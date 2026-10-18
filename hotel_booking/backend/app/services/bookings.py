from datetime import datetime, timezone
from sqlalchemy import select, exists
from app.models import Room, RoomType, Booking, Closure, History, HOLD
from app.core.errors import fail, DomainError
from app.core.security import principal
from app.services.rules import validate_stay, next_state


def get_or_404(db, model, key, lock=False):
    query = select(model).where(model.__mapper__.primary_key[0] == key)
    if lock:
        query = query.with_for_update().execution_options(populate_existing=True)
    obj = db.scalar(query)
    if obj is None:
        fail(404, 'NOT_FOUND', 'Không tìm thấy dữ liệu')
    return obj


def lock_room(db, key):
    return get_or_404(db, Room, key, True)


def room_type(db, room):
    return db.scalar(select(RoomType).where(RoomType.ma_lp == room.ma_lp)
                     .with_for_update(read=True).execution_options(populate_existing=True))


def conflict(db, room_id, start, end, exclude_closure=None):
    booking = db.scalar(select(exists().where(Booking.ma_phong == room_id,
        Booking.trang_thai.in_(HOLD), Booking.ngay_nhan < end, Booking.ngay_tra > start)))
    query = select(Closure.ma_ngung).where(Closure.ma_phong == room_id,
        Closure.dang_hieu_luc.is_(True), Closure.tu_ngay < end, Closure.den_ngay > start)
    if exclude_closure:
        query = query.where(Closure.ma_ngung != exclude_closure)
    return booking or db.scalar(query.limit(1)) is not None


def check_room(db, room, kind, stay):
    validate_stay(stay.ngay_nhan, stay.ngay_tra, stay.so_khach, kind.suc_chua)
    return room.dang_kinh_doanh and kind.dang_kinh_doanh and not conflict(
        db, room.ma_phong, stay.ngay_nhan, stay.ngay_tra)


def create_booking(db, user, data, commit=True):
    # Authentication already opened a transaction. Commit only here, together with history.
    room = lock_room(db, data.ma_phong)
    kind = room_type(db, room)
    principal(db, user['account'])
    if not check_room(db, room, kind, data):
        fail(409, 'ROOM_UNAVAILABLE', 'Phòng không còn trống trong khoảng ngày đã chọn')
    if data.expected_don_gia_moi_dem is not None and data.expected_don_gia_moi_dem != kind.gia_co_ban:
        raise DomainError(409, 'PRICE_CHANGED', 'Giá phòng đã thay đổi. Vui lòng xem và xác nhận giá mới.',
            {'don_gia_moi_dem': int(kind.gia_co_ban),
             'tong_tien': int(kind.gia_co_ban * (data.ngay_tra-data.ngay_nhan).days)})
    booking = Booking(**data.model_dump(exclude={'expected_don_gia_moi_dem'}), ma_kh=user['account'].id,
                      don_gia_moi_dem=kind.gia_co_ban,
                      tong_tien=kind.gia_co_ban * (data.ngay_tra - data.ngay_nhan).days,
                      trang_thai='CHO_XAC_NHAN')
    from app.services.stays import policy,now,VN
    from datetime import timedelta,time
    booking.chinh_sach=policy()
    arrival_deadline=datetime.combine(data.ngay_nhan,time.max,VN)
    booking.giu_cho_den=min(now()+timedelta(hours=booking.chinh_sach['hold_hours']),arrival_deadline)
    db.add(booking)
    db.flush()
    db.add(History(ma_pdp=booking.ma_pdp, den_trang_thai=booking.trang_thai,
                   nguoi_thuc_hien=user['account'].id))
    from app.services.notifications import booking_event
    booking_event(db, booking, 'create')
    if commit: db.commit()
    return booking


def visible_booking(db, key, user, lock=False):
    booking = get_or_404(db, Booking, key, lock)
    if user['role'] == 'KHACH_HANG' and booking.ma_kh != user['account'].id:
        fail(404, 'NOT_FOUND', 'Không tìm thấy phiếu')
    return booking


def transition(db, key, user, action, reason=None):
    initial = visible_booking(db, key, user)
    lock_room(db, initial.ma_phong)
    booking = visible_booking(db, key, user, True)
    if booking.trang_thai=='CHO_XAC_NHAN' and booking.giu_cho_den:
        from app.services.stays import now,state
        if booking.giu_cho_den<=now():
            state(db,booking,user,'HET_HAN','Hết thời gian giữ chỗ chưa được xác nhận');db.commit()
            fail(409,'HOLD_EXPIRED','Đơn đã hết thời gian giữ chỗ; vui lòng đặt lại')
    refreshed = principal(db, user['account'])
    new = next_state(booking.trang_thai, action, booking.ngay_nhan,
                     refreshed['role'], booking.ma_kh == user['account'].id)
    if action=='cancel':
        from app.services.stays import now,VN,add_auto
        from datetime import time,timedelta
        p=booking.chinh_sach
        arrival=datetime.combine(booking.ngay_nhan,time(p.get('checkin_hour',14)),VN)
        if booking.trang_thai=='DA_XAC_NHAN' and p.get('version') and arrival-now()<timedelta(hours=p['cancel_free_hours']):
            add_auto(db,booking,user,'HUY_MUON',min(int(booking.tong_tien),int(booking.don_gia_moi_dem)*p['late_cancel_nights']),'Phí hủy sát ngày nhận theo chính sách đã chốt')
    db.add(History(ma_pdp=key, tu_trang_thai=booking.trang_thai, den_trang_thai=new,
                   nguoi_thuc_hien=user['account'].id, ly_do=reason))
    booking.trang_thai = new
    booking.ngay_cap_nhat = datetime.now(timezone.utc)
    if action != 'cancel':
        booking.nhan_vien_xu_ly = user['account'].id
        booking.ngay_xu_ly = booking.ngay_cap_nhat
        booking.ly_do_tu_choi = reason if action == 'reject' else None
    from app.services.notifications import booking_event
    booking_event(db, booking, action)
    db.commit()
    return booking


def save_closure(db, user, data, key=None):
    initial = get_or_404(db, Closure, key) if key else None
    room_id = initial.ma_phong if initial else data.ma_phong
    lock_room(db, room_id)
    closure = get_or_404(db, Closure, key, True) if key else Closure(
        ma_phong=room_id, nguoi_tao=user['account'].id,ly_do='')
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(closure, field, '' if field=='ly_do' and value is None else value)
    if closure.dang_hieu_luc is None:
        closure.dang_hieu_luc = True
    if closure.den_ngay <= closure.tu_ngay:
        fail(422, 'VALIDATION_ERROR', 'Ngày kết thúc phải sau ngày bắt đầu')
    if closure.dang_hieu_luc and conflict(db, room_id, closure.tu_ngay, closure.den_ngay, key):
        fail(409, 'ROOM_UNAVAILABLE', 'Kỳ tạm ngừng giao với lịch đang giữ phòng')
    db.add(closure)
    db.commit()
    return closure

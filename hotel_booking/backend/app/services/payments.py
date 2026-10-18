from sqlalchemy import select, func, case, text
from app.models import Payment, Booking, Charge
from app.core.errors import fail
from app.core.security import principal
from app.core.permissions import PERMISSIONS
from app.services.bookings import get_or_404, lock_room


def balance(db, booking):
    collected, refunded = db.execute(select(
        func.coalesce(func.sum(case((Payment.loai == 'THU', Payment.so_tien), else_=0)), 0),
        func.coalesce(func.sum(case((Payment.loai == 'HOAN', Payment.so_tien), else_=0)), 0)
    ).where(Payment.ma_pdp == booking.ma_pdp,Payment.environment=='production')).one()
    net = int(collected-refunded)
    charges = int(db.scalar(select(func.coalesce(func.sum(Charge.don_gia*Charge.so_luong),0)).where(
        Charge.ma_pdp==booking.ma_pdp,Charge.da_huy.is_(False))))
    base = int(booking.tong_tien) if booking.trang_thai not in ('DA_HUY','DA_TU_CHOI','HET_HAN','KHONG_DEN') else 0
    total = base + charges
    return {'da_thu': int(collected), 'da_hoan': int(refunded), 'thu_rong': net,
            'tien_phong':base,'tong_phu_thu':charges,'tong_thanh_toan':total,
            'con_phai_thu': max(total-net,0) if booking.trang_thai != 'CHO_XAC_NHAN' else 0,
            'can_hoan_tien':max(net-total,0)}


def record(db, user, data, booking_id=None, original_id=None):
    kind = 'HOAN' if original_id else 'THU'
    # Serialize duplicate request IDs as well as booking balance checks across processes.
    db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))'), {'key': str(data.request_id)})
    original = get_or_404(db, Payment, original_id) if original_id else None
    booking_id = original.ma_pdp if original else booking_id
    initial = get_or_404(db, Booking, booking_id)
    lock_room(db, initial.ma_phong)
    booking = get_or_404(db, Booking, booking_id, True)
    refreshed = principal(db, user['account'])
    needed = 'payments.refund' if original else 'payments.collect'
    if needed not in PERMISSIONS.get(refreshed['role'], set()):
        fail(403,'FORBIDDEN','Bạn không có quyền ghi nhận giao dịch này')
    values = data.model_dump()
    existing = db.scalar(select(Payment).where(Payment.request_id == data.request_id))
    if existing:
        matches = (existing.ma_pdp == booking_id and existing.loai == kind and
            existing.giao_dich_goc_id == original_id and existing.nguoi_ghi_nhan == user['account'].id and
            all(getattr(existing,k) == v for k,v in values.items()))
        if not matches:
            fail(409,'REQUEST_CONFLICT','Mã yêu cầu đã được dùng với nội dung khác')
        db.commit()
        return existing
    totals = balance(db, booking)
    from app.models import PaymentAttempt
    if db.scalar(select(PaymentAttempt.id).where(PaymentAttempt.ma_pdp==booking_id,PaymentAttempt.state.in_(('CREATED','PENDING'))).limit(1)):
        fail(409,'ONLINE_PAYMENT_PENDING','Có thanh toán online chưa được đối soát; kiểm tra kết quả trước khi thu/hoàn thủ công')
    if original and original.environment!='production':
        fail(409,'SANDBOX_TRANSACTION','Giao dịch thử nghiệm không được hoàn bằng tiền thật')
    if original:
        if original.loai != 'THU':
            fail(400,'INVALID_OPERATION','Chỉ hoàn giao dịch thu gốc')
        refunded = db.scalar(select(func.coalesce(func.sum(Payment.so_tien),0)).where(
            Payment.giao_dich_goc_id == original_id, Payment.loai == 'HOAN'))
        if data.so_tien > original.so_tien-refunded or data.so_tien > totals['thu_rong']:
            fail(409,'PAYMENT_LIMIT','Khoản hoàn vượt số tiền đã thu còn lại')
    elif booking.trang_thai not in ('DA_XAC_NHAN','DANG_O','CHO_THANH_TOAN','DA_HOAN_TAT','DA_HUY','KHONG_DEN'):
        fail(400,'INVALID_OPERATION','Chỉ ghi nhận thu cho đặt phòng đã xác nhận')
    elif data.so_tien > totals['con_phai_thu']:
        fail(409,'PAYMENT_LIMIT','Khoản thu vượt số tiền còn phải thu')
    obj = Payment(**values, ma_pdp=booking_id, loai=kind, giao_dich_goc_id=original_id,
                  nguoi_ghi_nhan=user['account'].id)
    db.add(obj)
    db.commit()
    return obj

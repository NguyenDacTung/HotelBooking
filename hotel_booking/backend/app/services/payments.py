from sqlalchemy import select, func, case, text
from app.models import Payment, Booking
from app.core.errors import fail
from app.core.security import principal
from app.core.permissions import PERMISSIONS
from app.services.bookings import get_or_404, lock_room


def balance(db, booking):
    collected, refunded = db.execute(select(
        func.coalesce(func.sum(case((Payment.loai == 'THU', Payment.so_tien), else_=0)), 0),
        func.coalesce(func.sum(case((Payment.loai == 'HOAN', Payment.so_tien), else_=0)), 0)
    ).where(Payment.ma_pdp == booking.ma_pdp)).one()
    net = int(collected-refunded)
    return {'da_thu': int(collected), 'da_hoan': int(refunded), 'thu_rong': net,
            'con_phai_thu': max(int(booking.tong_tien)-net,0) if booking.trang_thai == 'DA_XAC_NHAN' else 0,
            'can_hoan_tien': net if booking.trang_thai == 'DA_HUY' else 0}


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
    if original:
        if original.loai != 'THU':
            fail(400,'INVALID_OPERATION','Chỉ hoàn giao dịch thu gốc')
        refunded = db.scalar(select(func.coalesce(func.sum(Payment.so_tien),0)).where(
            Payment.giao_dich_goc_id == original_id, Payment.loai == 'HOAN'))
        if data.so_tien > original.so_tien-refunded or data.so_tien > totals['thu_rong']:
            fail(409,'PAYMENT_LIMIT','Khoản hoàn vượt số tiền đã thu còn lại')
    elif booking.trang_thai != 'DA_XAC_NHAN':
        fail(400,'INVALID_OPERATION','Chỉ ghi nhận thu cho đặt phòng đã xác nhận')
    elif data.so_tien > totals['con_phai_thu']:
        fail(409,'PAYMENT_LIMIT','Khoản thu vượt số tiền còn phải thu')
    obj = Payment(**values, ma_pdp=booking_id, loai=kind, giao_dich_goc_id=original_id,
                  nguoi_ghi_nhan=user['account'].id)
    db.add(obj)
    db.commit()
    return obj

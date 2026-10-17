from datetime import datetime, timezone
from sqlalchemy import select
from app.models import Account, Staff, Role, Notification


def booking_event(db, booking, action):
    if action in ('create', 'cancel'):
        recipients = db.scalars(select(Account.id).join(Staff).join(Role).where(
            Account.dang_hoat_dong.is_(True), Staff.dang_hoat_dong.is_(True),
            Role.dang_su_dung.is_(True), Role.ma_quyen.in_(('LE_TAN','QUAN_LY')))).all()
    else:
        recipients = [booking.ma_kh]
    titles = {'create':'Yêu cầu đặt phòng mới', 'cancel':'Đặt phòng đã hủy',
              'confirm':'TTTP đã xác nhận đặt phòng', 'reject':'Yêu cầu đặt phòng đã bị từ chối'}
    for recipient in recipients:
        db.add(Notification(tai_khoan_id=recipient, loai_su_kien=action,
            tieu_de=titles[action], noi_dung='Mở ứng dụng TTTP để xem thông tin cập nhật.',
            ma_pdp=booking.ma_pdp, event_key=f'{booking.ma_pdp}:{action}:{recipient}'))

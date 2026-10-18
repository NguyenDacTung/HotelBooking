"""Stay actions, immutable rate/policy snapshots and an audited surcharge ledger."""
from datetime import datetime,time,timedelta,timezone
from decimal import Decimal,ROUND_HALF_UP
from uuid import uuid4,uuid5,NAMESPACE_URL
from zoneinfo import ZoneInfo
from sqlalchemy import select,func
from app.models import Booking,Room,Charge,History,HOLD
from app.core.config import settings
from app.core.errors import fail
from app.services.accounts import audit

VN=ZoneInfo('Asia/Ho_Chi_Minh')
def now(): return datetime.now(timezone.utc)
def policy():
    c=settings()
    return {'version':1,'checkin_hour':c.checkin_hour,'checkout_hour':c.checkout_hour,
      'hold_hours':c.hold_hours,'cancel_free_hours':24,'late_cancel_nights':1,
      'no_show_nights':1,'extra_bed_price':c.extra_bed_price,
      'early_before_6_percent':100,'early_before_checkin_percent':50,
      'late_before_15_percent':30,'late_before_18_percent':50,'late_after_18_percent':100}

def amount(rate,percent):return int((Decimal(rate)*Decimal(percent)/100).quantize(Decimal('1'),rounding=ROUND_HALF_UP))

def time_charge(b,kind,instant=None):
    if not b.chinh_sach:return 0  # No retrospective automatic fee on legacy reservations.
    t=(instant or now()).astimezone(VN);p=b.chinh_sach or policy()
    if kind=='NHAN_SOM':
        percent=p['early_before_6_percent'] if t.hour<6 else p['early_before_checkin_percent'] if t.hour<p['checkin_hour'] else 0
        return amount(b.don_gia_moi_dem,percent)
    due=datetime.combine(b.ngay_tra,time(p['checkout_hour']),VN)
    if t<=due:return 0
    days=max((t.date()-b.ngay_tra).days,0)
    hour=t.hour+t.minute/60+t.second/3600
    percent=0 if hour<=p['checkout_hour'] else p['late_before_15_percent'] if hour<=15 else p['late_before_18_percent'] if hour<=18 else p['late_after_18_percent']
    return days*int(b.don_gia_moi_dem)+amount(b.don_gia_moi_dem,percent)

def add_auto(db,b,user,kind,value,description):
    key=uuid5(NAMESPACE_URL,f'tttp:{b.ma_pdp}:{kind}')
    row=db.scalar(select(Charge).where(Charge.request_id==key))
    if row:
        # A manager's audited waiver must survive later invoice refreshes.
        from app.models import Audit
        if row.da_huy and db.scalar(select(Audit.id).where(Audit.entity=='charge',Audit.entity_id==str(row.id),Audit.action=='void').limit(1)):
            return
        if int(row.don_gia)!=value or row.da_huy!=(value==0):
            audit(db,user,'charge',row.id,'recalculate',{'don_gia':int(row.don_gia)}, {'don_gia':value},description)
            if value: row.don_gia=value
            row.da_huy=value==0
    elif value:
        db.add(Charge(ma_pdp=b.ma_pdp,loai=kind,noi_dung=description,don_gia=value,so_luong=1,
            nguoi_tao=user['account'].id,request_id=key))
    db.flush()

def state(db,b,user,new,reason):
    old=b.trang_thai;b.trang_thai=new;b.ngay_cap_nhat=now()
    db.add(History(ma_pdp=b.ma_pdp,tu_trang_thai=old,den_trang_thai=new,nguoi_thuc_hien=user['account'].id,ly_do=reason))
    audit(db,user,'booking',b.ma_pdp,'stay',{'trang_thai':old},{'trang_thai':new},reason)
    from app.services.notifications import booking_event
    booking_event(db,b,'stay_'+new)
    db.flush()

def locked(db,key,user):
    from app.services.bookings import visible_booking,lock_room
    initial=visible_booking(db,key,user);lock_room(db,initial.ma_phong)
    return visible_booking(db,key,user,True)

def checkin(db,key,user,reason):
    b=locked(db,key,user);room=db.get(Room,b.ma_phong)
    if b.trang_thai!='DA_XAC_NHAN':fail(409,'STATE_CONFLICT','Chỉ nhận phòng cho đơn đã xác nhận')
    if b.ngay_nhan!=now().astimezone(VN).date():fail(400,'INVALID_OPERATION','Nhận phòng vào đúng ngày đến; hãy đổi ngày trước nếu cần')
    if room.tinh_trang_van_hanh!='SAN_SANG':fail(409,'ROOM_NOT_READY','Phòng chưa dọn xong hoặc đang bảo trì')
    active=db.scalar(select(Booking.ma_pdp).where(Booking.ma_phong==room.ma_phong,
        Booking.trang_thai.in_(('DANG_O','CHO_THANH_TOAN')),Booking.ma_pdp!=b.ma_pdp).limit(1))
    if active:fail(409,'ROOM_OCCUPIED','Khách trước chưa hoàn tất trả phòng')
    add_auto(db,b,user,'NHAN_SOM',time_charge(b,'NHAN_SOM'),'Phụ thu nhận phòng sớm theo chính sách đã chốt')
    b.nhan_phong_luc=now();state(db,b,user,'DANG_O',reason);db.commit();return b

def request_checkout(db,key,user):
    b=locked(db,key,user)
    if b.trang_thai not in ('DANG_O','CHO_THANH_TOAN'):fail(409,'STATE_CONFLICT','Đơn chưa nhận phòng hoặc đã hoàn tất')
    add_auto(db,b,user,'TRA_MUON',time_charge(b,'TRA_MUON'),'Phụ thu trả phòng muộn theo thời điểm yêu cầu')
    b.yeu_cau_tra_luc=now()
    if b.trang_thai=='DANG_O':state(db,b,user,'CHO_THANH_TOAN','Yêu cầu trả phòng và đối chiếu hóa đơn')
    db.commit();return b

def checkout(db,key,user,reason):
    from app.services.payments import balance
    b=locked(db,key,user)
    from app.models import PaymentAttempt
    if db.scalar(select(PaymentAttempt.id).where(PaymentAttempt.ma_pdp==key,PaymentAttempt.state.in_(('CREATED','PENDING'))).limit(1)):
        fail(409,'ONLINE_PAYMENT_PENDING','Cần đối soát thanh toán online trước khi hoàn tất trả phòng')
    if b.trang_thai!='CHO_THANH_TOAN':fail(409,'STATE_CONFLICT','Cần lập hóa đơn trả phòng trước')
    # Refresh late fee at physical handover, not at an arbitrarily early request.
    add_auto(db,b,user,'TRA_MUON',time_charge(b,'TRA_MUON'),'Đối chiếu phụ thu tại thời điểm trả phòng thực tế')
    due=balance(db,b)
    if due['con_phai_thu'] or due['can_hoan_tien']:
        db.commit() # retain revised invoice so it can be paid/refunded before retry
        fail(409,'BALANCE_DUE','Hóa đơn còn khoản cần thu/hoàn. Đối chiếu sổ tiền rồi hoàn tất trả phòng.')
    room=db.get(Room,b.ma_phong);room.tinh_trang_van_hanh='CAN_DON_DEP'
    b.tra_phong_luc=now();state(db,b,user,'DA_HOAN_TAT',reason);db.commit();return b

def no_show(db,key,user,reason):
    b=locked(db,key,user)
    if b.trang_thai!='DA_XAC_NHAN' or b.ngay_nhan>=now().astimezone(VN).date():
        fail(409,'STATE_CONFLICT','Chỉ xử lý khách không đến sau ngày nhận phòng')
    fee=min(int(b.tong_tien),int(b.don_gia_moi_dem)*b.chinh_sach.get('no_show_nights',0))
    add_auto(db,b,user,'KHONG_DEN',fee,'Phí khách không đến theo chính sách đặt phòng')
    state(db,b,user,'KHONG_DEN',reason);db.commit();return b

def expire_pending(db):
    # Only new-policy holds; legacy bookings are not retrospectively reinterpreted.
    keys=db.scalars(select(Booking.ma_pdp).where(Booking.trang_thai=='CHO_XAC_NHAN',Booking.giu_cho_den<=now())).all()
    from app.models import Account
    from app.core.security import principal
    from app.services.bookings import lock_room,get_or_404
    for key in keys:
        initial=db.get(Booking,key);lock_room(db,initial.ma_phong);b=get_or_404(db,Booking,key,True)
        if b.trang_thai=='CHO_XAC_NHAN' and b.giu_cho_den and b.giu_cho_den<=now():
            owner=principal(db,db.get(Account,b.ma_kh)) if db.get(Account,b.ma_kh).dang_hoat_dong else {'account':db.get(Account,b.ma_kh)}
            state(db,b,owner,'HET_HAN','Hết thời gian giữ chỗ chưa được xác nhận')
        db.commit()

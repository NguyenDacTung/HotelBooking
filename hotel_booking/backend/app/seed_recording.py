"""Additive, repeatable catalogue/history for the owner's progress recording.

The dataset is fictional, not proof of real stays or money received. This fact
is recorded in the delivery notes; customer-facing wording stays natural.
Caller owns the transaction. Existing rows are never updated or deleted.
"""
from datetime import datetime, time, timedelta
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5
from zoneinfo import ZoneInfo
import hashlib
import shutil

from sqlalchemy import select, text
from app.core.config import settings
from app.core.security import passwords
from app.models import (Account, Customer, Staff, Role, Room, RoomType, RoomImage,
    Booking, History, Charge, Payment, Review, Notification)
from app.services.stays import policy, time_charge

VN = ZoneInfo('Asia/Ho_Chi_Minh')
PREFIX = 'tetra-recording-20261018-v1'
ROOMS = [
    ('401','Standard Single','Ưu tiên bố trí khách đi công tác.'),
    ('402','Standard Double','Bố trí cho khách đi đôi.'),
    ('403','Standard Twin','Hai giường riêng cho khách đi cùng.'),
    ('404','Superior Double','Có khu vực làm việc trong phòng.'),
    ('405','Superior Twin','Hai giường riêng, phù hợp đồng nghiệp.'),
    ('406','Deluxe King','Bố trí giường king và khu vực tiếp khách.'),
    ('407','Deluxe Twin','Phù hợp hai khách cần giường riêng.'),
    ('408','Family Quad','Ưu tiên nhóm gia đình bốn người.'),
    ('409','Junior Suite','Bố trí khách lưu trú cần không gian rộng.'),
    ('410','Executive Suite','Có khu vực tiếp khách riêng.'),
    ('411','Deluxe King','Kiểm tra đầy đủ đồ dùng trước khi đón khách.'),
    ('412','Superior Double','Ưu tiên khách lưu trú từ hai đêm.'),
]
PEOPLE = [
    ('minhanh','Trần Minh Anh','0902000101'),
    ('thanhha','Nguyễn Thanh Hà','0902000102'),
    ('quanghuy','Lê Quang Huy','0902000103'),
    ('ngoclinh','Phạm Ngọc Linh','0902000104'),
    ('hoangnam','Vũ Hoàng Nam','0902000105'),
    ('baotran','Đỗ Bảo Trân','0902000106'),
]

def ident(label): return uuid5(NAMESPACE_URL, PREFIX+':'+label)
def instant(day, hour=14, minute=10): return datetime.combine(day,time(hour,minute),VN)

def seed(db, password, anchor=None):
    """No commit: validate/rollback on test DB or commit explicitly on original DB."""
    anchor = anchor or datetime.now(VN).date()
    current = datetime.now(VN)
    db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:k,0))'),{'k':PREFIX})
    # The final marker is a normal notification with a stable internal event key.
    marker = db.scalar(select(Notification.id).where(Notification.event_key==PREFIX+':complete'))
    if marker:
        return {'already_present':True,'added':{},'customer':'minhanh@tetra.test','staff':'thutrang@tetra.test','room_for_recording':'411'}
    roles = {r.ma_quyen:r for r in db.scalars(select(Role))}
    if 'LE_TAN' not in roles: raise RuntimeError('Receptionist role missing; no data applied')
    staff_id=ident('staff:thutrang')
    if db.scalar(select(Account.id).where(Account.email=='thutrang@tetra.test')):
        raise RuntimeError('Recording account already exists without dataset marker; inspect without overwriting')
    staff_account=Account(id=staff_id,email='thutrang@tetra.test',mat_khau_bam=passwords.hash(password),
        loai_tai_khoan='NHAN_VIEN',ngay_tao=instant(anchor-timedelta(days=120)))
    db.add(staff_account);db.flush()
    db.add(Staff(id=staff_id,ho_ten='Lê Thu Trang',ma_cv=roles['LE_TAN'].ma_cv))
    customers=[]
    for slug,name,phone in PEOPLE:
        if db.scalar(select(Account.id).where(Account.email==slug+'@tetra.test')):
            raise RuntimeError('Recording customer email conflict; no existing account changed')
        account=Account(id=ident('customer:'+slug),email=slug+'@tetra.test',mat_khau_bam=passwords.hash(password),
            loai_tai_khoan='KHACH_HANG',ngay_tao=instant(anchor-timedelta(days=75)))
        db.add(account);db.flush();db.add(Customer(id=account.id,ho_ten=name,so_dien_thoai=phone));customers.append(account)
    db.flush()
    root=Path(__file__).resolve().parents[2]
    photo_dir=settings().upload_dir.resolve();photo_dir.mkdir(parents=True,exist_ok=True)
    photos={
        'double':[root/'assets/room_photos/pexels-271618.jpg',root/'assets/room_photos/pexels-271619.jpg'],
        'twin':[root/'assets/room_photos/pexels-2029722.jpg',root/'assets/room_photos/pexels-29000012.jpg'],
        'family':[root/'assets/room_photos/pexels-34763215.jpg'],
        'suite':[root/'assets/room_photos/pexels-262048.jpg',root/'assets/images/banner-deluxe.jpg'],
    }
    rooms={};images=0
    for number,kind_name,note in ROOMS:
        if db.scalar(select(Room.ma_phong).where(Room.so_phong==number)):
            raise RuntimeError('Room number conflict: '+number+'; no existing room changed')
        kind=db.scalar(select(RoomType).where(RoomType.ten_loai==kind_name))
        if not kind: raise RuntimeError('Required room type missing: '+kind_name)
        row=Room(so_phong=number,ma_lp=kind.ma_lp,tang=4,ghi_chu=note)
        db.add(row);db.flush();rooms[number]=(row,kind)
        group='twin' if 'Twin' in kind_name else 'family' if 'Family' in kind_name else 'suite' if ('Suite' in kind_name or 'Deluxe' in kind_name) else 'double'
        selected=photos[group]
        for i,source in enumerate(selected):
            name=f'tetra-room-20261018-{number}-{i}.jpg';dest=photo_dir/name
            if dest.exists():
                if hashlib.sha256(dest.read_bytes()).digest()!=hashlib.sha256(source.read_bytes()).digest():
                    raise RuntimeError('Existing image file differs; refusing overwrite')
            else:shutil.copyfile(source,dest)
            db.add(RoomImage(ma_phong=row.ma_phong,duong_dan='/uploads/'+name,la_anh_bia=i==0,thu_tu=i));images+=1

    def history(b, states, who):
        last=None
        for state,when,note in states:
            db.add(History(ma_pdp=b.ma_pdp,tu_trang_thai=last,den_trang_thai=state,
                nguoi_thuc_hien=who if state!='CHO_XAC_NHAN' else b.ma_kh,ly_do=note,thoi_diem=when));last=state

    def booking(label,number,person,start,nights,status,note=''):
        room,kind=rooms[number];arrival=anchor+timedelta(days=start);departure=arrival+timedelta(days=nights)
        created=min(instant(arrival-timedelta(days=3),9),current-timedelta(hours=2))
        contact=PEOPLE[person]
        b=Booking(ma_pdp=ident('booking:'+label),ma_kh=customers[person].id,ma_phong=room.ma_phong,
            ngay_nhan=arrival,ngay_tra=departure,so_khach=min(2,kind.suc_chua),don_gia_moi_dem=kind.gia_co_ban,
            tong_tien=int(kind.gia_co_ban)*nights,trang_thai=status,ten_lien_he=contact[1],sdt_lien_he=contact[2],
            ghi_chu=note or None,ngay_tao=created,ngay_cap_nhat=current,chinh_sach=policy())
        timeline=[('CHO_XAC_NHAN',created,'')]
        if status in ('DA_XAC_NHAN','DANG_O','CHO_THANH_TOAN','DA_HOAN_TAT','KHONG_DEN'):
            b.nhan_vien_xu_ly=staff_id;b.ngay_xu_ly=created+timedelta(hours=1)
            timeline.append(('DA_XAC_NHAN',b.ngay_xu_ly,''))
        if status in ('DANG_O','CHO_THANH_TOAN','DA_HOAN_TAT'):
            b.nhan_phong_luc=instant(arrival);timeline.append(('DANG_O',b.nhan_phong_luc,'Nhận phòng'))
        if status in ('CHO_THANH_TOAN','DA_HOAN_TAT'):
            b.yeu_cau_tra_luc=instant(departure,11,10) if status=='DA_HOAN_TAT' else current-timedelta(minutes=15)
            timeline.append(('CHO_THANH_TOAN',b.yeu_cau_tra_luc,'Yêu cầu trả phòng và đối chiếu hóa đơn'))
        if status=='DA_HOAN_TAT':
            b.tra_phong_luc=instant(departure,11,25);timeline.append((status,b.tra_phong_luc,'Hoàn tất trả phòng'))
            b.ngay_cap_nhat=b.tra_phong_luc
        if status in ('DA_HUY','DA_TU_CHOI','HET_HAN','KHONG_DEN'):
            terminal=instant(arrival,18) if status=='KHONG_DEN' else created+timedelta(hours=3)
            timeline.append((status,terminal,note));b.ngay_cap_nhat=terminal
        if status=='CHO_XAC_NHAN':b.giu_cho_den=min(current+timedelta(hours=23),instant(arrival,23,59))
        db.add(b);db.flush();history(b,timeline,staff_id)
        return b

    def charge(b,label,kind,description,price,quantity=1,when=None):
        db.add(Charge(id=ident('charge:'+label),ma_pdp=b.ma_pdp,loai=kind,noi_dung=description,
            don_gia=price,so_luong=quantity,nguoi_tao=staff_id,ngay_tao=when or b.nhan_phong_luc or current,
            request_id=uuid5(NAMESPACE_URL,f'tttp:{b.ma_pdp}:{kind}') if kind in ('TRA_MUON','KHONG_DEN') else ident('charge-request:'+label)))

    def receipt(b,label,value,when,method='CHUYEN_KHOAN'):
        db.add(Payment(id=ident('payment:'+label),ma_pdp=b.ma_pdp,loai='THU',so_tien=value,phuong_thuc=method,
            environment='production',thoi_diem_giao_dich=when,ngay_tao=when,nguoi_ghi_nhan=staff_id,
            ghi_chu='Thanh toán tiền phòng và dịch vụ lưu trú',ma_tham_chieu='LT-'+when.strftime('%Y%m%d')+'-'+label.upper(),
            request_id=ident('receipt-request:'+label)))

    completed=[('401',0,-28,2,5,'Phòng gọn gàng, phù hợp chuyến công tác ngắn ngày.'),
        ('402',1,-24,1,4,'Giường thoải mái, thủ tục nhận phòng nhanh.'),
        ('403',2,-20,3,4,'Hai giường riêng thuận tiện, phòng được dọn sạch.'),
        ('404',3,-16,2,5,'Không gian làm việc tiện lợi, nhân viên hỗ trợ nhiệt tình.'),
        ('405',4,-12,1,4,'Phòng sạch, ánh sáng dễ chịu. Tôi muốn có thêm móc treo đồ.'),
        ('406',5,-8,2,5,'Phòng rộng, giường êm và có khu vực ngồi thư giãn.'),
        ('407',0,-5,2,4,'Nhân viên hỗ trợ nhanh, phù hợp đi cùng đồng nghiệp.'),
        ('408',1,-3,1,5,'Gia đình có đủ chỗ nghỉ, tiện nghi sử dụng thuận tiện.'),
        ('409',0,-2,1,5,'Khu vực tiếp khách rộng, nhận và trả phòng thuận tiện.')]
    for index,(number,person,start,nights,stars,comment) in enumerate(completed):
        b=booking('past-'+str(index),number,person,start,nights,'DA_HOAN_TAT')
        extra=40000 if index in (3,6,8) else 0
        if extra:charge(b,'past-'+str(index),'MINIBAR','Nước uống minibar',20000,2,when=b.yeu_cau_tra_luc-timedelta(minutes=10))
        receipt(b,'past-'+str(index),int(b.tong_tien)+extra,b.tra_phong_luc-timedelta(minutes=3), 'TIEN_MAT' if index%3==0 else 'CHUYEN_KHOAN')
        db.add(Review(id=ident('review:'+str(index)),ma_pdp=b.ma_pdp,so_sao=stars,nhan_xet=comment,
            ngay_tao=b.tra_phong_luc+timedelta(hours=3),ngay_cap_nhat=b.tra_phong_luc+timedelta(hours=3)))
    booking('pending-1','401',1,1,2,'CHO_XAC_NHAN','Dự kiến đến vào buổi chiều.')
    booking('confirmed-today','402',2,0,1,'DA_XAC_NHAN','Xin hỗ trợ nhận phòng sau 14 giờ.')
    staying=booking('staying','403',3,-1,2,'DANG_O','Khách lưu trú hai đêm.')
    receipt(staying,'staying-deposit',550000,staying.nhan_phong_luc,'TIEN_MAT')
    due=booking('checkout','404',4,-1,1,'CHO_THANH_TOAN')
    charge(due,'checkout-minibar','MINIBAR','Nước uống minibar',20000,2)
    late=time_charge(due,'TRA_MUON',current)
    if late:
        charge(due,'checkout-late','TRA_MUON','Phụ thu trả phòng muộn',late)
    booking('confirmed-family','405',5,0,2,'DA_XAC_NHAN')
    booking('next-week-king','406',1,4,2,'DA_XAC_NHAN','Ưu tiên chuẩn bị bàn làm việc.')
    booking('next-week-twin','407',0,7,2,'DA_XAC_NHAN','Hai khách cần giường riêng.')
    booking('pending-family','408',2,3,2,'CHO_XAC_NHAN','Gia đình dự kiến tới buổi tối.')
    booking('cancelled-1','409',3,-10,1,'DA_HUY','Thay đổi lịch công tác.')
    booking('cancelled-2','410',4,-6,2,'DA_HUY','Khách điều chỉnh kế hoạch di chuyển.')
    booking('rejected','409',5,1,1,'DA_TU_CHOI','Chưa thống nhất lại thời gian đến.')
    no_show=booking('no-show','410',2,-1,1,'KHONG_DEN','Chưa liên hệ được khách sau giờ dự kiến đến.')
    charge(no_show,'no-show','KHONG_DEN','Phí không đến theo chính sách đặt phòng',int(no_show.don_gia_moi_dem))
    booking('expired','410',1,-4,1,'HET_HAN','Hết thời gian giữ phòng khi chưa xác nhận.')
    for index,account in enumerate(customers):
        db.add(Notification(id=ident('notification:'+str(index)),tai_khoan_id=account.id,loai_su_kien='BOOKING_UPDATED',
            tieu_de='Thông tin đặt phòng đã cập nhật',noi_dung='Mở lịch sử đặt phòng để xem lịch lưu trú và hóa đơn của bạn.',
            ngay_tao=current-timedelta(minutes=index*8),event_key=PREFIX+(':complete' if index==0 else ':notice:'+str(index))))
    db.flush()
    return {'already_present':False,'added':{'rooms':12,'images':images,'customers':6,'staff':1,'bookings':22,'reviews':9},
        'customer':'minhanh@tetra.test','staff':'thutrang@tetra.test','room_for_recording':'411','anchor':str(anchor)}

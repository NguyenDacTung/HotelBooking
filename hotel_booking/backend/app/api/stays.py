from datetime import date,datetime,timedelta
from uuid import UUID
from pydantic import Field
from fastapi import APIRouter,Depends
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.security import staff,manager,current,principal
from app.core.errors import fail
from app.db.session import get_db
from app.models import Booking,Customer,Account,Charge,Room,RoomType,HOLD
from app.schemas.requests import Input,Reason,BookingCreate,Stay,Email,Name,Phone
from app.schemas.responses import booking_out
from app.api.catalog import columns
from app.services import stays
from app.services.accounts import audit
from app.services.bookings import create_booking,get_or_404,lock_room,room_type,check_room

router=APIRouter(tags=['Lưu trú và phụ thu'])

class FrontDeskCreate(BookingCreate):
    email_khach: Email

class Amend(Stay):
    ma_phong:int=Field(gt=0)
    ly_do:str=Field(default='',max_length=2000)
    expected_don_gia_moi_dem:int|None=Field(None,ge=0)

class ChargeInput(Input):
    loai:str=Field(pattern='^(GIUONG_PHU|MINIBAR|GIAT_LA|HU_HONG|KHAC)$')
    noi_dung:str=Field(min_length=1,max_length=500)
    don_gia:int=Field(gt=0,le=999999999999)
    so_luong:int=Field(default=1,ge=1,le=30)
    request_id:UUID

@router.get('/hotel/policy')
def policy():
    return stays.policy()

@router.post('/staff/bookings',status_code=201)
def front_desk(data:FrontDeskCreate,user=Depends(staff),db:Session=Depends(get_db)):
    account=db.scalar(select(Account).where(Account.email==data.email_khach))
    if account and account.loai_tai_khoan!='KHACH_HANG':fail(409,'INVALID_CUSTOMER','Email thuộc tài khoản nhân viên')
    if not account:
        account=Account(email=data.email_khach,mat_khau_bam=None,dang_nhap_noi_bo=False,loai_tai_khoan='KHACH_HANG')
        db.add(account);db.flush();db.add(Customer(id=account.id,ho_ten=data.ten_lien_he,so_dien_thoai=data.sdt_lien_he));db.flush()
    target=principal(db,account)
    b=create_booking(db,target,BookingCreate(**data.model_dump(exclude={'email_khach'})),commit=False)
    audit(db,user,'booking',b.ma_pdp,'front_desk',None,{'customer':str(account.id)},'Lễ tân tạo đặt phòng hộ khách')
    db.commit();return booking_out(db,b,True)

@router.patch('/staff/bookings/{key}/amend')
def amend(key:UUID,data:Amend,user=Depends(staff),db:Session=Depends(get_db)):
    initial=get_or_404(db,Booking,key)
    for rid in sorted(set((initial.ma_phong,data.ma_phong))):lock_room(db,rid)
    b=get_or_404(db,Booking,key,True)
    if b.trang_thai not in ('CHO_XAC_NHAN','DA_XAC_NHAN'):fail(409,'STATE_CONFLICT','Chỉ đổi phòng/ngày trước khi nhận phòng')
    from app.models import Payment
    if db.scalar(select(Payment.id).where(Payment.ma_pdp==key).limit(1)):
        fail(409,'PAYMENT_EXISTS','Đơn đã có giao dịch tiền; cần hoàn/đối chiếu và tạo đơn thay thế để giữ nguyên sổ tiền')
    from app.models import PaymentAttempt
    if db.scalar(select(PaymentAttempt.id).where(PaymentAttempt.ma_pdp==key,PaymentAttempt.state.in_(('CREATED','PENDING'))).limit(1)):
        fail(409,'ONLINE_PAYMENT_PENDING','Đối soát thanh toán online trước khi đổi phòng/ngày')
    room=db.get(Room,data.ma_phong);kind=room_type(db,room)
    if data.expected_don_gia_moi_dem is not None and data.expected_don_gia_moi_dem!=kind.gia_co_ban:
        fail(409,'PRICE_CHANGED','Giá phòng đã thay đổi; mở lại màn hình đổi phòng để xác nhận giá mới')
    old={'ma_phong':b.ma_phong,'ngay_nhan':str(b.ngay_nhan),'ngay_tra':str(b.ngay_tra),'tong_tien':int(b.tong_tien)}
    # Ignore this booking while validating the replacement interval; rollback on failure.
    previous=b.trang_thai;b.trang_thai='DA_HUY';db.flush()
    if not check_room(db,room,kind,data):fail(409,'ROOM_UNAVAILABLE','Phòng/ngày mới không khả dụng')
    b.trang_thai=previous;b.ma_phong=data.ma_phong;b.ngay_nhan=data.ngay_nhan;b.ngay_tra=data.ngay_tra;b.so_khach=data.so_khach
    b.don_gia_moi_dem=kind.gia_co_ban;b.tong_tien=kind.gia_co_ban*(data.ngay_tra-data.ngay_nhan).days
    b.ngay_cap_nhat=stays.now()
    audit(db,user,'booking',key,'amend',old,{'ma_phong':b.ma_phong,'ngay_nhan':str(b.ngay_nhan),'ngay_tra':str(b.ngay_tra),'tong_tien':int(b.tong_tien)},data.ly_do)
    db.commit();return booking_out(db,b,True)

@router.patch('/staff/bookings/{key}/cancel')
def cancel(key:UUID,data:Reason,user=Depends(staff),db:Session=Depends(get_db)):
    from app.services.bookings import transition
    return booking_out(db,transition(db,key,user,'cancel',data.ly_do),True)

@router.post('/staff/bookings/{key}/check-in')
def checkin(key:UUID,data:Reason,user=Depends(staff),db:Session=Depends(get_db)):
    return booking_out(db,stays.checkin(db,key,user,data.ly_do or 'Nhận phòng'),True)

@router.post('/bookings/{key}/request-checkout')
def request_checkout(key:UUID,user=Depends(current),db:Session=Depends(get_db)):
    return booking_out(db,stays.request_checkout(db,key,user),True)

@router.post('/staff/bookings/{key}/check-out')
def checkout(key:UUID,data:Reason,user=Depends(staff),db:Session=Depends(get_db)):
    return booking_out(db,stays.checkout(db,key,user,data.ly_do or 'Bàn giao phòng và đối chiếu đủ tiền'),True)

@router.post('/staff/bookings/{key}/no-show')
def no_show(key:UUID,data:Reason,user=Depends(staff),db:Session=Depends(get_db)):
    return booking_out(db,stays.no_show(db,key,user,data.ly_do),True)

@router.post('/staff/bookings/{key}/charges',status_code=201)
def charge(key:UUID,data:ChargeInput,user=Depends(staff),db:Session=Depends(get_db)):
    b=stays.locked(db,key,user)
    existing=db.scalar(select(Charge).where(Charge.request_id==data.request_id))
    if existing:
        if existing.ma_pdp!=key or any(getattr(existing,k)!=v for k,v in data.model_dump().items()):fail(409,'REQUEST_CONFLICT','Mã yêu cầu đã dùng với nội dung khác')
        return columns(existing)
    if b.trang_thai not in ('DANG_O','CHO_THANH_TOAN'):fail(409,'STATE_CONFLICT','Chỉ thêm phát sinh trong thời gian lưu trú')
    if data.loai=='GIUONG_PHU':
        if data.so_luong!=1:fail(422,'VALIDATION_ERROR','Tối đa một giường phụ mỗi đơn')
        if db.scalar(select(Charge.id).where(Charge.ma_pdp==key,Charge.loai=='GIUONG_PHU',Charge.da_huy.is_(False))):fail(409,'STATE_CONFLICT','Đã thêm giường phụ')
    row=Charge(**data.model_dump(),ma_pdp=key,nguoi_tao=user['account'].id)
    db.add(row);db.flush();audit(db,user,'charge',row.id,'add',None,{'don_gia':data.don_gia,'so_luong':data.so_luong,'loai':data.loai},data.noi_dung)
    db.commit();return columns(row)

@router.post('/admin/charges/{key}/void')
def void_charge(key:UUID,data:Reason,user=Depends(manager),db:Session=Depends(get_db)):
    row=get_or_404(db,Charge,key);b=stays.locked(db,row.ma_pdp,user)
    row=get_or_404(db,Charge,key,True)
    if b.trang_thai=='DA_HOAN_TAT':fail(409,'STATE_CONFLICT','Hóa đơn đã hoàn tất; giữ nguyên sổ giao dịch')
    row.da_huy=True;audit(db,user,'charge',key,'void',None,{'da_huy':True},data.ly_do)
    db.commit();return columns(row)

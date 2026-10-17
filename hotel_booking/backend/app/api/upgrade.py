from datetime import datetime, timezone, date
from uuid import UUID
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, or_, func, update
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import current, manager, staff, passwords
from app.core.permissions import permission
from app.core.errors import fail
from app.models import Account, Staff, Customer, Role, Room, Closure, Booking, Payment, Notification
from app.schemas.upgrade import (AccountCreate, AccountEdit, RoleEdit, StatusEdit, OperationEdit,
    PaymentCreate, RefundCreate, PasswordChange)
from app.api.catalog import page_result, columns, room_out
from app.services.accounts import account_out, change_access, audit
from app.services.bookings import get_or_404, lock_room, conflict
from app.services.payments import record, balance
from app.services.rules import today

router = APIRouter(tags=['TTTP'])
admin = permission('accounts.manage')


@router.get('/admin/accounts', dependencies=[Depends(admin)])
def accounts(q: str | None = None, role: str | None = None, active: bool | None = None,
             page: int = Query(1,ge=1), page_size: int = Query(20,ge=1,le=100), db: Session = Depends(get_db)):
    query = select(Account).outerjoin(Customer).outerjoin(Staff).outerjoin(Role)
    if q:
        value = '%'+q.strip()+'%'
        query = query.where(or_(Account.email.ilike(value),Customer.ho_ten.ilike(value),Staff.ho_ten.ilike(value)))
    if role:
        query = query.where(Account.loai_tai_khoan=='KHACH_HANG' if role=='KHACH_HANG' else Role.ma_quyen==role)
    if active is not None:
        query = query.where(Account.dang_hoat_dong==active)
    return page_result(db,query.order_by(Account.ngay_tao.desc(),Account.id),page,page_size,lambda x: account_out(db,x))


@router.post('/admin/accounts', status_code=201)
def create_account(data: AccountCreate, user=Depends(admin), db: Session = Depends(get_db)):
    email = data.email.lower()
    if db.scalar(select(Account.id).where(Account.email==email)):
        fail(409,'EMAIL_ALREADY_EXISTS','Email đã được sử dụng')
    job = db.scalar(select(Role).where(Role.ma_quyen==data.ma_quyen, Role.dang_su_dung.is_(True)))
    if not job:
        fail(409,'STATE_CONFLICT','Chức vụ không khả dụng')
    account = Account(email=email,mat_khau_bam=passwords.hash(data.mat_khau),loai_tai_khoan='NHAN_VIEN')
    db.add(account); db.flush()
    db.add(Staff(id=account.id,ho_ten=data.ho_ten,ma_cv=job.ma_cv)); db.flush()
    audit(db,user,'account',account.id,'create',None,{'ma_quyen':data.ma_quyen},'Tạo tài khoản nội bộ')
    db.commit()
    return account_out(db,account,True)


@router.get('/admin/accounts/{key}', dependencies=[Depends(admin)])
def detail_account(key: UUID, db: Session = Depends(get_db)):
    return account_out(db,get_or_404(db,Account,key),True)


@router.patch('/admin/accounts/{key}')
def edit_account(key: UUID, data: AccountEdit, user=Depends(admin), db: Session = Depends(get_db)):
    account = get_or_404(db,Account,key,True)
    profile = db.get(Customer,key) if account.loai_tai_khoan=='KHACH_HANG' else db.get(Staff,key)
    values = data.model_dump(exclude_unset=True)
    if ('ho_ten' in values and values['ho_ten'] is None) or isinstance(profile,Staff) and 'so_dien_thoai' in values:
        fail(422,'VALIDATION_ERROR','Thông tin hồ sơ không hợp lệ')
    before = {k:getattr(profile,k) for k in values}
    for k,v in values.items(): setattr(profile,k,v)
    audit(db,user,'account',key,'profile',before,values,'Cập nhật hồ sơ')
    db.commit()
    return account_out(db,account,True)


@router.patch('/admin/accounts/{key}/role')
def role_account(key: UUID, data: RoleEdit, user=Depends(admin), db: Session = Depends(get_db)):
    return change_access(db,user,key,data)


@router.patch('/admin/accounts/{key}/status')
def status_account(key: UUID, data: StatusEdit, user=Depends(admin), db: Session = Depends(get_db)):
    return change_access(db,user,key,data)


@router.post('/users/me/change-password')
def change_password(data: PasswordChange, user=Depends(current), db: Session = Depends(get_db)):
    account = get_or_404(db,Account,user['account'].id,True)
    # A social-only account must link a verified email before adding password login.
    if not account.mat_khau_bam or not data.mat_khau_cu or not passwords.verify(data.mat_khau_cu,account.mat_khau_bam):
        fail(400,'INVALID_OPERATION','Mật khẩu hiện tại không đúng hoặc tài khoản không có mật khẩu')
    account.mat_khau_bam = passwords.hash(data.mat_khau)
    account.token_version += 1
    db.commit()
    return {'message':'Đã đổi mật khẩu. Vui lòng đăng nhập lại.'}


@router.get('/staff/rooms/status', dependencies=[Depends(permission('rooms.operations'))])
def operations(tang: int | None = None, ma_lp: int | None = None, tinh_trang: str | None = None,
               page: int = Query(1,ge=1),page_size: int = Query(20,ge=1,le=100),db: Session = Depends(get_db)):
    query = select(Room)
    if tang is not None: query = query.where(Room.tang==tang)
    if ma_lp is not None: query = query.where(Room.ma_lp==ma_lp)
    if tinh_trang: query = query.where(Room.tinh_trang_van_hanh==tinh_trang)
    def out(room):
        result = room_out(db,room,True)
        result['lich_tam_ngung'] = [columns(c) for c in db.scalars(select(Closure).where(
            Closure.ma_phong==room.ma_phong,Closure.dang_hieu_luc.is_(True),Closure.den_ngay>today()).order_by(Closure.tu_ngay))]
        result['lich_dat'] = [{'ngay_nhan':b.ngay_nhan,'ngay_tra':b.ngay_tra,'trang_thai':b.trang_thai}
            for b in db.scalars(select(Booking).where(Booking.ma_phong==room.ma_phong,
            Booking.trang_thai.in_(('CHO_XAC_NHAN','DA_XAC_NHAN')),Booking.ngay_tra>today()).order_by(Booking.ngay_nhan))]
        return result
    return page_result(db,query.order_by(Room.ma_phong),page,page_size,out)


@router.patch('/staff/rooms/{key}/operational-status')
def change_operation(key: int, data: OperationEdit, user=Depends(permission('rooms.operations')),db: Session = Depends(get_db)):
    room = lock_room(db,key)
    old, new = room.tinh_trang_van_hanh, data.tinh_trang_van_hanh
    transitions = {'SAN_SANG':'CAN_DON_DEP','CAN_DON_DEP':'DANG_DON_DEP','DANG_DON_DEP':'SAN_SANG','BAO_TRI':'SAN_SANG'}
    if new != 'BAO_TRI' and transitions.get(old) != new:
        fail(409,'STATE_CONFLICT','Không thể chuyển tình trạng phòng theo thứ tự này')
    if new == 'BAO_TRI':
        if old == 'BAO_TRI': fail(409,'STATE_CONFLICT','Phòng đã được đánh dấu bảo trì')
        if not data.tu_ngay or not data.den_ngay or data.den_ngay<=data.tu_ngay:
            fail(422,'VALIDATION_ERROR','Bảo trì cần khoảng ngày hợp lệ')
        if conflict(db,key,data.tu_ngay,data.den_ngay):
            fail(409,'ROOM_UNAVAILABLE','Lịch bảo trì giao với đặt phòng hoặc kỳ tạm ngừng')
        closure = Closure(ma_phong=key,tu_ngay=data.tu_ngay,den_ngay=data.den_ngay,
            ly_do=data.ly_do,nguoi_tao=user['account'].id)
        db.add(closure); db.flush()
        after = {'tinh_trang_van_hanh':new,'ma_ngung':closure.ma_ngung}
    else:
        if old == 'BAO_TRI':
            from app.models import Audit
            previous = db.scalar(select(Audit).where(Audit.entity=='room',Audit.entity_id==str(key),
                Audit.action=='operation').order_by(Audit.id.desc()).limit(1))
            closure_id = previous.after.get('ma_ngung') if previous and previous.after else None
            if closure_id:
                closure = db.get(Closure,closure_id)
                if closure and closure.ma_phong==key: closure.dang_hieu_luc=False
        after = {'tinh_trang_van_hanh':new}
    room.tinh_trang_van_hanh = new
    audit(db,user,'room',key,'operation',{'tinh_trang_van_hanh':old},after,data.ly_do)
    db.commit()
    return room_out(db,room,True)


@router.get('/staff/bookings/{key}/payments', dependencies=[Depends(permission('payments.collect'))])
def payments(key: UUID, page: int = Query(1,ge=1),page_size: int = Query(20,ge=1,le=100),db: Session = Depends(get_db)):
    booking = get_or_404(db,Booking,key)
    result = page_result(db,select(Payment).where(Payment.ma_pdp==key).order_by(Payment.ngay_tao.desc(),Payment.id),page,page_size,columns)
    result.update(balance(db,booking))
    return result


@router.post('/staff/bookings/{key}/payments', status_code=201)
def collect(key: UUID,data: PaymentCreate,user=Depends(permission('payments.collect')),db: Session = Depends(get_db)):
    return columns(record(db,user,data,booking_id=key))


@router.post('/admin/payments/{key}/refunds', status_code=201)
def refund(key: UUID,data: RefundCreate,user=Depends(permission('payments.refund')),db: Session = Depends(get_db)):
    return columns(record(db,user,data,original_id=key))


@router.get('/notifications/unread-count')
def unread(user=Depends(current),db: Session = Depends(get_db)):
    return {'count':db.scalar(select(func.count()).select_from(Notification).where(
        Notification.tai_khoan_id==user['account'].id,Notification.ngay_doc.is_(None)))}


@router.patch('/notifications/read-all')
def read_all(user=Depends(current),db: Session = Depends(get_db)):
    db.execute(update(Notification).where(Notification.tai_khoan_id==user['account'].id,
        Notification.ngay_doc.is_(None)).values(ngay_doc=datetime.now(timezone.utc)))
    db.commit()
    return {'status':'ok'}


@router.get('/notifications')
def notifications(page: int = Query(1,ge=1),page_size: int = Query(20,ge=1,le=100),
                  user=Depends(current),db: Session = Depends(get_db)):
    return page_result(db,select(Notification).where(Notification.tai_khoan_id==user['account'].id)
        .order_by(Notification.ngay_tao.desc(),Notification.id),page,page_size,columns)


@router.patch('/notifications/{key}/read')
def read_one(key: UUID,user=Depends(current),db: Session = Depends(get_db)):
    notification = db.scalar(select(Notification).where(Notification.id==key,
        Notification.tai_khoan_id==user['account'].id).with_for_update())
    if not notification: fail(404,'NOT_FOUND','Không tìm thấy thông báo')
    notification.ngay_doc = notification.ngay_doc or datetime.now(timezone.utc)
    db.commit()
    return columns(notification)

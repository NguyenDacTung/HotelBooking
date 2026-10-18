import hashlib,hmac,secrets,smtplib
from datetime import timedelta
from email.message import EmailMessage
from uuid import UUID
from fastapi import APIRouter,Depends,Request
from sqlalchemy import select,text,delete
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.errors import fail
from app.core.security import passwords
from app.db.session import get_db
from app.models import Account,ResetCode,LoginAttempt
from app.schemas.requests import Input,Email
from pydantic import Field
from app.services.stays import now

router=APIRouter(tags=['Khôi phục tài khoản'])

def digest(value):return hmac.new(settings().jwt_secret.encode(),value.encode(),hashlib.sha256).hexdigest()

def throttle(db,key,limit):
    key=digest(key)
    db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key,0))'),{'key':key})
    row=db.get(LoginAttempt,key)
    if not row:row=LoginAttempt(khoa=key,so_lan=0,bat_dau=now());db.add(row)
    if row.bat_dau<now()-timedelta(minutes=15):row.so_lan=0;row.bat_dau=now()
    row.so_lan+=1;count=row.so_lan;db.commit()
    if count>limit:fail(429,'RATE_LIMITED','Bạn đã thử quá nhiều lần. Vui lòng thử lại sau 15 phút.')

def login_limits(db,email,ip):
    throttle(db,'login-ip:'+ip,60);throttle(db,'login-email:'+email,8)

class Forgot(Input): email:Email
class Recover(Forgot):
    ma_xac_nhan:str=Field(pattern=r'^\d{6}$')
    mat_khau:str=Field(min_length=8,max_length=128)

def deliver(email,code):
    c=settings();message=EmailMessage()
    message['Subject']='TETRA - Khoi phuc mat khau';message['From']=c.smtp_from;message['To']=email
    message.set_content(f'Mã khôi phục mật khẩu TETRA: {code}\nMã có hiệu lực 10 phút và chỉ dùng một lần. Nếu bạn không yêu cầu, hãy bỏ qua email này.')
    cls=smtplib.SMTP_SSL if c.smtp_port==465 else smtplib.SMTP
    with cls(c.smtp_host,c.smtp_port,timeout=10) as smtp:
        if c.smtp_starttls and c.smtp_port!=465:smtp.starttls()
        if c.smtp_user:smtp.login(c.smtp_user,c.smtp_password)
        smtp.send_message(message)

@router.post('/auth/forgot-password')
def forgot(data:Forgot,request:Request,db:Session=Depends(get_db)):
    c=settings()
    if not c.smtp_host or not c.smtp_from:fail(503,'RECOVERY_NOT_CONFIGURED','Khôi phục qua email chưa được cấu hình')
    throttle(db,'reset-ip:'+(request.client.host if request.client else 'unknown'),10)
    throttle(db,'reset-email:'+data.email,3)
    account=db.scalar(select(Account).where(Account.email==data.email,Account.dang_hoat_dong.is_(True)))
    if account:
        old=db.scalars(select(ResetCode).where(ResetCode.tai_khoan_id==account.id,ResetCode.da_dung.is_(False))).all()
        for item in old:item.da_dung=True
        code=f'{secrets.randbelow(1000000):06d}'
        row=ResetCode(tai_khoan_id=account.id,ma_bam=digest(data.email+':'+code),het_han=now()+timedelta(minutes=10))
        db.add(row);db.commit()
        try:deliver(data.email,code)
        except Exception:
            row.da_dung=True;db.commit();fail(503,'MAIL_UNAVAILABLE','Chưa gửi được email. Vui lòng thử lại sau.')
    return {'message':'Nếu email hợp lệ, bạn sẽ nhận được mã khôi phục có hiệu lực 10 phút.'}

@router.post('/auth/reset-password')
def recover(data:Recover,request:Request,db:Session=Depends(get_db)):
    throttle(db,'reset-verify:'+(request.client.host if request.client else 'unknown'),20)
    account=db.scalar(select(Account).where(Account.email==data.email).with_for_update())
    row=db.scalar(select(ResetCode).where(ResetCode.tai_khoan_id==account.id,ResetCode.da_dung.is_(False)).order_by(ResetCode.het_han.desc()).with_for_update()) if account else None
    if not row or row.het_han<now() or row.so_lan_sai>=5:fail(400,'INVALID_RESET','Mã không hợp lệ hoặc đã hết hạn')
    if not hmac.compare_digest(row.ma_bam,digest(data.email+':'+data.ma_xac_nhan)):
        row.so_lan_sai+=1;db.commit();fail(400,'INVALID_RESET','Mã không hợp lệ hoặc đã hết hạn')
    row.da_dung=True;account.mat_khau_bam=passwords.hash(data.mat_khau);account.dang_nhap_noi_bo=True;account.token_version+=1
    db.execute(delete(LoginAttempt).where(LoginAttempt.khoa==digest('login-email:'+data.email)))
    db.commit();return {'message':'Đã đặt mật khẩu mới. Vui lòng đăng nhập lại.'}

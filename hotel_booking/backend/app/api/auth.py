from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from app.core.errors import fail
from app.core.security import current, passwords, dummy_hash, issue_token, principal
from app.core.config import settings
from app.db.session import get_db
from app.models import Account, Customer
from app.schemas.requests import Login, Register, ProfilePatch
from app.schemas.responses import ProfileOut, profile_out

router = APIRouter(tags=['Tài khoản'])


@router.post('/auth/register', status_code=201, response_model=ProfileOut)
def register(data: Register, db: Session = Depends(get_db)):
    if db.scalar(select(Account.id).where(Account.email == data.email)):
        fail(409, 'EMAIL_ALREADY_EXISTS', 'Email đã được sử dụng')
    account = Account(email=data.email, mat_khau_bam=passwords.hash(data.mat_khau), loai_tai_khoan='KHACH_HANG')
    db.add(account)
    db.flush()
    db.add(Customer(id=account.id, ho_ten=data.ho_ten, so_dien_thoai=data.so_dien_thoai))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        fail(409, 'EMAIL_ALREADY_EXISTS', 'Email đã được sử dụng')
    return profile_out(principal(db, account))


@router.post('/auth/login')
def login(data: Login, db: Session = Depends(get_db)):
    account = db.scalar(select(Account).where(Account.email == data.email))
    valid = passwords.verify(data.mat_khau, account.mat_khau_bam if account and account.mat_khau_bam else dummy_hash)
    if not account or not valid:
        fail(401, 'UNAUTHENTICATED', 'Email hoặc mật khẩu không đúng')
    principal(db, account)
    return {'access_token': issue_token(account), 'token_type': 'bearer',
            'expires_in': settings().access_token_expire_minutes * 60}


@router.get('/users/me', response_model=ProfileOut)
def me(user=Depends(current)):
    return profile_out(user)


@router.patch('/users/me', response_model=ProfileOut)
def update_me(data: ProfilePatch, user=Depends(current), db: Session = Depends(get_db)):
    values = data.model_dump(exclude_unset=True)
    if 'ho_ten' in values and values['ho_ten'] is None:
        fail(422, 'VALIDATION_ERROR', 'Họ tên không được rỗng')
    if user['role'] != 'KHACH_HANG' and 'so_dien_thoai' in values:
        fail(422, 'VALIDATION_ERROR', 'Hồ sơ nhân viên không có số điện thoại')
    for name, value in values.items():
        setattr(user['profile'], name, value)
    db.commit()
    return profile_out(user)

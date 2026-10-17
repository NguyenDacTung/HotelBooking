from datetime import datetime, timedelta, timezone
from uuid import UUID
import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pwdlib import PasswordHash
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.errors import fail
from app.db.session import get_db
from app.models import Account, Customer, Staff, Role

passwords = PasswordHash.recommended()
bearer = HTTPBearer(auto_error=False)
# Equal-cost verification for unknown users.
dummy_hash = passwords.hash('non-user-verification-only')


def issue_token(account):
    now = datetime.now(timezone.utc)
    return jwt.encode({'sub': str(account.id), 'iat': now, 'ver': account.token_version,
                       'exp': now + timedelta(minutes=settings().access_token_expire_minutes)},
                      settings().jwt_secret, algorithm='HS256')


def principal(db, account):
    if account:
        db.refresh(account)
    if not account or not account.dang_hoat_dong:
        fail(401, 'UNAUTHENTICATED', 'Phiên đăng nhập không hợp lệ')
    if account.loai_tai_khoan == 'KHACH_HANG':
        profile = db.get(Customer, account.id)
        role = 'KHACH_HANG'
    else:
        profile = db.get(Staff, account.id)
        job = db.get(Role, profile.ma_cv) if profile else None
        if profile:
            db.refresh(profile)
            job = db.get(Role, profile.ma_cv)
        if job:
            db.refresh(job)
        if not profile or not profile.dang_hoat_dong or not job or not job.dang_su_dung:
            fail(401, 'UNAUTHENTICATED', 'Tài khoản nhân viên không còn hiệu lực')
        role = job.ma_quyen
    if not profile:
        fail(401, 'UNAUTHENTICATED', 'Hồ sơ không hợp lệ')
    return {'account': account, 'profile': profile, 'role': role}


def current(credentials: HTTPAuthorizationCredentials | None = Depends(bearer), db: Session = Depends(get_db)):
    try:
        if not credentials:
            raise ValueError()
        payload = jwt.decode(credentials.credentials, settings().jwt_secret,
                             algorithms=['HS256'], options={'require': ['sub', 'exp', 'iat']})
        account_id = UUID(payload['sub'])
    except (ValueError, TypeError, jwt.PyJWTError):
        fail(401, 'UNAUTHENTICATED', 'Vui lòng đăng nhập lại')
    account = db.scalar(select(Account).where(Account.id == account_id).execution_options(populate_existing=True))
    if not account or payload.get('ver') != account.token_version:
        fail(401, 'UNAUTHENTICATED', 'Phiên đã thay đổi, vui lòng đăng nhập lại')
    return principal(db, account)


def require(*roles):
    def check(user=Depends(current)):
        if user['role'] not in roles:
            fail(403, 'FORBIDDEN', 'Bạn không có quyền thực hiện thao tác này')
        return user
    return check


customer = require('KHACH_HANG')
staff = require('LE_TAN', 'QUAN_LY')
manager = require('QUAN_LY')

"""Biometric sign-in uses a Keystore-backed public key, never an OS boolean or password cache."""
import base64
import secrets
from datetime import timedelta
from uuid import UUID

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi import APIRouter, Depends, Request
from pydantic import Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.api.recovery import throttle
from app.core.config import settings
from app.core.errors import fail
from app.core.security import current, issue_token, principal, passwords, dummy_hash
from app.db.session import get_db
from app.models import Account, BiometricDevice, BiometricChallenge
from app.schemas.requests import Input
from app.services.stays import now

router = APIRouter(tags=['Đăng nhập sinh trắc học'])

class Enroll(Input):
    device_id: UUID
    public_key: str = Field(min_length=40, max_length=512)
    mat_khau: str = Field(min_length=1, max_length=128)

class Device(Input):
    device_id: UUID

class Proof(Input):
    challenge_id: UUID
    signature: str = Field(min_length=8, max_length=256)

def key(value):
    try:
        public = serialization.load_der_public_key(base64.b64decode(value, validate=True))
        if not isinstance(public, ec.EllipticCurvePublicKey) or not isinstance(public.curve, ec.SECP256R1):
            raise ValueError()
        return public
    except (ValueError, TypeError):
        fail(422, 'INVALID_PUBLIC_KEY', 'Thiết bị chưa cung cấp khóa đăng nhập hợp lệ')

def invalid():
    fail(401, 'BIOMETRIC_INVALID', 'Đăng nhập vân tay đã hết hiệu lực. Vui lòng dùng email và mật khẩu rồi bật lại.')

def challenge(db, device, purpose):
    row = BiometricChallenge(device_id=device.id, message=f'TETRA:{purpose}:{device.id}:{secrets.token_urlsafe(32)}',
                             purpose=purpose, het_han=now()+timedelta(minutes=2))
    db.add(row); db.commit()
    return {'challenge_id': str(row.id), 'message': row.message}

def verify(db, data, purpose, account_id=None):
    row = db.scalar(select(BiometricChallenge).where(BiometricChallenge.id == data.challenge_id).with_for_update())
    if not row or row.used or row.purpose != purpose or row.het_han <= now():
        invalid()
    device = db.scalar(select(BiometricDevice).where(BiometricDevice.id == row.device_id).with_for_update())
    if account_id is not None and device.tai_khoan_id != account_id:
        invalid()
    row.used = True
    db.flush()
    try:
        key(device.public_key).verify(base64.b64decode(data.signature, validate=True), row.message.encode(), ec.ECDSA(hashes.SHA256()))
    except (ValueError, InvalidSignature):
        db.commit()  # A failed proof also consumes its one-use challenge.
        invalid()
    account = db.scalar(select(Account).where(Account.id == device.tai_khoan_id).with_for_update())
    if device.revoked or device.het_han <= now() or not account or device.token_version != account.token_version:
        db.commit(); invalid()
    principal(db, account)
    return device, account

@router.post('/users/me/biometric', status_code=201)
def enroll(data: Enroll, user=Depends(current), db: Session=Depends(get_db)):
    throttle(db, 'biometric-enroll:'+str(user['account'].id), 5)
    account = db.scalar(select(Account).where(Account.id == user['account'].id).with_for_update())
    if not passwords.verify(data.mat_khau, account.mat_khau_bam or dummy_hash):
        fail(400, 'PASSWORD_INVALID', 'Mật khẩu xác nhận chưa đúng; chưa bật đăng nhập vân tay')
    key(data.public_key)
    if db.get(BiometricDevice, data.device_id):
        fail(409, 'DEVICE_EXISTS', 'Hãy bật lại đăng nhập vân tay với khóa thiết bị mới')
    count = db.scalar(select(func.count()).select_from(BiometricDevice).where(
        BiometricDevice.tai_khoan_id == user['account'].id, BiometricDevice.active.is_(True),
        BiometricDevice.revoked.is_(False), BiometricDevice.het_han > now()))
    if count >= 10:
        fail(409, 'DEVICE_LIMIT', 'Tài khoản đã đạt giới hạn thiết bị đăng nhập')
    device = BiometricDevice(id=data.device_id, tai_khoan_id=account.id, public_key=data.public_key,
                             token_version=account.token_version, het_han=now()+timedelta(days=90))
    db.add(device); db.flush()
    return challenge(db, device, 'ENROLL')

@router.post('/users/me/biometric/confirm')
def confirm(data: Proof, user=Depends(current), db: Session=Depends(get_db)):
    device, _ = verify(db, data, 'ENROLL', user['account'].id)
    device.active = True; db.commit()
    return {'device_id': str(device.id), 'expires_at': device.het_han.isoformat()}

@router.delete('/users/me/biometric/{device_id}')
def revoke(device_id: UUID, user=Depends(current), db: Session=Depends(get_db)):
    device = db.scalar(select(BiometricDevice).where(BiometricDevice.id == device_id).with_for_update())
    if not device or device.tai_khoan_id != user['account'].id:
        fail(404, 'NOT_FOUND', 'Không tìm thấy thiết bị')
    device.revoked = True; db.commit()
    return {'revoked': True}

@router.post('/auth/biometric/challenge')
def begin(data: Device, request: Request, db: Session=Depends(get_db)):
    throttle(db, 'biometric-ip:'+(request.client.host if request.client else 'unknown'), 60)
    throttle(db, 'biometric-device:'+str(data.device_id), 12)
    device = db.get(BiometricDevice, data.device_id)
    if not device or not device.active or device.revoked or device.het_han <= now():
        invalid()
    account = db.get(Account, device.tai_khoan_id)
    if not account or account.token_version != device.token_version:
        invalid()
    principal(db, account)
    return challenge(db, device, 'LOGIN')

@router.post('/auth/biometric/login')
def login(data: Proof, request: Request, db: Session=Depends(get_db)):
    throttle(db, 'biometric-proof-ip:'+(request.client.host if request.client else 'unknown'), 60)
    device, account = verify(db, data, 'LOGIN')
    if not device.active:
        db.commit(); invalid()
    db.commit()
    return {'access_token': issue_token(account), 'token_type': 'bearer',
            'expires_in': settings().access_token_expire_minutes*60}

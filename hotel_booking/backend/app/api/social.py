from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.orm import Session
import httpx
from app.db.session import get_db
from app.core.config import settings
from app.core.security import current, issue_token, principal
from app.core.errors import fail
from app.models import Account, Customer, Identity
from app.schemas.upgrade import SocialCredential

router = APIRouter(tags=['Đăng nhập liên kết'])


def verify(provider, credential):
    config = settings()
    if provider == 'GOOGLE':
        if not config.google_client_id:
            fail(503,'PROVIDER_NOT_CONFIGURED','Google chưa được cấu hình')
        try:
            from google.oauth2 import id_token
            from google.auth.transport.requests import Request
            payload = id_token.verify_oauth2_token(credential, Request(), config.google_client_id)
            if not payload.get('sub') or payload.get('aud') != config.google_client_id:
                raise ValueError()
            return {'subject':payload['sub'],'name':payload.get('name') or 'Khách TETRA',
                    'email':payload.get('email') if payload.get('email_verified') is True else None}
        except Exception:
            fail(401,'INVALID_SOCIAL_TOKEN','Không xác minh được đăng nhập Google')
    if provider == 'FACEBOOK':
        if not config.facebook_app_id or not config.facebook_app_secret:
            fail(503,'PROVIDER_NOT_CONFIGURED','Facebook chưa được cấu hình')
        try:
            root = f'https://graph.facebook.com/{config.facebook_graph_version}'
            with httpx.Client(timeout=10) as client:
                response = client.get(root+'/debug_token',params={'input_token':credential,
                    'access_token':config.facebook_app_id+'|'+config.facebook_app_secret})
                response.raise_for_status()
                info = response.json()['data']
                now = datetime.now(timezone.utc).timestamp()
                if (info.get('is_valid') is not True or info.get('app_id') != config.facebook_app_id
                    or not info.get('user_id') or info.get('expires_at',0)<=now
                    or (info.get('data_access_expires_at') and info['data_access_expires_at']<=now)):
                    raise ValueError()
                profile = client.get(root+'/me',params={'access_token':credential,'fields':'id,name'})
                profile.raise_for_status()
                body = profile.json()
                if body['id'] != info['user_id']: raise ValueError()
                return {'subject':body['id'],'name':body.get('name') or 'Khách TETRA','email':None}
        except Exception:
            fail(401,'INVALID_SOCIAL_TOKEN','Không xác minh được đăng nhập Facebook')
    fail(422,'VALIDATION_ERROR','Nhà cung cấp không hợp lệ')


@router.get('/auth/providers')
def providers():
    config = settings()
    return {'google':bool(config.google_client_id),
            'facebook':bool(config.facebook_app_id and config.facebook_app_secret)}


def social_login(db, provider, credential):
    data = verify(provider, credential)
    identity = db.scalar(select(Identity).where(Identity.provider==provider,Identity.provider_subject==data['subject']))
    if identity:
        account = db.get(Account,identity.tai_khoan_id)
    else:
        email = data['email'].strip().lower() if data.get('email') else None
        if email and db.scalar(select(Account.id).where(Account.email==email)):
            fail(409,'LINK_REQUIRED','Email đã có tài khoản. Hãy đăng nhập tài khoản đó để liên kết.')
        account = Account(email=email,mat_khau_bam=None,dang_nhap_noi_bo=False,loai_tai_khoan='KHACH_HANG')
        db.add(account); db.flush()
        db.add(Customer(id=account.id,ho_ten=data['name'][:120]))
        db.add(Identity(tai_khoan_id=account.id,provider=provider,provider_subject=data['subject']))
        db.commit()
    principal(db,account)
    return {'access_token':issue_token(account),'token_type':'bearer',
            'expires_in':settings().access_token_expire_minutes*60}


@router.post('/auth/google')
def google(data: SocialCredential,db: Session = Depends(get_db)):
    return social_login(db,'GOOGLE',data.credential)


@router.post('/auth/facebook')
def facebook(data: SocialCredential,db: Session = Depends(get_db)):
    return social_login(db,'FACEBOOK',data.credential)


@router.get('/users/me/identities')
def identities(user=Depends(current),db: Session = Depends(get_db)):
    return {'items':[{'provider':i.provider,'ngay_tao':i.ngay_tao} for i in db.scalars(
        select(Identity).where(Identity.tai_khoan_id==user['account'].id).order_by(Identity.provider))]}


@router.post('/users/me/identities/{provider}')
def link(provider: str,data: SocialCredential,user=Depends(current),db: Session = Depends(get_db)):
    from app.services.bookings import get_or_404
    get_or_404(db,Account,user['account'].id,True)
    provider = provider.upper()
    verified = verify(provider,data.credential)
    existing = db.scalar(select(Identity).where(Identity.provider==provider,Identity.provider_subject==verified['subject']))
    if existing:
        if existing.tai_khoan_id != user['account'].id:
            fail(409,'IDENTITY_IN_USE','Phương thức đăng nhập đã liên kết tài khoản khác')
    else:
        db.add(Identity(tai_khoan_id=user['account'].id,provider=provider,provider_subject=verified['subject']))
    db.commit()
    return {'status':'linked'}


@router.delete('/users/me/identities/{provider}',status_code=204)
def unlink(provider: str,user=Depends(current),db: Session = Depends(get_db)):
    from app.services.bookings import get_or_404
    account = get_or_404(db,Account,user['account'].id,True)
    identity = db.scalar(select(Identity).where(Identity.provider==provider.upper(),Identity.tai_khoan_id==account.id))
    if not identity: fail(404,'NOT_FOUND','Chưa liên kết phương thức này')
    count = db.scalar(select(func.count()).select_from(Identity).where(Identity.tai_khoan_id==account.id))
    if not account.mat_khau_bam and count<=1:
        fail(400,'LAST_IDENTITY','Không thể bỏ phương thức đăng nhập cuối cùng')
    db.delete(identity)
    account.token_version += 1
    db.commit()

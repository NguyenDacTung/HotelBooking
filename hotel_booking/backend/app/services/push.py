"""FCM HTTP v1 durable outbox. No DB lock held while calling Firebase."""
from datetime import datetime,timezone,timedelta
from sqlalchemy import select,or_
from app.models import Notification,DeviceToken,Account
from app.core.config import settings

def dispatch(db):
    c=settings()
    if not c.firebase_project_id or not c.firebase_credentials:return
    from google.oauth2.service_account import Credentials
    from google.auth.transport.requests import AuthorizedSession
    credentials=Credentials.from_service_account_file(c.firebase_credentials,scopes=['https://www.googleapis.com/auth/firebase.messaging'])
    instant=datetime.now(timezone.utc)
    rows=db.scalars(select(Notification).where(Notification.push_luc.is_(None),Notification.ngay_tao>instant-timedelta(days=1),
        or_(Notification.push_retry_at.is_(None),Notification.push_retry_at<=instant)).order_by(Notification.ngay_tao).limit(20).with_for_update(skip_locked=True)).all()
    jobs=[]
    for row in rows:
        account=db.get(Account,row.tai_khoan_id)
        tokens=list(db.scalars(select(DeviceToken.token).where(DeviceToken.tai_khoan_id==row.tai_khoan_id,DeviceToken.token_version==account.token_version))) if account.dang_hoat_dong else []
        if not tokens:row.push_luc=instant;continue
        row.push_attempts+=1
        # Lease survives worker crashes and suppresses concurrent dispatchers.
        row.push_retry_at=instant+timedelta(minutes=10)
        jobs.append((row.id,row.ma_pdp,row.push_attempts,tokens))
    db.commit()
    with AuthorizedSession(credentials) as http:
        for key,booking,attempt,tokens in jobs:
            retry=False;invalid=[]
            for token in tokens:
                payload={'message':{'token':token,'notification':{'title':'TETRA','body':'Bạn có cập nhật đặt phòng mới.'},
                    'data':{'booking_id':str(booking or ''),'notification_id':str(key)},
                    'android':{'ttl':'3600s','notification':{'tag':str(key)}}}}
                try:
                    r=http.post(f'https://fcm.googleapis.com/v1/projects/{c.firebase_project_id}/messages:send',json=payload,timeout=10)
                    if r.status_code==404:invalid.append(token)
                    elif r.status_code>=400:retry=True
                except Exception:retry=True # no gateway response or sensitive details logged
            row=db.get(Notification,key,with_for_update=True)
            if row and row.push_luc is None and row.push_attempts==attempt:
                if retry:row.push_retry_at=datetime.now(timezone.utc)+timedelta(seconds=min(3600,60*2**min(attempt-1,6)))
                else:row.push_luc=datetime.now(timezone.utc);row.push_retry_at=None
            for token in invalid:
                device=db.scalar(select(DeviceToken).where(DeviceToken.token==token))
                if device:db.delete(device)
            db.commit()

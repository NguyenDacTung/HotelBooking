from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from datetime import timedelta
from uuid import uuid4
import hashlib,hmac,io
import pytest
from PIL import Image
from sqlalchemy.orm import Session
from sqlalchemy import select,func
from test_postgres import setup,make,client_for
from app.models import Booking,Review,Payment,PaymentAttempt,Room
from app.services.stays import now
from app.services.rules import today
from app.services.payments import balance
from app.services.reports import revenue
pytestmark=pytest.mark.postgres

def completed(env):
    b=make(env)
    with Session(env['engine']) as db:
        row=db.get(Booking,b.ma_pdp);row.trang_thai='DA_HOAN_TAT';row.nhan_phong_luc=now()-timedelta(days=2);row.tra_phong_luc=now();db.commit()
    return b

def test_review_completed_owner_privacy_moderation(setup):
    b=make(setup);owner=client_for(setup);other=client_for(setup,1);admin=client_for(setup,2);staff=client_for(setup,3);url=f'/bookings/{b.ma_pdp}/review'
    assert owner.post(url,json={'so_sao':5}).status_code==409
    with Session(setup['engine']) as db:
        db.get(Booking,b.ma_pdp).trang_thai='DA_HOAN_TAT';db.commit()
    assert owner.post(url,json={'so_sao':5}).status_code==409 # real handover required
    with Session(setup['engine']) as db:db.get(Booking,b.ma_pdp).tra_phong_luc=now();db.commit()
    assert other.post(url,json={'so_sao':5}).status_code==404
    assert staff.post(url,json={'so_sao':5}).status_code==403
    for value in (0,6,True,2.5):assert owner.post(url,json={'so_sao':value}).status_code==422
    assert owner.post(url,json={'so_sao':3,'nhan_xet':'a'*1001}).status_code==422
    row=owner.post(url,json={'so_sao':3,'nhan_xet':'Hài lòng'}).json()
    assert owner.post(url,json={'so_sao':5}).status_code==409
    public=other.get(f"/rooms/{setup['room']}/reviews").json()
    assert public['so_danh_gia']==1 and public['diem_trung_binh']==3
    assert not {'email','so_dien_thoai','ma_pdp','ma_kh'} & public['items'][0].keys()
    assert other.get(url).status_code==404
    assert owner.patch(f"/admin/reviews/{row['id']}/visibility",json={'hien_thi':False}).status_code==403
    assert admin.patch(f"/admin/reviews/{row['id']}/visibility",json={'hien_thi':False}).status_code==200
    assert owner.get('/users/me/reviews').json()['items'][0]['hien_thi'] is False
    assert other.get(f"/rooms/{setup['room']}/reviews").json()['so_danh_gia']==0
    assert admin.patch(f"/admin/reviews/{row['id']}/visibility",json={'hien_thi':True}).status_code==200
    assert owner.get(f"/rooms/{setup['room']}").json()['danh_gia']['so_danh_gia']==1

def test_review_race_one_per_stay(setup):
    b=completed(setup);barrier=Barrier(2)
    def send(_):
        c=client_for(setup);barrier.wait(timeout=10);return c.post(f'/bookings/{b.ma_pdp}/review',json={'so_sao':4}).status_code
    with ThreadPoolExecutor(2) as pool:assert sorted(pool.map(send,range(2)))==[201,409]
    with Session(setup['engine']) as db:assert db.scalar(select(func.count()).select_from(Review))==1

def test_optional_reasons_closure_reject_operations(setup):
    b=make(setup);admin=client_for(setup,2)
    assert admin.patch(f'/staff/bookings/{b.ma_pdp}/reject',json={}).status_code==200
    result=admin.post('/staff/room-closures',json={'ma_phong':setup['room'],'tu_ngay':str(today()+timedelta(days=30)),'den_ngay':str(today()+timedelta(days=31))})
    assert result.status_code==201,result.text
    result=admin.patch(f"/staff/rooms/{setup['room']}/operational-status",json={'tinh_trang_van_hanh':'CAN_DON_DEP'})
    assert result.status_code==200,result.text

def csv_preview(admin,raw):return admin.post('/admin/room-import/preview',files={'file':('rooms.csv',raw,'text/csv')})

def test_csv_validate_atomic_confirm_replay(setup):
    admin=client_for(setup,2);customer=client_for(setup)
    raw=('\ufeffso_phong,ma_lp,tang,ghi_chu\n201,'+str(setup['type'])+',2,"Có bàn, ghế"\n').encode('utf-8')
    assert csv_preview(customer,raw).status_code==403
    d=csv_preview(admin,raw).json();assert d['can_import'] is True
    url=f"/admin/room-import/{d['id']}/confirm"
    assert admin.post(url).json()['imported']==1
    assert admin.post(url).json()['replayed'] is True
    invalid=csv_preview(admin,('so_phong,ma_lp\n202,'+str(setup['type'])+'\n201,'+str(setup['type'])+'\n').encode()).json()
    assert invalid['can_import'] is False
    assert admin.post(f"/admin/room-import/{invalid['id']}/confirm").status_code==409
    with Session(setup['engine']) as db:assert db.scalar(select(Room).where(Room.so_phong=='202')) is None

def test_csv_competing_batches_only_one_commits(setup):
    admin=client_for(setup,2);raw=f"so_phong,ma_lp\nCSV-RACE,{setup['type']}\n".encode()
    ids=[csv_preview(admin,raw).json()['id'] for _ in range(2)];barrier=Barrier(2)
    def confirm(key):c=client_for(setup,2);barrier.wait(timeout=10);return c.post(f'/admin/room-import/{key}/confirm').status_code
    with ThreadPoolExecutor(2) as pool:assert sorted(pool.map(confirm,ids))==[200,409]

def test_private_feedback_image_and_device_whitelist(setup,tmp_path,monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings(),'private_upload_dir',tmp_path/'private')
    c=client_for(setup);admin=client_for(setup,2);other=client_for(setup,1)
    assert c.post('/feedback',data={'noi_dung':' ','thiet_bi':'{}'}).status_code==422
    assert c.post('/feedback',data={'noi_dung':'Test','thiet_bi':'{"token":"never"}'}).status_code==422
    raw=io.BytesIO();Image.new('RGB',(10,10),'blue').save(raw,format='PNG')
    response=c.post('/feedback',data={'noi_dung':'Kiểm thử ảnh riêng','thiet_bi':'{"model":"Test"}'},files={'file':('private.png',raw.getvalue(),'image/png')})
    assert response.status_code==201,response.text
    url=f"/feedback/{response.json()['id']}/attachment"
    assert c.get(url).status_code==200 and admin.get(url).status_code==200
    assert other.get(url).status_code==404
    name=admin.get('/admin/feedback').json()['items'][0]['anh'];assert c.get('/uploads/'+name).status_code==404
    assert other.get('/admin/feedback').status_code==403

def configure(monkeypatch):
    from app.core.config import settings
    c=settings()
    for key,value in {'payment_public_base_url':'https://tetra.example.test','momo_partner_code':'TEST','momo_access_key':'test-access','momo_secret_key':'test-secret','payment_environment':'sandbox'}.items():monkeypatch.setattr(c,key,value)

def test_capabilities_public_no_secrets(setup):
    c=client_for(setup);r=c.get('/app/capabilities');assert r.status_code==200
    text=r.text.lower();assert not any(k in text for k in ('password','secret','access_key','jwt','credentials'))
    assert r.json()['payments']['momo']['configured'] is False

def test_payment_unconfigured_never_creates_attempt(setup):
    b=make(setup);admin=client_for(setup,2);admin.patch(f'/staff/bookings/{b.ma_pdp}/confirm')
    r=client_for(setup).post(f'/bookings/{b.ma_pdp}/online-payments',json={'provider':'MOMO','request_id':str(uuid4())})
    assert r.status_code==503
    with Session(setup['engine']) as db:assert db.scalar(select(func.count()).select_from(PaymentAttempt))==0

def test_online_unknown_stays_pending_and_blocks_manual(setup,monkeypatch):
    from app.services import gateways
    configure(monkeypatch);b=make(setup);admin=client_for(setup,2);admin.patch(f'/staff/bookings/{b.ma_pdp}/confirm')
    monkeypatch.setattr(gateways,'create',lambda *a:(_ for _ in ()).throw(TimeoutError()))
    c=client_for(setup);url=f'/bookings/{b.ma_pdp}/online-payments';body={'provider':'MOMO','request_id':str(uuid4())}
    assert c.post(url,json=body).status_code==503
    replay=c.post(url,json=body);assert replay.status_code==200 and replay.json()['state']=='CREATED'
    assert admin.post(f'/staff/bookings/{b.ma_pdp}/payments',json={'request_id':str(uuid4()),'so_tien':1,'phuong_thuc':'TIEN_MAT'}).status_code==409
    with Session(setup['engine']) as db:assert db.scalar(select(func.count()).select_from(PaymentAttempt))==1

def callback(a,amount=None):
    from app.core.config import settings
    c=settings();data={'amount':int(a.amount) if amount is None else amount,'extraData':'','message':'Success','orderId':a.reference,'orderInfo':'TETRA Hotel','orderType':'momo_wallet','partnerCode':c.momo_partner_code,'payType':'qr','requestId':str(a.request_id),'responseTime':123,'resultCode':0,'transId':123456789}
    raw='&'.join(f'{k}={v}' for k,v in sorted({'accessKey':c.momo_access_key,**data}.items()))
    data['signature']=hmac.new(c.momo_secret_key.encode(),raw.encode(),hashlib.sha256).hexdigest();return data

def test_signed_ipn_tampering_duplicate_late_sandbox(setup,monkeypatch):
    from app.services import gateways
    configure(monkeypatch);monkeypatch.setattr(gateways,'create',lambda *a:'https://test-payment.momo.vn/test')
    b=make(setup);admin=client_for(setup,2);admin.patch(f'/staff/bookings/{b.ma_pdp}/confirm');c=client_for(setup)
    r=c.post(f'/bookings/{b.ma_pdp}/online-payments',json={'provider':'MOMO','request_id':str(uuid4())});assert r.status_code==200,r.text
    with Session(setup['engine']) as db:a=db.get(PaymentAttempt,UUID(r.json()['id']));db.expunge(a)
    data=callback(a)
    assert c.post('/payments/momo/ipn',json=data|{'amount':1}).status_code==400
    assert c.post('/payments/momo/ipn',json=callback(a,1)).status_code==400
    assert c.patch(f'/bookings/{b.ma_pdp}/cancel',json={}).status_code==200
    assert c.post('/payments/momo/ipn',json=data).status_code==204
    assert c.post('/payments/momo/ipn',json=data).status_code==204
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(Payment))==1
        booking=db.get(Booking,b.ma_pdp);assert booking.trang_thai=='DA_HUY'
        assert balance(db,booking)['da_thu']==0
        assert revenue(db,today(),today())['kpi']['thu']==0
from uuid import UUID


def test_calendar_staff_access_and_bounded_range(setup):
    b=make(setup);staff=client_for(setup,3);c=client_for(setup)
    url=f"/staff/rooms/{setup['room']}/calendar";params={'tu_ngay':str(today()),'den_ngay':str(today()+timedelta(days=30))}
    assert c.get(url,params=params).status_code==403
    data=staff.get(url,params=params).json();assert data['bookings'][0]['id']==str(b.ma_pdp)
    assert 'ten_lien_he' not in str(data) and 'sdt_lien_he' not in str(data)
    assert staff.get(url,params=params|{'den_ngay':str(today()+timedelta(days=100))}).status_code==422
    assert staff.get(f'/staff/booking-reference/TETRA:1:{b.ma_pdp}').status_code==200
    assert c.get(f'/staff/booking-reference/{b.ma_pdp}').status_code==403

def test_production_late_payment_records_refund_without_resurrection(setup,monkeypatch):
    from app.services import gateways
    from app.core.config import settings
    configure(monkeypatch);monkeypatch.setattr(settings(),'payment_environment','production');monkeypatch.setattr(settings(),'momo_endpoint','https://payment.momo.vn/v2/gateway/api')
    monkeypatch.setattr(gateways,'create',lambda *a:'https://payment.momo.vn/test')
    b=make(setup);admin=client_for(setup,2);admin.patch(f'/staff/bookings/{b.ma_pdp}/confirm');c=client_for(setup)
    r=c.post(f'/bookings/{b.ma_pdp}/online-payments',json={'provider':'MOMO','request_id':str(uuid4())});assert r.status_code==200
    with Session(setup['engine']) as db:a=db.get(PaymentAttempt,UUID(r.json()['id']));db.expunge(a)
    assert c.patch(f'/bookings/{b.ma_pdp}/cancel',json={}).status_code==200
    barrier=Barrier(2);data=callback(a)
    def ipn(_):cl=client_for(setup);barrier.wait(timeout=10);return cl.post('/payments/momo/ipn',json=data).status_code
    with ThreadPoolExecutor(2) as pool:assert list(pool.map(ipn,range(2)))==[204,204]
    with Session(setup['engine']) as db:
        b=db.get(Booking,b.ma_pdp);assert b.trang_thai=='DA_HUY' and balance(db,b)['can_hoan_tien']==1000000
        assert db.scalar(select(func.count()).select_from(Payment))==1

def test_online_create_competes_manual_collection(setup,monkeypatch):
    from app.services import gateways
    configure(monkeypatch);monkeypatch.setattr(gateways,'create',lambda *a:'https://test-payment.momo.vn/test')
    b=make(setup);client_for(setup,2).patch(f'/staff/bookings/{b.ma_pdp}/confirm');barrier=Barrier(2)
    def collect(kind):
        c=client_for(setup,0 if kind=='online' else 3);barrier.wait(timeout=10)
        if kind=='online':return c.post(f'/bookings/{b.ma_pdp}/online-payments',json={'provider':'MOMO','request_id':str(uuid4())}).status_code
        return c.post(f'/staff/bookings/{b.ma_pdp}/payments',json={'request_id':str(uuid4()),'so_tien':1000000,'phuong_thuc':'TIEN_MAT'}).status_code
    with ThreadPoolExecutor(2) as pool:results=list(pool.map(collect,['online','manual']))
    assert sorted(results) in ([200,409],[201,409])

def test_vnpay_signed_amount_ack_and_return_never_settles(setup,monkeypatch):
    from app.services import gateways
    from app.core.config import settings
    from urllib.parse import urlencode
    c=settings();monkeypatch.setattr(c,'payment_public_base_url','https://tetra.example.test');monkeypatch.setattr(c,'vnpay_tmn_code','TESTCODE');monkeypatch.setattr(c,'vnpay_hash_secret','test-vnpay-secret')
    b=make(setup);admin=client_for(setup,2);admin.patch(f'/staff/bookings/{b.ma_pdp}/confirm');owner=client_for(setup)
    r=owner.post(f'/bookings/{b.ma_pdp}/online-payments',json={'provider':'VNPAY','request_id':str(uuid4())});assert r.status_code==200,r.text
    with Session(setup['engine']) as db:a=db.get(PaymentAttempt,UUID(r.json()['id']));db.expunge(a)
    assert 'vnp_Amount=100000000' in r.json()['payment_url']
    data={'vnp_TmnCode':'TESTCODE','vnp_TxnRef':a.reference,'vnp_Amount':str(int(a.amount)*100),'vnp_ResponseCode':'00','vnp_TransactionStatus':'00','vnp_TransactionNo':'888123'}
    def sign(d):return d|{'vnp_SecureHash':hmac.new(b'test-vnpay-secret',urlencode(sorted(d.items())).encode(),hashlib.sha512).hexdigest()}
    assert owner.get('/payments/return',params=sign(data)).status_code==200
    with Session(setup['engine']) as db:assert db.scalar(select(func.count()).select_from(Payment))==0
    assert owner.get('/payments/vnpay/ipn',params=sign(data)|{'vnp_Amount':'1'}).json()['RspCode']=='97'
    assert owner.get('/payments/vnpay/ipn',params=sign(data|{'vnp_Amount':'1'})).json()['RspCode']=='04'
    assert owner.get('/payments/vnpay/ipn',params=sign(data)).json()['RspCode']=='00'
    assert owner.get('/payments/vnpay/ipn',params=sign(data)).json()['RspCode']=='02'
    with Session(setup['engine']) as db:assert db.scalar(select(func.count()).select_from(Payment))==1


def test_missing_persistent_media_blocks_upload_but_allows_text(setup,monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings(),'persistent_media_enabled',False)
    c=client_for(setup);admin=client_for(setup,2)
    raw=io.BytesIO();Image.new('RGB',(10,10),'blue').save(raw,format='PNG');file={'file':('image.png',raw.getvalue(),'image/png')}
    assert c.post('/users/me/avatar',files=file).status_code==503
    assert admin.post(f"/staff/rooms/{setup['room']}/images",files=file).status_code==503
    assert c.post('/feedback',data={'noi_dung':'Test'},files=file).status_code==503
    assert c.post('/feedback',data={'noi_dung':'Vẫn gửi được nội dung'}).status_code==201


def test_push_outbox_durable_backoff_and_no_transaction_during_io(setup,monkeypatch):
    from app.core.config import settings
    from app.models import DeviceToken,Notification
    from app.services.push import dispatch
    from google.oauth2.service_account import Credentials
    import google.auth.transport.requests as transport
    monkeypatch.setattr(settings(),'firebase_project_id','fixture-project');monkeypatch.setattr(settings(),'firebase_credentials','fixture-not-a-real-key.json')
    monkeypatch.setattr(Credentials,'from_service_account_file',lambda *a,**k:object())
    make(setup);sent=[]
    with Session(setup['engine']) as db:
        db.add(DeviceToken(tai_khoan_id=setup['ids'][2],token='fixture-device',token_version=0));db.commit()
        class Fake:
            def __enter__(self):return self
            def __exit__(self,*a):pass
            def post(self,*a,**kwargs):
                assert not db.in_transaction()
                sent.append(kwargs['json']);return type('Response',(),{'status_code':503 if len(sent)==1 else 200})()
        monkeypatch.setattr(transport,'AuthorizedSession',lambda *a:Fake())
        dispatch(db);assert len(sent)==1
        row=db.scalar(select(Notification).where(Notification.tai_khoan_id==setup['ids'][2]));assert row.push_attempts==1 and row.push_luc is None and row.push_retry_at>now()
        db.rollback();dispatch(db);assert len(sent)==1
        row=db.get(Notification,row.id);row.push_retry_at=now()-timedelta(seconds=1);db.commit()
        dispatch(db);assert len(sent)==2
        row=db.get(Notification,row.id);assert row.push_luc is not None and row.push_attempts==2
        assert sent[0]['message']['android']['notification']['tag']==sent[1]['message']['android']['notification']['tag']

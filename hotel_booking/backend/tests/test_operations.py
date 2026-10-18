"""PostgreSQL stay lifecycle, money reconciliation and credential recovery."""
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from uuid import uuid4
import pytest
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.models import Booking, Room, Charge, ResetCode
from app.services.stays import VN, policy, time_charge, expire_pending
from app.services.rules import today
from test_postgres import setup, client_for, make

pytestmark = pytest.mark.postgres

def instant(day, hour, minute=0): return datetime.combine(day, datetime.min.time(), VN).replace(hour=hour,minute=minute)

@pytest.mark.parametrize('hour,minute,expected',[(12,0,0),(12,1,150000),(15,0,150000),(15,1,250000),(18,0,250000),(18,1,500000)])
def test_late_fee_boundaries(setup,hour,minute,expected):
    b=make(setup)
    assert time_charge(b,'TRA_MUON',instant(b.ngay_tra,hour,minute))==expected
    assert time_charge(b,'TRA_MUON',instant(b.ngay_tra+timedelta(days=1),hour,minute))==500000+expected

@pytest.mark.parametrize('hour,expected',[(5,500000),(6,250000),(13,250000),(14,0)])
def test_early_fee_boundaries(setup,hour,expected):
    b=make(setup)
    assert time_charge(b,'NHAN_SOM',instant(b.ngay_nhan,hour))==expected

def test_same_day_lifecycle_reconciles_and_releases_room(setup,monkeypatch):
    b=make(setup,offset=0)
    staff=client_for(setup,3);guest=client_for(setup)
    assert staff.patch(f'/staff/bookings/{b.ma_pdp}/confirm').status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(today(),14))
    assert guest.post(f'/staff/bookings/{b.ma_pdp}/check-in',json={'ly_do':'Nhận phòng'}).status_code==403
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-in',json={'ly_do':'Kiểm tra giấy tờ'}).status_code==200
    assert guest.get(f'/rooms/{b.ma_phong}').json()['trang_thai_su_dung']=='DANG_SU_DUNG'
    charge={'loai':'MINIBAR','noi_dung':'Hai chai nước','don_gia':20000,'so_luong':2,'request_id':str(uuid4())}
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/charges',json=charge).status_code==201
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/charges',json=charge).status_code in (200,201)
    invoice=guest.post(f'/bookings/{b.ma_pdp}/request-checkout').json()
    assert invoice['tong_phu_thu']==40000 and invoice['tong_thanh_toan']==1040000
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-out',json={'ly_do':'Bàn giao'}).status_code==409
    payment={'request_id':str(uuid4()),'so_tien':1040000,'phuong_thuc':'TIEN_MAT'}
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/payments',json=payment).status_code==201
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-out',json={'ly_do':'Đã đối chiếu'}).status_code==200
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-out',json={'ly_do':'Lặp lại'}).status_code==409
    with Session(setup['engine']) as db:
        assert db.get(Room,b.ma_phong).tinh_trang_van_hanh=='CAN_DON_DEP'
        assert db.get(Booking,b.ma_pdp).tra_phong_luc is not None
        assert len(db.scalars(select(Charge)).all())==1

def test_hold_expiry_excludes_legacy(setup):
    new=make(setup);legacy=make(setup,offset=10)
    with Session(setup['engine']) as db:
        db.get(Booking,new.ma_pdp).giu_cho_den=instant(today()-timedelta(days=1),0)
        db.get(Booking,legacy.ma_pdp).giu_cho_den=None
        db.get(Booking,legacy.ma_pdp).chinh_sach={}
        db.commit();expire_pending(db)
        assert db.get(Booking,new.ma_pdp).trang_thai=='HET_HAN'
        assert db.get(Booking,legacy.ma_pdp).trang_thai=='CHO_XAC_NHAN'

def test_recovery_one_use_and_revokes_old_token(setup,monkeypatch):
    from app.core.config import settings
    c=settings();monkeypatch.setattr(c,'smtp_host','test.invalid');monkeypatch.setattr(c,'smtp_from','hotel@test.invalid')
    mails=[];monkeypatch.setattr('app.api.recovery.deliver',lambda email,code:mails.append(code))
    client=client_for(setup);old_token=client.headers['Authorization']
    assert client.post('/auth/forgot-password',json={'email':'user0@example.com'}).status_code==200
    assert len(mails)==1
    with Session(setup['engine']) as db:
        assert db.scalar(select(ResetCode)).ma_bam!=mails[0]
    body={'email':'user0@example.com','ma_xac_nhan':mails[0],'mat_khau':'new-test-password'}
    assert client.post('/auth/reset-password',json=body).status_code==200
    assert client.get('/users/me',headers={'Authorization':old_token}).status_code==401
    client.headers.pop('Authorization',None)
    assert client.post('/auth/reset-password',json=body).status_code==400
    assert client.post('/auth/login',json={'email':'user0@example.com','mat_khau':'new-test-password'}).status_code==200

def test_login_throttle_and_phone_validation(setup):
    client=client_for(setup)
    for _ in range(8):assert client.post('/auth/login',json={'email':'user0@example.com','mat_khau':'bad-password'}).status_code==401
    assert client.post('/auth/login',json={'email':'user0@example.com','mat_khau':'bad-password'}).status_code==429
    assert client.patch('/users/me',json={'so_dien_thoai':'abc'}).status_code==422

def test_simultaneous_checkin_one_transition(setup,monkeypatch):
    b=make(setup,offset=0);client=client_for(setup,3)
    assert client.patch(f'/staff/bookings/{b.ma_pdp}/confirm').status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(today(),14))
    barrier=Barrier(2)
    def run(_):
        c=client_for(setup,3);barrier.wait()
        return c.post(f'/staff/bookings/{b.ma_pdp}/check-in',json={'ly_do':'Đồng thời'}).status_code
    with ThreadPoolExecutor(2) as pool:assert sorted(pool.map(run,range(2)))==[200,409]

def test_frontdesk_amend_cancel_and_price_guard(setup):
    staff=client_for(setup,3)
    body={'email_khach':'walkin@example.com','ten_lien_he':'Khách trực tiếp','sdt_lien_he':'0901234567','ma_phong':setup['room'],
        'ngay_nhan':str(today()),'ngay_tra':str(today()+timedelta(days=1)),'so_khach':1,'expected_don_gia_moi_dem':500000}
    result=staff.post('/staff/bookings',json=body)
    assert result.status_code==201
    key=result.json()['ma_pdp']
    amendment={k:v for k,v in body.items() if k in ('ma_phong','ngay_nhan','ngay_tra','so_khach','expected_don_gia_moi_dem')}|{'ly_do':'Gia hạn','ngay_tra':str(today()+timedelta(days=3))}
    assert staff.patch(f'/staff/bookings/{key}/amend',json=amendment|{'expected_don_gia_moi_dem':1}).status_code==409
    changed=staff.patch(f'/staff/bookings/{key}/amend',json=amendment)
    assert changed.status_code==200 and changed.json()['tong_tien']==1500000
    assert staff.patch(f'/staff/bookings/{key}/cancel',json={'ly_do':'Khách đổi kế hoạch'}).status_code==200

def test_catalog_seed_idempotent_preserves_bookings_and_accounts(setup):
    from app.seed_operations import seed
    from app.models import Account,RoomType,RoomImage
    b=make(setup)
    with Session(setup['engine']) as db:
        before=[(a.id,a.mat_khau_bam) for a in db.scalars(select(Account).order_by(Account.id))]
        seed(db,True)
        counts=(len(db.scalars(select(Room)).all()),len(db.scalars(select(RoomImage)).all()))
        seed(db,True)
        assert counts==(len(db.scalars(select(Room)).all()),len(db.scalars(select(RoomImage)).all()))
        assert len(db.scalars(select(RoomType)).all())==11
        assert before==[(a.id,a.mat_khau_bam) for a in db.scalars(select(Account).order_by(Account.id))]
        assert db.get(Booking,b.ma_pdp).tong_tien==1000000

def test_overdue_physical_stay_not_recommended(setup):
    b=make(setup)
    with Session(setup['engine']) as db:
        row=db.get(Booking,b.ma_pdp);row.trang_thai='DANG_O';row.ngay_nhan=today()-timedelta(days=3);row.ngay_tra=today()-timedelta(days=1);db.commit()
    c=client_for(setup)
    assert c.get('/rooms/recommended',params={'ngay_nhan':str(today()),'ngay_tra':str(today()+timedelta(days=1)),'so_khach':1}).json()['total']==0

def test_device_owner_binding_and_logout_removal(setup):
    from app.models import DeviceToken
    first=client_for(setup);second=client_for(setup,1);body={'token':'test-device-registration-no-real-token'}
    assert first.post('/devices',json=body).status_code==200
    assert second.post('/devices',json=body).status_code==200
    assert first.request('DELETE','/devices',json=body).status_code==200
    with Session(setup['engine']) as db:assert db.scalar(select(DeviceToken)).tai_khoan_id==setup['ids'][1]
    assert second.request('DELETE','/devices',json=body).status_code==200

def test_expired_hold_cannot_be_confirmed_before_worker(setup):
    b=make(setup)
    with Session(setup['engine']) as db:
        db.get(Booking,b.ma_pdp).giu_cho_den=instant(today()-timedelta(days=1),0);db.commit()
    response=client_for(setup,3).patch(f'/staff/bookings/{b.ma_pdp}/confirm')
    assert response.status_code==409 and response.json()['error']['code']=='HOLD_EXPIRED'
    assert client_for(setup).get(f'/bookings/{b.ma_pdp}').json()['trang_thai']=='HET_HAN'

def test_cancellation_fee_and_no_show_keep_financial_history(setup,monkeypatch):
    b=make(setup,offset=0);staff=client_for(setup,3);guest=client_for(setup)
    assert staff.patch(f'/staff/bookings/{b.ma_pdp}/confirm').status_code==200
    cancelled=guest.patch(f'/bookings/{b.ma_pdp}/cancel',json={'ly_do':'Đổi kế hoạch'})
    assert cancelled.status_code==200
    assert cancelled.json()['tong_thanh_toan']==500000 and cancelled.json()['tien_phong']==0
    another=make(setup,offset=1)
    assert staff.patch(f'/staff/bookings/{another.ma_pdp}/confirm').status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(today()+timedelta(days=2),10))
    missed=staff.post(f'/staff/bookings/{another.ma_pdp}/no-show',json={'ly_do':'Đã liên hệ khách không đến'})
    assert missed.status_code==200 and missed.json()['tong_thanh_toan']==500000

def test_physical_stay_blocks_operational_changes(setup,monkeypatch):
    b=make(setup,offset=0);staff=client_for(setup,3)
    assert staff.patch(f'/staff/bookings/{b.ma_pdp}/confirm').status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(today(),14))
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-in',json={'ly_do':'Nhận'}).status_code==200
    assert staff.patch(f'/staff/rooms/{b.ma_phong}/operational-status',json={'tinh_trang_van_hanh':'CAN_DON_DEP','ly_do':'Dọn'}).status_code==409

def test_manager_waiver_survives_checkout_invoice_refresh(setup,monkeypatch):
    b=make(setup,offset=0);staff=client_for(setup,3);admin=client_for(setup,2)
    assert staff.patch(f'/staff/bookings/{b.ma_pdp}/confirm').status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(today(),14))
    assert staff.post(f'/staff/bookings/{b.ma_pdp}/check-in',json={'ly_do':'Nhận'}).status_code==200
    monkeypatch.setattr('app.services.stays.now',lambda:instant(b.ngay_tra,16))
    invoice=staff.post(f'/bookings/{b.ma_pdp}/request-checkout').json()
    late=next(c for c in invoice['phu_thu'] if c['loai']=='TRA_MUON')
    assert admin.post(f'/admin/charges/{late["id"]}/void',json={'ly_do':'Khách chờ xử lý do lỗi khách sạn'}).status_code==200
    revised=staff.post(f'/bookings/{b.ma_pdp}/request-checkout').json()
    assert revised['tong_phu_thu']==0 and next(c for c in revised['phu_thu'] if c['id']==late['id'])['da_huy']

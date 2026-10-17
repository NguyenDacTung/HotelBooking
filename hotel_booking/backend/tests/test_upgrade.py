"""Upgrade invariants exercised on the dedicated PostgreSQL database."""
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta, datetime, timezone
from threading import Barrier
from uuid import uuid4
import pytest
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from test_postgres import setup, make, client_for, user
from app.models import Booking, Payment, Notification, Audit, RoomType, Closure
from app.services.rules import today

pytestmark = pytest.mark.postgres


def confirmed(env):
    booking = make(env)
    admin = client_for(env, 2)
    assert admin.patch(f'/staff/bookings/{booking.ma_pdp}/confirm').status_code == 200
    return booking, admin


def payment(amount=600000, **extra):
    return dict(request_id=str(uuid4()), so_tien=amount, phuong_thuc='TIEN_MAT', **extra)


def test_price_change_has_no_booking_or_notification_side_effect(setup):
    from test_postgres import payload
    client = client_for(setup)
    data = payload(setup).model_dump(mode='json') | {'expected_don_gia_moi_dem': 400000}
    response = client.post('/bookings', json=data)
    assert response.status_code == 409
    assert response.json()['error']['code'] == 'PRICE_CHANGED'
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(Booking)) == 0
        assert db.scalar(select(func.count()).select_from(Notification)) == 0


def test_payment_idempotency_refund_and_notification_ownership(setup):
    booking, admin = confirmed(setup)
    staff, customer, other = (client_for(setup, i) for i in (3, 0, 1))
    url = f'/staff/bookings/{booking.ma_pdp}/payments'
    body = payment(1000000)
    first = staff.post(url, json=body)
    assert first.status_code == 201, first.text
    assert staff.post(url, json=body).json()['id'] == first.json()['id']
    assert staff.post(url, json=body | {'so_tien': 1}).status_code == 409
    assert customer.post(url, json=payment(1)).status_code == 403
    assert staff.post(url, json=payment(1)).status_code == 409
    assert customer.patch(f'/bookings/{booking.ma_pdp}/cancel', json={}).status_code == 200
    assert customer.get(f'/bookings/{booking.ma_pdp}').json()['can_hoan_tien'] == 1000000
    refund_url = f'/admin/payments/{first.json()["id"]}/refunds'
    refund_body = payment(1000000, ghi_chu='Hoàn thực tế')
    assert staff.post(refund_url, json=refund_body).status_code == 403
    assert admin.post(refund_url, json=refund_body).status_code == 201
    assert admin.post(refund_url, json=refund_body).status_code == 201
    assert admin.post(refund_url, json=payment(1, ghi_chu='Vượt')).status_code == 409
    assert customer.get(f'/bookings/{booking.ma_pdp}').json()['can_hoan_tien'] == 0
    notice = customer.get('/notifications').json()['items'][0]
    assert other.patch(f'/notifications/{notice["id"]}/read').status_code == 404
    assert customer.patch(f'/notifications/{notice["id"]}/read').status_code == 200


def test_concurrent_collections_cannot_overpay(setup):
    booking, _ = confirmed(setup)
    barrier = Barrier(2)
    def collect(_):
        client = client_for(setup, 3)
        barrier.wait(timeout=10)
        return client.post(f'/staff/bookings/{booking.ma_pdp}/payments', json=payment()).status_code
    with ThreadPoolExecutor(2) as pool:
        assert sorted(pool.map(collect, range(2))) == [201, 409]
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.sum(Payment.so_tien))) == 600000


def test_concurrent_refunds_cannot_exceed_original(setup):
    booking, admin = confirmed(setup)
    original = admin.post(f'/staff/bookings/{booking.ma_pdp}/payments', json=payment(1000000)).json()
    barrier = Barrier(2)
    def refund(_):
        client = client_for(setup, 2)
        barrier.wait(timeout=10)
        return client.post(f'/admin/payments/{original["id"]}/refunds', json=payment(600000, ghi_chu='Hoàn thực tế')).status_code
    with ThreadPoolExecutor(2) as pool:
        assert sorted(pool.map(refund, range(2))) == [201, 409]


def test_two_admins_cannot_disable_each_other_concurrently(setup):
    admin = client_for(setup, 2)
    assert admin.patch(f'/admin/accounts/{setup["ids"][3]}/role', json={'ma_quyen':'QUAN_LY','ly_do':'Bổ nhiệm'}).status_code == 200
    clients = [client_for(setup, 2), client_for(setup, 3)]
    barrier = Barrier(2)
    def disable(index):
        barrier.wait(timeout=10)
        return clients[index].patch(f'/admin/accounts/{setup["ids"][3-index]}/status', json={'dang_hoat_dong':False,'ly_do':'Khóa thử'}).status_code
    with ThreadPoolExecutor(2) as pool:
        results = list(pool.map(disable, range(2)))
    assert sorted(results) == [200, 401]


def test_google_verification_checks_audience_and_verified_email(monkeypatch):
    from app.api import social
    from app.core.config import settings
    from google.oauth2 import id_token
    from app.core.errors import DomainError
    config = settings().model_copy(update={'google_client_id':'expected-client'})
    monkeypatch.setattr(social, 'settings', lambda: config)
    monkeypatch.setattr(id_token, 'verify_oauth2_token', lambda *args: {'sub':'verified','aud':'wrong-client'})
    with pytest.raises(DomainError) as error:
        social.verify('GOOGLE','invalid-token')
    assert error.value.status == 401
    monkeypatch.setattr(id_token, 'verify_oauth2_token', lambda *args: {'sub':'verified','aud':'expected-client','email':'not-verified@example.com','email_verified':False})
    assert social.verify('GOOGLE','controlled-token')['email'] is None


def test_accounts_token_revocation_audit_and_self_protection(setup):
    admin, staff = client_for(setup, 2), client_for(setup, 3)
    url = f'/admin/accounts/{setup["ids"][3]}/role'
    response = admin.patch(url, json={'ma_quyen':'QUAN_LY','ly_do':'Phân công'})
    assert response.status_code == 200, response.text
    assert staff.get('/users/me').status_code == 401
    assert admin.patch(f'/admin/accounts/{setup["ids"][2]}/status', json={'dang_hoat_dong':False,'ly_do':'Tự khóa'}).status_code == 400
    detail = admin.get(f'/admin/accounts/{setup["ids"][3]}').json()
    assert detail['lich_su'] and 'mat_khau_bam' not in detail
    assert admin.patch(f'/admin/accounts/{setup["ids"][0]}/role', json={'ma_quyen':'LE_TAN','ly_do':'Sai'}).status_code == 400


def test_operations_conflicts_and_cleaning_sequence(setup):
    booking = make(setup)
    client = client_for(setup, 3)
    url = f'/staff/rooms/{setup["room"]}/operational-status'
    assert client.patch(url, json={'tinh_trang_van_hanh':'BAO_TRI','ly_do':'Thiếu ngày'}).status_code == 422
    response = client.patch(url, json={'tinh_trang_van_hanh':'BAO_TRI','ly_do':'Trùng lịch','tu_ngay':str(booking.ngay_nhan),'den_ngay':str(booking.ngay_tra)})
    assert response.status_code == 409
    for state in ('CAN_DON_DEP','DANG_DON_DEP','SAN_SANG'):
        assert client.patch(url, json={'tinh_trang_van_hanh':state,'ly_do':'Dọn phòng'}).status_code == 200
    assert client.patch(url, json={'tinh_trang_van_hanh':'DANG_DON_DEP','ly_do':'Bỏ bước'}).status_code == 409


def test_report_receipts_csv_pdf_and_permissions(setup):
    booking, admin = confirmed(setup)
    assert admin.post(f'/staff/bookings/{booking.ma_pdp}/payments', json=payment(250000)).status_code == 201
    query = {'tu_ngay':str(today()-timedelta(days=1)), 'den_ngay':str(today()+timedelta(days=1))}
    report = admin.get('/admin/reports/revenue', params=query)
    assert report.status_code == 200, report.text
    data = report.json()
    assert data['kpi']['thu'] == 250000 and data['kpi']['gia_tri_dat'] == 1000000
    assert len(data['series']) == 3 and sum(r['thu'] for r in data['series']) == 250000
    assert client_for(setup, 3).get('/admin/reports/revenue', params=query).status_code == 403
    csv = admin.get('/admin/reports/revenue/export', params=query | {'format':'csv'})
    assert csv.status_code == 200 and csv.content.startswith(b'\xef\xbb\xbf') and b'250000' in csv.content
    pdf = admin.get('/admin/reports/revenue/export', params=query | {'format':'pdf'})
    assert pdf.status_code == 200 and pdf.content.startswith(b'%PDF')
    one = admin.get('/admin/reports/revenue/export', params={'tu_ngay':str(today()),'den_ngay':str(today()),'format':'pdf'})
    assert one.status_code == 200


def test_report_uses_vietnam_midnight_half_open_bounds(setup):
    booking, admin = confirmed(setup)
    result = admin.post(f'/staff/bookings/{booking.ma_pdp}/payments', json=payment(250000)).json()
    from uuid import UUID
    query = {'tu_ngay':'2026-01-02','den_ngay':'2026-01-02'}
    for instant, expected in [('2026-01-01T16:59:59.999999+00:00',0),
                              ('2026-01-01T17:00:00+00:00',250000),
                              ('2026-01-02T16:59:59.999999+00:00',250000),
                              ('2026-01-02T17:00:00+00:00',0)]:
        with Session(setup['engine']) as db:
            db.get(Payment, UUID(result['id'])).thoi_diem_giao_dich = datetime.fromisoformat(instant)
            db.commit()
        response = admin.get('/admin/reports/revenue', params=query)
        assert response.status_code == 200
        assert response.json()['kpi']['thu'] == expected


def test_ending_maintenance_preserves_unrelated_closure(setup):
    with Session(setup['engine'], expire_on_commit=False) as db:
        unrelated = Closure(ma_phong=setup['room'],tu_ngay=today()+timedelta(days=50),den_ngay=today()+timedelta(days=52),ly_do='Lịch khác',nguoi_tao=setup['ids'][2])
        db.add(unrelated); db.commit(); unrelated_id = unrelated.ma_ngung
    client = client_for(setup, 3)
    url = f'/staff/rooms/{setup["room"]}/operational-status'
    response = client.patch(url, json={'tinh_trang_van_hanh':'BAO_TRI','ly_do':'Sửa phòng','tu_ngay':str(today()+timedelta(days=30)),'den_ngay':str(today()+timedelta(days=32))})
    assert response.status_code == 200, response.text
    assert client.patch(url, json={'tinh_trang_van_hanh':'SAN_SANG','ly_do':'Hoàn tất'}).status_code == 200
    with Session(setup['engine']) as db:
        assert db.get(Closure, unrelated_id).dang_hieu_luc is True
        assert db.scalar(select(func.count()).select_from(Closure).where(Closure.dang_hieu_luc.is_(True))) == 1


def test_social_no_automatic_email_link_and_customer_only(setup, monkeypatch):
    from app.api import social
    from app.main import app
    from fastapi.testclient import TestClient
    monkeypatch.setattr(social, 'verify', lambda *_: {'subject':'verified-subject','email':'user0@example.com','name':'A'})
    client = TestClient(app)
    assert client.post('/auth/google', json={'credential':'mock-controlled'}).status_code == 409
    monkeypatch.setattr(social, 'verify', lambda *_: {'subject':'new-subject','email':None,'name':'Khách xã hội'})
    response = client.post('/auth/google', json={'credential':'mock-controlled'})
    assert response.status_code == 200, response.text
    client.headers['Authorization'] = 'Bearer '+response.json()['access_token']
    assert client.get('/users/me').json()['ma_quyen'] == 'KHACH_HANG'

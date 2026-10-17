"""HTTP contract flow against the isolated real PostgreSQL test database."""
import pytest
from fastapi.testclient import TestClient
from test_postgres import setup, payload

pytestmark = pytest.mark.postgres


def test_login_search_quote_book_staff_confirm_customer_refresh(setup):
    from app.main import app
    with TestClient(app) as customer, TestClient(app) as staff:
        assert customer.get('/health/db').status_code == 200
        for client, email in [(customer, 'user0@example.com'), (staff, 'user2@example.com')]:
            response = client.post('/auth/login', json={'email': email, 'mat_khau': 'test-password'})
            assert response.status_code == 200
            client.headers['Authorization'] = 'Bearer ' + response.json()['access_token']
        data = payload(setup).model_dump(mode='json')
        stay = {key: data[key] for key in ('ngay_nhan', 'ngay_tra', 'so_khach')}
        available = customer.get('/rooms/available', params=stay)
        assert available.status_code == 200 and available.json()['total'] == 1
        quote = customer.post(f'/rooms/{setup["room"]}/quote', json=stay)
        assert quote.status_code == 200 and quote.json()['kha_dung'] is True
        created = customer.post('/bookings', json=data)
        assert created.status_code == 201
        booking = created.json()
        assert booking['trang_thai'] == 'CHO_XAC_NHAN'
        assert booking['tong_tien'] == quote.json()['tong_tien']
        key = booking['ma_pdp']
        assert customer.get('/rooms/available', params=stay).json()['total'] == 0
        confirmed = staff.patch(f'/staff/bookings/{key}/confirm')
        assert confirmed.status_code == 200
        refreshed = customer.get(f'/bookings/{key}').json()
        assert refreshed['trang_thai'] == 'DA_XAC_NHAN' and len(refreshed['lich_su']) == 2
        mine = customer.get('/bookings/my').json()
        assert mine['items'][0]['ma_pdp'] == key
        cancelled = customer.patch(f'/bookings/{key}/cancel', json={'ly_do': 'Test cleanup'})
        assert cancelled.status_code == 200 and cancelled.json()['trang_thai'] == 'DA_HUY'
        assert customer.get('/rooms/available', params=stay).json()['total'] == 1

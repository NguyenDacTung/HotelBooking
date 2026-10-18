"""An expected checkout date never substitutes for actual handover."""
from datetime import timedelta
import pytest
from sqlalchemy.orm import Session
from app.models import Booking
from app.services.rules import today
from test_postgres import setup, client_for, make, payload

pytestmark = pytest.mark.postgres


@pytest.mark.parametrize('state', ['DANG_O', 'CHO_THANH_TOAN'])
@pytest.mark.parametrize('departure_offset', [0, -1])
def test_unreturned_stay_blocks_search_quote_create_amend_and_confirmation(setup, state, departure_offset):
    previous = make(setup, offset=0)
    pending = make(setup, offset=5)
    with Session(setup['engine']) as db:
        old = db.get(Booking, previous.ma_pdp)
        old.ngay_nhan = today() - timedelta(days=3)
        old.ngay_tra = today() + timedelta(days=departure_offset)
        old.tong_tien = int(old.don_gia_moi_dem) * (old.ngay_tra - old.ngay_nhan).days
        old.trang_thai = state
        db.commit()
    customer = client_for(setup)
    staff = client_for(setup, 3)
    room = setup['room']
    new = payload(setup, offset=10).model_dump(mode='json')
    stay = {k: new[k] for k in ('ngay_nhan', 'ngay_tra', 'so_khach')}
    for offset in (0, 10):
        query = stay | {'ngay_nhan': str(today()+timedelta(days=offset)),
                        'ngay_tra': str(today()+timedelta(days=offset+1))}
        assert customer.get('/rooms/available', params=query).json()['total'] == 0
        assert customer.get('/rooms/recommended', params=query).json()['total'] == 0
    assert customer.get(f'/rooms/{room}').json()['trang_thai_su_dung'] == 'DANG_SU_DUNG'
    assert customer.post(f'/rooms/{room}/quote', json=stay).json()['kha_dung'] is False
    assert customer.post('/bookings', json=new).status_code == 409
    assert staff.post('/staff/bookings', json=new | {'email_khach': 'user1@example.com'}).status_code == 409
    confirm = staff.patch(f'/staff/bookings/{pending.ma_pdp}/confirm')
    assert confirm.status_code == 409 and confirm.json()['error']['code'] == 'ROOM_OCCUPIED'
    amend = stay | {'ma_phong': room}
    assert staff.patch(f'/staff/bookings/{pending.ma_pdp}/amend', json=amend).status_code == 409
    with Session(setup['engine']) as db:
        assert db.get(Booking, pending.ma_pdp).trang_thai == 'CHO_XAC_NHAN'
        assert db.get(Booking, previous.ma_pdp).trang_thai == state

    # Release only through the real invoice/payment/physical-checkout lifecycle.
    invoice = customer.post(f'/bookings/{previous.ma_pdp}/request-checkout')
    assert invoice.status_code == 200
    from uuid import uuid4
    payment = {'request_id': str(uuid4()), 'so_tien': invoice.json()['con_phai_thu'], 'phuong_thuc': 'TIEN_MAT'}
    assert staff.post(f'/staff/bookings/{previous.ma_pdp}/payments', json=payment).status_code == 201
    assert staff.post(f'/staff/bookings/{previous.ma_pdp}/check-out', json={}).status_code == 200
    assert customer.get('/rooms/available', params=stay).json()['total'] == 1
    assert customer.post(f'/rooms/{room}/quote', json=stay).json()['kha_dung'] is True
    assert staff.patch(f'/staff/bookings/{pending.ma_pdp}/confirm').status_code == 200

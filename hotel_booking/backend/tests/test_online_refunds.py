from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from uuid import uuid4

import pytest
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from test_postgres import setup, make, client_for
from app.models import PaymentAttempt, Payment, SandboxRefund, Booking
from app.services import gateways
from app.services.payments import balance
from app.services.stays import now
from app.services.reports import revenue
from app.services.rules import today

pytestmark = pytest.mark.postgres


def paid(env, monkeypatch, provider='MOMO', environment='sandbox'):
    from app.core.config import settings
    c = settings()
    for field, value in {'payment_environment': 'sandbox', 'payment_public_base_url': 'https://merchant.example.org',
                         'momo_partner_code': 'TEST', 'momo_access_key': 'fixture', 'momo_secret_key': 'fixture',
                         'vnpay_tmn_code': 'TEST', 'vnpay_hash_secret': 'fixture'}.items():
        monkeypatch.setattr(c, field, value)
    booking = make(env)
    client_for(env, 2).patch(f'/staff/bookings/{booking.ma_pdp}/confirm')
    with Session(env['engine'], expire_on_commit=False) as db:
        attempt = PaymentAttempt(ma_pdp=booking.ma_pdp, provider=provider, environment=environment,
            request_id=uuid4(), reference=uuid4().hex, amount=booking.tong_tien, state='SUCCEEDED',
            provider_transaction='12345', expires_at=now()+timedelta(minutes=15))
        db.add(attempt)
        db.flush()
        db.add(Payment(ma_pdp=booking.ma_pdp, loai='THU', so_tien=attempt.amount, phuong_thuc=provider,
                       environment=environment, nguoi_ghi_nhan=env['ids'][0], request_id=attempt.request_id))
        db.commit()
        return attempt


def test_refund_permissions_sandbox_only_and_idempotent_ledger(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    url = f'/admin/online-payments/{a.id}/refunds'
    body = {'request_id': str(uuid4())}
    assert client_for(setup).post(url, json=body).status_code == 403
    assert client_for(setup, 3).post(url, json=body).status_code == 403
    assert client_for(setup, 1).get(f'/bookings/{a.ma_pdp}/online-refunds').status_code == 404
    calls = []
    def transport(*args, **kwargs):
        calls.append(1)
        # The request was committed before I/O, without a held transaction lock.
        with Session(setup['engine']) as db:
            assert db.scalar(select(func.count()).select_from(SandboxRefund)) == 1
        return 'SUCCEEDED', 'refund-123'
    monkeypatch.setattr(gateways, 'refund_transport', transport)
    admin = client_for(setup, 2)
    r = admin.post(url, json=body)
    assert r.status_code == 200, r.text
    assert r.json()['state'] == 'SUCCEEDED'
    assert admin.post(url, json=body).json()['id'] == r.json()['id']
    assert admin.post(f"/admin/online-refunds/{r.json()['id']}/query").status_code == 200
    assert len(calls) == 1
    assert admin.post(url, json={'request_id': str(uuid4())}).status_code == 409
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(Payment).where(Payment.loai == 'HOAN')) == 1
        assert balance(db, db.get(Booking, a.ma_pdp))['da_hoan'] == 0
        assert revenue(db, today(), today())['kpi']['thu'] == 0


def test_refund_timeout_stays_reserved_query_reconciles(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    monkeypatch.setattr(gateways, 'refund_transport', lambda *a, **k: (_ for _ in ()).throw(TimeoutError()))
    admin = client_for(setup, 2)
    url = f'/admin/online-payments/{a.id}/refunds'
    body = {'request_id': str(uuid4())}
    assert admin.post(url, json=body).status_code == 503
    replay = admin.post(url, json=body)
    assert replay.json()['state'] == 'CREATED'
    assert admin.post(url, json={'request_id': str(uuid4())}).status_code == 409
    monkeypatch.setattr(gateways, 'refund_transport', lambda *a, **k: ('SUCCEEDED', 'query-refund'))
    assert admin.post(f"/admin/online-refunds/{replay.json()['id']}/query").json()['state'] == 'SUCCEEDED'


def test_production_and_unconfigured_never_create_refund(setup, monkeypatch):
    a = paid(setup, monkeypatch, environment='production')
    admin = client_for(setup, 2)
    assert admin.post(f'/admin/online-payments/{a.id}/refunds', json={'request_id': str(uuid4())}).status_code == 503
    from app.core.config import settings
    monkeypatch.setattr(settings(), 'momo_secret_key', '')
    with Session(setup['engine']) as db:
        db.get(PaymentAttempt, a.id).environment = 'sandbox'
        db.commit()
    assert admin.post(f'/admin/online-payments/{a.id}/refunds', json={'request_id': str(uuid4())}).status_code == 503
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(SandboxRefund)) == 0


def test_concurrent_refunds_only_one_provider_call(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    calls = []
    def transport(*args, **kwargs):
        calls.append(1)
        return 'PENDING', ''
    monkeypatch.setattr(gateways, 'refund_transport', transport)
    def send(_):
        return client_for(setup, 2).post(f'/admin/online-payments/{a.id}/refunds', json={'request_id': str(uuid4())}).status_code
    with ThreadPoolExecutor(2) as pool:
        statuses = list(pool.map(send, range(2)))
    assert sorted(statuses) == [200, 409]
    assert len(calls) == 1


@pytest.mark.parametrize('provider', ['MOMO', 'VNPAY'])
def test_transport_validates_signatures_and_distinguishes_original_payment(setup, monkeypatch, provider):
    a = paid(setup, monkeypatch, provider=provider)
    refund = SandboxRefund(id=uuid4(), attempt_id=a.id, request_id=uuid4(), reference='RFtest', amount=a.amount,
                           created_by=setup['ids'][2], ngay_tao=now())
    tamper = []
    def post(self, url, json):
        if provider == 'MOMO':
            assert '/refund' in url
            assert json['signature'] == gateways.momo_sign(json, ('accessKey','amount','description','orderId','partnerCode','requestId','transId'))
            result = {'partnerCode': 'TEST', 'requestId': json['requestId'], 'orderId': 'RFtest',
                      'amount': int(a.amount), 'resultCode': 0, 'transId': 98765}
        else:
            assert json['vnp_Command'] in ('refund', 'querydr')
            assert json.get('vnp_TransactionType', '02') == '02'
            result = {'vnp_ResponseId': 'reply', 'vnp_Command': json['vnp_Command'], 'vnp_ResponseCode': '00',
                      'vnp_TmnCode': 'TEST', 'vnp_TxnRef': a.reference, 'vnp_Amount': int(a.amount)*100,
                      'vnp_TransactionType': '01' if json['vnp_Command'] == 'querydr' else '02',
                      'vnp_TransactionStatus': '00', 'vnp_TransactionNo': '98765'}
            keys = ('vnp_ResponseId','vnp_Command','vnp_ResponseCode','vnp_Message','vnp_TmnCode','vnp_TxnRef','vnp_Amount','vnp_BankCode','vnp_PayDate','vnp_TransactionNo','vnp_TransactionType','vnp_TransactionStatus','vnp_OrderInfo')
            if json['vnp_Command'] == 'querydr': keys += ('vnp_PromotionCode','vnp_PromotionAmount')
            result['vnp_SecureHash'] = gateways.digest('fixture', '|'.join(str(result.get(k,'')) for k in keys), 'sha512')
        if tamper:
            result['amount' if provider == 'MOMO' else 'vnp_Amount'] = 1
        class Response:
            def raise_for_status(self): pass
            def json(self): return result
        return Response()
    import httpx
    monkeypatch.setattr(httpx.Client, 'post', post)
    assert gateways.refund_transport(refund, a, '127.0.0.1') == ('SUCCEEDED', '98765')
    if provider == 'VNPAY':
        assert gateways.refund_transport(refund, a, '127.0.0.1', query_only=True) == ('PENDING', '')
    tamper.append(True)
    with pytest.raises(ValueError):
        gateways.refund_transport(refund, a, '127.0.0.1')


def test_missing_refund_reference_keeps_request_unsettled(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    monkeypatch.setattr(gateways, 'refund_transport', lambda *a, **k: ('SUCCEEDED', '0'))
    response = client_for(setup, 2).post(f'/admin/online-payments/{a.id}/refunds', json={'request_id': str(uuid4())})
    assert response.status_code == 503
    with Session(setup['engine']) as db:
        assert db.scalar(select(SandboxRefund)).state == 'CREATED'
        assert db.scalar(select(func.count()).select_from(Payment).where(Payment.loai == 'HOAN')) == 0


def test_momo_refund_query_matches_refund_reference_and_amount(setup, monkeypatch):
    import httpx
    a = paid(setup, monkeypatch)
    refund = SandboxRefund(request_id=uuid4(), reference='RFquery', amount=a.amount)
    wrong = []
    def post(self, url, json):
        assert url.endswith('/refund/query')
        result = {'partnerCode': 'TEST', 'requestId': json['requestId'], 'resultCode': 0,
                  'refundTrans': [{'orderId': 'other' if wrong else 'RFquery',
                                   'amount': int(a.amount), 'resultCode': 0, 'transId': 98765}]}
        class Response:
            def raise_for_status(self): pass
            def json(self): return result
        return Response()
    monkeypatch.setattr(httpx.Client, 'post', post)
    assert gateways.refund_transport(refund, a, '127.0.0.1', query_only=True) == ('SUCCEEDED', '98765')
    wrong.append(True)
    assert gateways.refund_transport(refund, a, '127.0.0.1', query_only=True) == ('PENDING', '')


def test_refund_request_id_cannot_collide_with_collection_or_manual_payment(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    admin = client_for(setup, 2)
    url = f'/admin/online-payments/{a.id}/refunds'
    assert admin.post(url, json={'request_id': str(a.request_id)}).status_code == 409
    request_id = uuid4()
    monkeypatch.setattr(gateways, 'refund_transport', lambda *a, **k: ('PENDING', ''))
    assert admin.post(url, json={'request_id': str(request_id)}).status_code == 200
    manual = admin.post(f'/staff/bookings/{a.ma_pdp}/payments', json={
        'request_id': str(request_id), 'so_tien': 1, 'phuong_thuc': 'TIEN_MAT'})
    assert manual.status_code == 409 and manual.json()['error']['code'] == 'REQUEST_CONFLICT'
    online = client_for(setup).post(f'/bookings/{a.ma_pdp}/online-payments', json={
        'request_id': str(request_id), 'provider': 'MOMO'})
    assert online.status_code == 409 and online.json()['error']['code'] == 'REQUEST_CONFLICT'


def test_late_pending_response_cannot_overwrite_terminal_refund(setup, monkeypatch):
    a = paid(setup, monkeypatch)
    def transport(refund, *args, **kwargs):
        # Another in-flight reconciler has already committed a final result.
        with Session(setup['engine']) as db:
            db.get(SandboxRefund, refund.id).state = 'FAILED'
            db.commit()
        return 'PENDING', ''
    monkeypatch.setattr(gateways, 'refund_transport', transport)
    response = client_for(setup, 2).post(f'/admin/online-payments/{a.id}/refunds', json={'request_id': str(uuid4())})
    assert response.status_code == 200 and response.json()['state'] == 'FAILED'

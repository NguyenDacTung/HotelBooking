import base64
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from threading import Barrier
from uuid import uuid4

import pytest
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.main import app
from app.models import Account, BiometricChallenge, BiometricDevice
from app.services.stays import now
from test_postgres import setup, client_for

pytestmark = pytest.mark.postgres

def enrollment(env, index=0, activate=True):
    private = ec.generate_private_key(ec.SECP256R1())
    public = base64.b64encode(private.public_key().public_bytes(serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo)).decode()
    owner = client_for(env, index)
    device = str(uuid4())
    r = owner.post('/users/me/biometric', json={'device_id': device, 'public_key': public, 'mat_khau': 'test-password'})
    assert r.status_code == 201
    challenge = r.json()
    if activate:
        assert owner.post('/users/me/biometric/confirm', json=proof(private, challenge)).status_code == 200
    return owner, device, private, challenge

def proof(private, challenge):
    return {'challenge_id': challenge['challenge_id'], 'signature': base64.b64encode(
        private.sign(challenge['message'].encode(), ec.ECDSA(hashes.SHA256()))).decode()}

def begin(device):
    r = TestClient(app).post('/auth/biometric/challenge', json={'device_id': device})
    assert r.status_code == 200
    return r.json()

def test_biometric_real_signature_new_token_without_email_password(setup):
    _, device, private, _ = enrollment(setup)
    c = TestClient(app)
    r = c.post('/auth/biometric/login', json=proof(private, begin(device)))
    assert r.status_code == 200 and r.json()['expires_in'] > 0
    me = c.get('/users/me', headers={'Authorization': 'Bearer '+r.json()['access_token']})
    assert me.status_code == 200 and me.json()['id'] == str(setup['ids'][0])

def test_biometric_enroll_requires_session_owner_and_signed_proof(setup):
    assert TestClient(app).post('/users/me/biometric', json={}).status_code == 401
    owner, device, private, ch = enrollment(setup, activate=False)
    public = base64.b64encode(private.public_key().public_bytes(serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo)).decode()
    assert owner.post('/users/me/biometric', json={'device_id': str(uuid4()), 'public_key': public, 'mat_khau': 'wrong'}).status_code == 400
    assert TestClient(app).post('/auth/biometric/challenge', json={'device_id': device}).status_code == 401
    assert client_for(setup, 1).post('/users/me/biometric/confirm', json=proof(private, ch)).status_code == 401
    assert owner.post('/users/me/biometric/confirm', json=proof(private, ch)).status_code == 200
    # Enrollment signatures cannot be used as login signatures or confirmed twice.
    assert TestClient(app).post('/auth/biometric/login', json=proof(private, ch)).status_code == 401
    assert owner.post('/users/me/biometric/confirm', json=proof(private, ch)).status_code == 401

def test_biometric_wrong_key_consumed_expired_replay(setup):
    _, device, private, _ = enrollment(setup)
    c = TestClient(app); ch = begin(device)
    wrong = ec.generate_private_key(ec.SECP256R1())
    assert c.post('/auth/biometric/login', json=proof(wrong, ch)).status_code == 401
    assert c.post('/auth/biometric/login', json=proof(private, ch)).status_code == 401
    ch = begin(device)
    with Session(setup['engine']) as db:
        db.get(BiometricChallenge, __import__('uuid').UUID(ch['challenge_id'])).het_han = now()-timedelta(seconds=1); db.commit()
    assert c.post('/auth/biometric/login', json=proof(private, ch)).status_code == 401

@pytest.mark.parametrize('change', ['password_version', 'locked', 'expired', 'revoked'])
def test_biometric_respects_current_account_and_credential(setup, change):
    owner, device, private, _ = enrollment(setup); ch = begin(device)
    with Session(setup['engine']) as db:
        account = db.get(Account, setup['ids'][0]); row = db.get(BiometricDevice, __import__('uuid').UUID(device))
        if change == 'password_version': account.token_version += 1
        if change == 'locked': account.dang_hoat_dong = False
        if change == 'expired': row.het_han = now()-timedelta(seconds=1)
        if change == 'revoked': row.revoked = True
        db.commit()
    assert TestClient(app).post('/auth/biometric/login', json=proof(private, ch)).status_code == 401
    assert TestClient(app).post('/auth/biometric/challenge', json={'device_id': device}).status_code == 401

def test_biometric_revoke_owned_and_no_fake_boolean(setup):
    owner, device, _, _ = enrollment(setup)
    assert client_for(setup,1).delete('/users/me/biometric/'+device).status_code == 404
    assert TestClient(app).post('/auth/biometric/login', json={'authenticated': True}).status_code == 422
    assert owner.delete('/users/me/biometric/'+device).status_code == 200
    assert TestClient(app).post('/auth/biometric/challenge', json={'device_id': device}).status_code == 401

def test_biometric_one_challenge_concurrent_only_one_login(setup):
    _, device, private, _ = enrollment(setup); data = proof(private, begin(device)); gate = Barrier(2)
    def send(_):
        gate.wait(timeout=10)
        return TestClient(app).post('/auth/biometric/login', json=data).status_code
    with ThreadPoolExecutor(2) as pool:
        assert sorted(pool.map(send,range(2))) == [200,401]

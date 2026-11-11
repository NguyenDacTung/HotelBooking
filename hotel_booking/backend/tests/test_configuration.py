import json
from types import SimpleNamespace

import pytest

from app.core.config import Settings
from app.services.configuration import audit, load_client


def config(**updates):
    values = Settings(_env_file=None, database_url='postgresql+psycopg://unused@localhost/test',
                      jwt_secret='unit-test-configuration-only-' * 2).model_dump()
    # Do not inherit developer integration credentials from process variables.
    for key in ('google_client_id', 'facebook_app_id', 'facebook_app_secret', 'smtp_host',
                'smtp_from', 'smtp_user', 'smtp_password', 'firebase_project_id',
                'firebase_credentials', 'payment_public_base_url', 'momo_partner_code',
                'momo_access_key', 'momo_secret_key', 'vnpay_tmn_code', 'vnpay_hash_secret'):
        values[key] = ''
    values.update(updates)
    return SimpleNamespace(**values)


def test_missing_services_are_disabled_and_report_contains_no_values():
    report = audit(config(facebook_app_secret='a-secret-that-must-not-leak'), {})
    assert not any(report[name]['ready'] for name in ('google', 'facebook', 'recovery', 'push', 'momo', 'vnpay', 'online_refund'))
    assert 'a-secret-that-must-not-leak' not in json.dumps(report)
    assert report['google']['missing'] == ['GOOGLE_CLIENT_ID', 'GOOGLE_SERVER_CLIENT_ID']


def test_google_and_facebook_require_matching_client_and_server():
    c = config(google_client_id='server-google', facebook_app_id='server-facebook', facebook_app_secret='private')
    client = {'GOOGLE_SERVER_CLIENT_ID': 'other', 'FACEBOOK_ENABLED': True,
              'TTTP_FACEBOOK_APP_ID': 'other', 'TTTP_FACEBOOK_CLIENT_TOKEN': 'public'}
    report = audit(c, client)
    assert report['google']['issues'] == ['GOOGLE_CLIENT_ID_MISMATCH']
    assert report['facebook']['issues'] == ['FACEBOOK_APP_ID_MISMATCH']
    client.update(GOOGLE_SERVER_CLIENT_ID='server-google', TTTP_FACEBOOK_APP_ID='server-facebook')
    assert audit(c, client)['google']['ready'] and audit(c, client)['facebook']['ready']


def test_push_rejects_missing_or_wrong_service_account(tmp_path):
    path = tmp_path / 'account.json'
    c = config(firebase_project_id='project-a', firebase_credentials=str(path))
    client = dict.fromkeys(['FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID'], 'public')
    client['FIREBASE_PROJECT_ID'] = 'project-a'
    assert audit(c, client)['push']['issues'] == ['FIREBASE_SERVICE_ACCOUNT_UNREADABLE']
    path.write_text(json.dumps({'type': 'service_account', 'private_key': 'not-printed',
                               'client_email': 'not-printed', 'project_id': 'project-b'}))
    assert audit(c, client)['push']['issues'] == ['FIREBASE_SERVICE_ACCOUNT_INVALID']
    client['FIREBASE_PROJECT_ID'] = 'project-b'
    assert 'FIREBASE_PROJECT_MISMATCH' in audit(c, client)['push']['issues']


@pytest.mark.parametrize('url', ['http://public.example.org', 'https://localhost', 'https://192.168.1.10', 'https://[::1]', 'https://user:pass@public.example.org', 'https://public.example.org?secret=no'])
def test_payment_callback_requires_public_https(url):
    report = audit(config(payment_public_base_url=url), {})
    assert 'PAYMENT_CALLBACK_NOT_PUBLIC_HTTPS' in report['momo']['issues']
    assert not report['vnpay']['ready']


def test_smtp_partial_auth_and_wrong_payment_environment_are_reported():
    report = audit(config(smtp_host='smtp', smtp_from='sender', smtp_user='user', payment_environment='production'), {})
    assert report['recovery']['issues'] == ['SMTP_AUTH_INCOMPLETE']
    assert 'PAYMENT_ENDPOINT_MISMATCH' in report['momo']['issues']


@pytest.mark.parametrize('payload', [{'MOMO_SECRET_KEY': 'never-embed'}, {'FACEBOOK_ENABLED': 'false'}, {'FIREBASE_API_KEY': 123}, ['wrong-type']])
def test_client_file_rejects_backend_secrets_and_wrong_types(tmp_path, payload):
    path = tmp_path / 'client.json'
    path.write_text(json.dumps(payload))
    with pytest.raises(ValueError) as exc:
        load_client(path)
    assert 'never-embed' not in str(exc.value)


def test_client_file_accepts_public_settings_and_windows_bom(tmp_path):
    path = tmp_path / 'client.json'
    path.write_text(json.dumps({'GOOGLE_SERVER_CLIENT_ID': '', 'FACEBOOK_ENABLED': False}), encoding='utf-8-sig')
    assert load_client(path)['FACEBOOK_ENABLED'] is False


@pytest.mark.parametrize('url', ['', 'http://127.0.0.1:8000', 'http://10.0.2.2:8000', 'https://api.example.org'])
def test_client_api_url_accepts_auto_usb_emulator_and_hosted(tmp_path, url):
    path = tmp_path / 'client.json'
    path.write_text(json.dumps({'API_BASE_URL': url}))
    assert load_client(path)['API_BASE_URL'] == url


@pytest.mark.parametrize('url', ['file:///local', 'http://user:private@host', 'https://host?key=private', 'https://host/#private', 'http://host:invalid'])
def test_client_api_url_rejects_invalid_or_embedded_credentials(tmp_path, url):
    path = tmp_path / 'client.json'
    path.write_text(json.dumps({'API_BASE_URL': url}))
    with pytest.raises(ValueError, match='CLIENT_API_URL_INVALID'):
        load_client(path)

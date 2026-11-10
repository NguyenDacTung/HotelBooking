"""Read-only integration audit. Reports field names and codes, never values."""
import ipaddress
import json
from pathlib import Path
from urllib.parse import urlparse

CLIENT_KEYS = frozenset({
    'API_BASE_URL',
    'GOOGLE_SERVER_CLIENT_ID', 'FACEBOOK_ENABLED',
    'TTTP_FACEBOOK_APP_ID', 'TTTP_FACEBOOK_CLIENT_TOKEN',
    'FIREBASE_API_KEY', 'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID',
})


def load_client(path):
    """Reject accidental backend secrets before passing JSON to Flutter."""
    data = json.loads(Path(path).read_text(encoding='utf-8-sig'))
    if not isinstance(data, dict) or set(data) - CLIENT_KEYS:
        raise ValueError('CLIENT_KEYS_NOT_ALLOWED')
    for key, value in data.items():
        if key == 'FACEBOOK_ENABLED':
            if not isinstance(value, bool):
                raise ValueError('CLIENT_BOOLEAN_REQUIRED')
        elif not isinstance(value, str) or value != value.strip():
            raise ValueError('CLIENT_STRING_REQUIRED')
    if data.get('API_BASE_URL'):
        try:
            url = urlparse(data['API_BASE_URL'])
            valid = (url.scheme in ('http', 'https') and url.hostname and not url.username
                     and not url.password and not url.query and not url.fragment)
            _ = url.port
        except ValueError:
            valid = False
        if not valid:
            raise ValueError('CLIENT_API_URL_INVALID')
    return data


def audit(config, client):
    result = {}

    def group(name, fields, client_fields=()):
        missing = [key.upper() for key in fields if not getattr(config, key)]
        missing += [key for key in client_fields if not client.get(key)]
        row = {'ready': not missing, 'missing': list(dict.fromkeys(missing)), 'issues': []}
        result[name] = row
        return row

    def issue(row, code):
        row['issues'].append(code)
        row['ready'] = False

    google = group('google', ['google_client_id'], ['GOOGLE_SERVER_CLIENT_ID'])
    if google['ready'] and config.google_client_id != client['GOOGLE_SERVER_CLIENT_ID']:
        issue(google, 'GOOGLE_CLIENT_ID_MISMATCH')

    facebook = group('facebook', ['facebook_app_id', 'facebook_app_secret'],
                     ['FACEBOOK_ENABLED', 'TTTP_FACEBOOK_APP_ID', 'TTTP_FACEBOOK_CLIENT_TOKEN'])
    if facebook['ready'] and config.facebook_app_id != client['TTTP_FACEBOOK_APP_ID']:
        issue(facebook, 'FACEBOOK_APP_ID_MISMATCH')

    smtp = group('recovery', ['smtp_host', 'smtp_from'])
    if bool(config.smtp_user) != bool(config.smtp_password):
        issue(smtp, 'SMTP_AUTH_INCOMPLETE')

    push = group('push', ['firebase_project_id', 'firebase_credentials'],
                 ['FIREBASE_API_KEY', 'FIREBASE_APP_ID',
                  'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID'])
    if config.firebase_project_id and client.get('FIREBASE_PROJECT_ID') and config.firebase_project_id != client['FIREBASE_PROJECT_ID']:
        issue(push, 'FIREBASE_PROJECT_MISMATCH')
    if config.firebase_credentials:
        try:
            credentials = json.loads(Path(config.firebase_credentials).read_text(encoding='utf-8-sig'))
            valid = (isinstance(credentials, dict) and credentials.get('type') == 'service_account'
                     and credentials.get('private_key') and credentials.get('client_email')
                     and credentials.get('project_id') == config.firebase_project_id)
            if not valid:
                issue(push, 'FIREBASE_SERVICE_ACCOUNT_INVALID')
        except (OSError, ValueError):
            issue(push, 'FIREBASE_SERVICE_ACCOUNT_UNREADABLE')

    for provider, fields in {
        'momo': ['momo_partner_code', 'momo_access_key', 'momo_secret_key'],
        'vnpay': ['vnpay_tmn_code', 'vnpay_hash_secret'],
    }.items():
        row = group(provider, ['payment_public_base_url', *fields])
        if config.payment_environment not in ('sandbox', 'production'):
            issue(row, 'PAYMENT_ENVIRONMENT_INVALID')
        public = urlparse(config.payment_public_base_url)
        if config.payment_public_base_url:
            invalid = (public.scheme != 'https' or not public.hostname or public.username
                       or public.password or public.query or public.fragment)
            host = (public.hostname or '').lower()
            invalid = invalid or host == 'localhost' or host.endswith(('.localhost', '.local', '.test', '.invalid', '.example'))
            try:
                invalid = invalid or not ipaddress.ip_address(host).is_global
            except ValueError:
                pass  # DNS reachability and provider approval require a live test.
            if invalid:
                issue(row, 'PAYMENT_CALLBACK_NOT_PUBLIC_HTTPS')
        endpoints = ([(config.momo_endpoint, 'test-payment.momo.vn' if config.payment_environment == 'sandbox' else 'payment.momo.vn')]
                     if provider == 'momo' else [
                         (config.vnpay_payment_url, 'sandbox.vnpayment.vn' if config.payment_environment == 'sandbox' else 'pay.vnpay.vn'),
                         (config.vnpay_query_url, 'sandbox.vnpayment.vn' if config.payment_environment == 'sandbox' else 'merchant.vnpay.vn')])
        if any(urlparse(url).scheme != 'https' or urlparse(url).hostname != host
               or urlparse(url).username or urlparse(url).password for url, host in endpoints):
            issue(row, 'PAYMENT_ENDPOINT_MISMATCH')
        row['environment'] = config.payment_environment if config.payment_environment in ('sandbox', 'production') else 'invalid'

    refund_ready = config.payment_environment == 'sandbox' and any(result[p]['ready'] for p in ('momo', 'vnpay'))
    result['online_refund'] = {'ready': refund_ready, 'missing': [],
                               'issues': [] if refund_ready else ['SANDBOX_MERCHANT_REQUIRED']}
    result['media_upload'] = {'ready': config.persistent_media_enabled, 'missing': [],
                              'issues': [] if config.persistent_media_enabled else ['PERSISTENT_MEDIA_DISABLED']}
    result['pdf_report'] = {'ready': config.report_font_path.is_file(), 'missing': [],
                           'issues': [] if config.report_font_path.is_file() else ['REPORT_FONT_MISSING']}
    return result

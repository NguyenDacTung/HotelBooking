"""Gateway protocols. Only signed IPN/query results may enter the ledger.
No credentials, payment URLs or gateway response bodies are logged.
"""
import hashlib,hmac
from urllib.parse import urlparse,urlencode
from uuid import uuid4
from datetime import datetime,timedelta
import httpx
from app.core.config import settings
from app.services.stays import VN,now

def digest(secret,raw,algorithm='sha256'):
    return hmac.new(secret.encode(),raw.encode(),getattr(hashlib,algorithm)).hexdigest()

def momo_sign(data,keys):
    c=settings()
    values={**data,'accessKey':c.momo_access_key}
    return digest(c.momo_secret_key,'&'.join(k+'='+str(values[k]) for k in keys))

MOMO_CREATE=('accessKey','amount','extraData','ipnUrl','orderId','orderInfo','partnerCode','redirectUrl','requestId','requestType')
MOMO_IPN=('accessKey','amount','extraData','message','orderId','orderInfo','orderType','partnerCode','payType','requestId','responseTime','resultCode','transId')

def configured(provider):
    c=settings();public=urlparse(c.payment_public_base_url)
    if public.scheme!='https' or not public.hostname or public.username or public.password or c.payment_environment not in ('sandbox','production'):return False
    if provider=='MOMO':
        host='test-payment.momo.vn' if c.payment_environment=='sandbox' else 'payment.momo.vn'
        return bool(c.momo_partner_code and c.momo_access_key and c.momo_secret_key and urlparse(c.momo_endpoint).scheme=='https' and urlparse(c.momo_endpoint).hostname==host)
    if provider=='VNPAY':
        host='sandbox.vnpayment.vn' if c.payment_environment=='sandbox' else 'pay.vnpay.vn'
        queryhost='sandbox.vnpayment.vn' if c.payment_environment=='sandbox' else 'merchant.vnpay.vn'
        return bool(c.vnpay_tmn_code and c.vnpay_hash_secret and urlparse(c.vnpay_payment_url).scheme=='https' and urlparse(c.vnpay_payment_url).hostname==host and urlparse(c.vnpay_query_url).scheme=='https' and urlparse(c.vnpay_query_url).hostname==queryhost)
    return False

def vnp_sign(data):
    return digest(settings().vnpay_hash_secret,urlencode(sorted((k,str(v)) for k,v in data.items() if v is not None and v!='' and k not in ('vnp_SecureHash','vnp_SecureHashType'))),'sha512')

def verify_momo(data):
    try:return hmac.compare_digest(str(data['signature']),momo_sign(data,MOMO_IPN)) and data['partnerCode']==settings().momo_partner_code
    except (KeyError,TypeError,ValueError):return False

def verify_vnp(data):
    return bool(data.get('vnp_SecureHash')) and hmac.compare_digest(str(data['vnp_SecureHash']).lower(),vnp_sign(data)) and data.get('vnp_TmnCode')==settings().vnpay_tmn_code

def safe_payment_url(url,provider):
    parsed=urlparse(url)
    hosts={'MOMO':{'test-payment.momo.vn','payment.momo.vn'},'VNPAY':{'sandbox.vnpayment.vn','pay.vnpay.vn'}}
    return parsed.scheme=='https' and parsed.hostname in hosts[provider] and not parsed.username and not parsed.password

def create(attempt,ip):
    c=settings();base=c.payment_public_base_url.rstrip('/')
    if attempt.provider=='MOMO':
        data={'partnerCode':c.momo_partner_code,'requestId':str(attempt.request_id),'orderId':attempt.reference,
            'amount':int(attempt.amount),'orderInfo':'TETRA Hotel','redirectUrl':base+'/payments/return',
            'ipnUrl':base+'/payments/momo/ipn','requestType':'payWithMethod','extraData':'','lang':'vi','autoCapture':True,'orderExpireTime':15}
        data['signature']=momo_sign(data,MOMO_CREATE)
        with httpx.Client(timeout=35,follow_redirects=False) as client:
            response=client.post(c.momo_endpoint.rstrip('/')+'/create',json=data);response.raise_for_status();result=response.json()
        # A returned rejection may be definitive; malformed/timeout is not.
        if result.get('resultCode')!=0:raise ValueError('GATEWAY_REJECTED')
        url=result.get('payUrl','')
    else:
        data={'vnp_Version':'2.1.0','vnp_Command':'pay','vnp_TmnCode':c.vnpay_tmn_code,
          'vnp_Amount':int(attempt.amount)*100,'vnp_CurrCode':'VND','vnp_TxnRef':attempt.reference,
          'vnp_OrderInfo':'TETRA Hotel','vnp_OrderType':'hotel','vnp_Locale':'vn',
          'vnp_ReturnUrl':base+'/payments/return','vnp_IpAddr':ip,
          'vnp_CreateDate':attempt.ngay_tao.astimezone(VN).strftime('%Y%m%d%H%M%S'),
          'vnp_ExpireDate':attempt.expires_at.astimezone(VN).strftime('%Y%m%d%H%M%S')}
        url=c.vnpay_payment_url+'?'+urlencode(sorted(data.items()))+'&vnp_SecureHash='+vnp_sign(data)
    if not safe_payment_url(url,attempt.provider):raise RuntimeError('INVALID_PAYMENT_URL')
    return url

def query(attempt,ip):
    c=settings()
    if attempt.provider=='MOMO':
        request_id=str(uuid4());data={'partnerCode':c.momo_partner_code,'orderId':attempt.reference,'requestId':request_id,'lang':'vi'}
        data['signature']=momo_sign(data,('accessKey','orderId','partnerCode','requestId'))
        with httpx.Client(timeout=35,follow_redirects=False) as client:
            response=client.post(c.momo_endpoint.rstrip('/')+'/query',json=data);response.raise_for_status();result=response.json()
        if result.get('partnerCode')!=c.momo_partner_code or result.get('orderId')!=attempt.reference or int(result.get('amount',-1))!=int(attempt.amount):raise ValueError('QUERY_MISMATCH')
        code=int(result['resultCode'])
        # Unknown/not-found/processing never unlock a potentially charged attempt.
        return ('SUCCEEDED' if code==0 else 'FAILED' if code in (1003,1005,1006) else 'PENDING',str(result.get('transId','')))
    data={'vnp_RequestId':uuid4().hex,'vnp_Version':'2.1.0','vnp_Command':'querydr','vnp_TmnCode':c.vnpay_tmn_code,
       'vnp_TxnRef':attempt.reference,'vnp_TransactionDate':attempt.ngay_tao.astimezone(VN).strftime('%Y%m%d%H%M%S'),
       'vnp_CreateDate':now().astimezone(VN).strftime('%Y%m%d%H%M%S'),'vnp_IpAddr':ip,'vnp_OrderInfo':'TETRA Hotel'}
    keys=('vnp_RequestId','vnp_Version','vnp_Command','vnp_TmnCode','vnp_TxnRef','vnp_TransactionDate','vnp_CreateDate','vnp_IpAddr','vnp_OrderInfo')
    data['vnp_SecureHash']=digest(c.vnpay_hash_secret,'|'.join(str(data[k]) for k in keys),'sha512')
    with httpx.Client(timeout=35,follow_redirects=False) as client:
        response=client.post(c.vnpay_query_url,json=data);response.raise_for_status();r=response.json()
    keys=('vnp_ResponseId','vnp_Command','vnp_ResponseCode','vnp_Message','vnp_TmnCode','vnp_TxnRef','vnp_Amount','vnp_BankCode','vnp_PayDate','vnp_TransactionNo','vnp_TransactionType','vnp_TransactionStatus','vnp_OrderInfo','vnp_PromotionCode','vnp_PromotionAmount')
    signature=digest(c.vnpay_hash_secret,'|'.join(str(r.get(k,'')) for k in keys),'sha512')
    if not hmac.compare_digest(str(r.get('vnp_SecureHash','')).lower(),signature) or r.get('vnp_TmnCode')!=c.vnpay_tmn_code or r.get('vnp_TxnRef')!=attempt.reference or int(r.get('vnp_Amount',-1))!=int(attempt.amount)*100:raise ValueError('QUERY_MISMATCH')
    status=r.get('vnp_TransactionStatus')
    return ('SUCCEEDED' if r.get('vnp_ResponseCode')=='00' and status=='00' else 'FAILED' if r.get('vnp_ResponseCode')=='00' and status=='02' else 'PENDING',str(r.get('vnp_TransactionNo','')))

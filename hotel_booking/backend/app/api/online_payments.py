"""One active attempt per booking, durable before network, signed callbacks only."""
from uuid import UUID,uuid4
from datetime import timedelta
from fastapi import APIRouter,Depends,Request,Response
from fastapi.responses import HTMLResponse
from pydantic import Field
from sqlalchemy import select,text
from sqlalchemy.orm import Session
from app.models import PaymentAttempt,Payment,Booking,Account,Notification
from app.schemas.requests import Input
from app.db.session import get_db
from app.core.security import current,customer
from app.core.config import settings
from app.core.errors import fail
from app.services.bookings import visible_booking,get_or_404,lock_room
from app.services.payments import balance
from app.services.stays import now
from app.services import gateways
from app.services.accounts import audit
router=APIRouter(tags=['Thanh toán online'])
class Create(Input):
    provider:str=Field(pattern='^(MOMO|VNPAY)$')
    request_id:UUID

def dto(row):
    return {'id':str(row.id),'provider':row.provider,'environment':row.environment,'amount':int(row.amount),
      'state':row.state,'payment_url':row.payment_url,'expires_at':row.expires_at.isoformat(),
      'note':'Sandbox không thanh toán công nợ thật' if row.environment=='sandbox' else None}

def settle(db,key,state,transaction):
    # Same lock order as staff money operations; callback retries cannot double-book.
    initial=get_or_404(db,PaymentAttempt,key);b=get_or_404(db,Booking,initial.ma_pdp)
    if state=='SUCCEEDED':db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key,0))'),{'key':initial.provider+initial.environment+transaction})
    lock_room(db,b.ma_phong);b=get_or_404(db,Booking,b.ma_pdp,True);a=get_or_404(db,PaymentAttempt,key,True)
    if a.state=='SUCCEEDED':return a
    if state=='SUCCEEDED':
        if not transaction or transaction=='0':fail(409,'MISSING_REFERENCE','Thiếu mã giao dịch cổng thanh toán')
        other=db.scalar(select(PaymentAttempt.id).where(PaymentAttempt.provider==a.provider,PaymentAttempt.environment==a.environment,PaymentAttempt.provider_transaction==transaction,PaymentAttempt.id!=a.id))
        if other:fail(409,'TRANSACTION_CONFLICT','Giao dịch đã được đối soát cho yêu cầu khác')
        a.provider_transaction=transaction
        if not db.scalar(select(Payment.id).where(Payment.request_id==a.request_id)):
            db.add(Payment(ma_pdp=b.ma_pdp,loai='THU',so_tien=a.amount,phuong_thuc=a.provider,environment=a.environment,
              nguoi_ghi_nhan=b.ma_kh,request_id=a.request_id,ma_tham_chieu=transaction,
              ghi_chu='Cổng thanh toán xác nhận; sandbox không tính thực thu' if a.environment=='sandbox' else 'Cổng thanh toán xác nhận'))
        db.add(Notification(tai_khoan_id=b.ma_kh,loai_su_kien='online_payment',tieu_de='Cập nhật thanh toán TETRA',
            noi_dung='Kết quả thanh toán đã được đối soát. Mở hóa đơn để kiểm tra môi trường và số tiền.',
            ma_pdp=b.ma_pdp,event_key='online-payment:'+str(a.id)))
        # Never resurrect cancelled/expired bookings; balance then exposes refund owed.
        audit(db,{'account':db.get(Account,b.ma_kh)},'payment_attempt',a.id,'settle',{'state':a.state},{'state':state},'')
    a.state=state;db.commit();return a

@router.post('/bookings/{key}/online-payments')
def create(key:UUID,data:Create,request:Request,user=Depends(customer),db:Session=Depends(get_db)):
    b=visible_booking(db,key,user);lock_room(db,b.ma_phong);b=visible_booking(db,key,user,True)
    old=db.scalar(select(PaymentAttempt).where(PaymentAttempt.request_id==data.request_id))
    if old:
        if old.ma_pdp!=key or old.provider!=data.provider:fail(409,'REQUEST_CONFLICT','Mã yêu cầu đã được dùng')
        return dto(old)
    active=db.scalar(select(PaymentAttempt).where(PaymentAttempt.ma_pdp==key,PaymentAttempt.state.in_(('CREATED','PENDING'))))
    if active:return dto(active)
    if not gateways.configured(data.provider):fail(503,'PAYMENT_NOT_CONFIGURED','Cổng thanh toán chưa được cấu hình')
    due=balance(db,b)['con_phai_thu']
    if b.trang_thai not in ('DA_XAC_NHAN','DANG_O','CHO_THANH_TOAN') or due<=0:fail(409,'PAYMENT_NOT_ALLOWED','Đơn chưa đến bước thanh toán hoặc không còn tiền cần thu')
    if data.provider=='MOMO' and not 1000<=due<=50000000:fail(422,'PAYMENT_LIMIT','MoMo hỗ trợ từ 1.000 đến 50.000.000 VND')
    a=PaymentAttempt(ma_pdp=key,provider=data.provider,environment=settings().payment_environment,request_id=data.request_id,
        reference='TETRA'+uuid4().hex,amount=due,state='CREATED',expires_at=now()+timedelta(minutes=15))
    db.add(a);db.commit();db.refresh(a)
    # Close the read transaction too: no database lock held over gateway I/O.
    db.expunge(a);db.rollback()
    try:url=gateways.create(a,request.client.host if request.client else '127.0.0.1')
    except Exception:
        # Unknown result stays CREATED and blocks duplicate/manual collection.
        fail(503,'PAYMENT_UNCERTAIN','Chưa xác định kết quả tạo thanh toán. Kiểm tra trạng thái, không thu lại bằng phương thức khác')
    row=get_or_404(db,PaymentAttempt,a.id,True);row.payment_url=url
    if row.state=='CREATED':row.state='PENDING'
    db.commit();return dto(row)

@router.get('/bookings/{key}/online-payments')
def attempts(key:UUID,user=Depends(current),db:Session=Depends(get_db)):
    visible_booking(db,key,user)
    return {'items':[dto(r) for r in db.scalars(select(PaymentAttempt).where(PaymentAttempt.ma_pdp==key).order_by(PaymentAttempt.ngay_tao.desc()).limit(20))]}

@router.post('/online-payments/{key}/query')
def query(key:UUID,request:Request,user=Depends(current),db:Session=Depends(get_db)):
    a=get_or_404(db,PaymentAttempt,key);visible_booking(db,a.ma_pdp,user)
    if a.state in ('SUCCEEDED','FAILED'):return dto(a)
    if not gateways.configured(a.provider) or a.environment!=settings().payment_environment:fail(503,'PAYMENT_NOT_CONFIGURED','Cấu hình không khớp phiên thanh toán')
    db.expunge(a);db.rollback()
    try:state,transaction=gateways.query(a,request.client.host if request.client else '127.0.0.1')
    except Exception:fail(503,'PAYMENT_UNCERTAIN','Chưa xác minh được kết quả. Giữ nguyên giao dịch chờ đối soát')
    return dto(settle(db,key,state,transaction))

@router.post('/payments/momo/ipn')
def momo_ipn(data:dict,db:Session=Depends(get_db)):
    if not gateways.configured('MOMO') or not gateways.verify_momo(data):fail(400,'INVALID_SIGNATURE','Chữ ký không hợp lệ')
    a=db.scalar(select(PaymentAttempt).where(PaymentAttempt.reference==str(data.get('orderId','')),PaymentAttempt.provider=='MOMO'))
    try:valid=a and int(data['amount'])==int(a.amount) and str(data['requestId'])==str(a.request_id) and a.environment==settings().payment_environment
    except (KeyError,ValueError,TypeError):valid=False
    if not valid:fail(400,'PAYMENT_MISMATCH','Thông tin giao dịch không khớp')
    code=int(data['resultCode']);state='SUCCEEDED' if code==0 else 'PENDING' if code in (9000,1000,7000,7002) else 'FAILED'
    settle(db,a.id,state,str(data.get('transId','')));return Response(status_code=204)

@router.get('/payments/vnpay/ipn')
def vnpay_ipn(request:Request,db:Session=Depends(get_db)):
    data=dict(request.query_params)
    if len(data)!=len(list(request.query_params.multi_items())) or not gateways.configured('VNPAY') or not gateways.verify_vnp(data):return {'RspCode':'97','Message':'Invalid checksum'}
    a=db.scalar(select(PaymentAttempt).where(PaymentAttempt.reference==data.get('vnp_TxnRef'),PaymentAttempt.provider=='VNPAY'))
    if not a or a.environment!=settings().payment_environment:return {'RspCode':'01','Message':'Not found'}
    try:valid=int(data.get('vnp_Amount',-1))==int(a.amount)*100
    except ValueError:valid=False
    if not valid:return {'RspCode':'04','Message':'Invalid amount'}
    if a.state=='SUCCEEDED':return {'RspCode':'02','Message':'Already confirmed'}
    state='SUCCEEDED' if data.get('vnp_ResponseCode')=='00' and data.get('vnp_TransactionStatus')=='00' else 'FAILED'
    settle(db,a.id,state,data.get('vnp_TransactionNo',''));return {'RspCode':'00','Message':'Confirmed'}

@router.get('/payments/return',response_class=HTMLResponse)
def returned():
    # No query payload echoed and no ledger mutation from a browser redirect.
    return '<meta charset="utf-8"><h1>TETRA Hotel</h1><p>Hãy quay lại ứng dụng và kiểm tra kết quả thanh toán. Trang chuyển về không xác nhận đã thu tiền.</p>'

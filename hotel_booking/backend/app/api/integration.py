"""Real integration endpoints; whitelist public config and protect private media."""
import csv,io,hashlib,json
from datetime import date,timedelta
from uuid import UUID,uuid4
from pathlib import Path
from fastapi import APIRouter,Depends,UploadFile,File,Form,Query,Response
from fastapi.responses import FileResponse
from pydantic import Field
from PIL import Image,UnidentifiedImageError
from sqlalchemy import select,func
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import current,manager,staff
from app.core.config import settings
from app.core.errors import fail
from app.models import Account,Room,RoomType,Booking,Closure,ImportBatch,Feedback,HotelSettings,HOLD
from app.schemas.requests import Input
from app.services.bookings import get_or_404
from app.services.accounts import audit
from app.services.stays import now,VN
from app.api.catalog import page_result,columns

router=APIRouter(tags=['TETRA tích hợp'])

def feature(configured,environment=None):
    return {'enabled':bool(configured),'configured':bool(configured),'reason_code':None if configured else 'NOT_CONFIGURED',**({'environment':environment} if environment else {})}

@router.get('/app/capabilities')
def capabilities():
    c=settings()
    from app.services.gateways import configured
    return {'payments':{p.lower():feature(configured(p),c.payment_environment) for p in ('MOMO','VNPAY')},
        'social_login':{'google':feature(c.google_client_id),'facebook':feature(c.facebook_app_id and c.facebook_app_secret)},
        'push':feature(c.firebase_project_id and c.firebase_credentials),'recovery':feature(c.smtp_host and c.smtp_from),
        'media_upload':feature(c.persistent_media_enabled),'online_refund':feature(False)}

class PublicSettings(Input):
    video_url:str=Field('',max_length=2000)
    video_caption:str=Field('',max_length=500)
    hotel_phone:str=Field('',max_length=30)
    hotel_email:str=Field('',max_length=254)
    website:str=Field('',max_length=2000)

@router.get('/hotel/info')
def info(db:Session=Depends(get_db)):
    row=db.get(HotelSettings,'hotel')
    return {'name':'TETRA','latitude':10.855802343959219,'longitude':106.78566243940791,**(row.value if row else PublicSettings().model_dump())}

@router.put('/admin/hotel/info')
def update_info(data:PublicSettings,user=Depends(manager),db:Session=Depends(get_db)):
    from urllib.parse import urlparse
    for url in (data.video_url,data.website):
        if url and (urlparse(url).scheme!='https' or not urlparse(url).hostname):fail(422,'INVALID_URL','Cần URL HTTPS hợp lệ')
    if data.video_url and ('youtu.be' in data.video_url or 'youtube.com' in data.video_url):fail(422,'INVALID_VIDEO','Dùng URL file video trực tiếp, không dùng trang YouTube')
    row=db.get(HotelSettings,'hotel')
    old=row.value if row else None
    if not row:row=HotelSettings(key='hotel',value=data.model_dump());db.add(row)
    else:row.value=data.model_dump()
    audit(db,user,'hotel','hotel','settings',old,data.model_dump(),'');db.commit();return info(db)

def image_bytes(file):
    raw=file.file.read(5*1024*1024+1)
    if len(raw)>5*1024*1024:fail(422,'FILE_TOO_LARGE','Ảnh tối đa 5 MiB')
    try:
        with Image.open(io.BytesIO(raw)) as im:
            ext={'JPEG':'.jpg','PNG':'.png','WEBP':'.webp'}.get(im.format)
            if not ext or im.width*im.height>25000000:raise ValueError()
            im.verify()
    except (OSError,ValueError,Image.DecompressionBombError):fail(422,'INVALID_IMAGE','Cần ảnh JPEG, PNG hoặc WebP hợp lệ')
    return raw,ext

@router.post('/users/me/avatar')
def avatar(file:UploadFile=File(),user=Depends(current),db:Session=Depends(get_db)):
    if not settings().persistent_media_enabled:fail(503,'MEDIA_NOT_CONFIGURED','Lưu ảnh chưa được cấu hình')
    raw,ext=image_bytes(file);name='avatar-'+str(uuid4())+ext;directory=settings().upload_dir
    directory.mkdir(parents=True,exist_ok=True);path=directory/name;path.write_bytes(raw)
    a=get_or_404(db,Account,user['account'].id,True);a.avatar_url='/uploads/'+name
    try:db.commit()
    except Exception:path.unlink(missing_ok=True);raise
    from app.schemas.responses import profile_out
    return profile_out(user)

@router.get('/staff/rooms/{key}/calendar')
def calendar(key:int,tu_ngay:date,den_ngay:date,user=Depends(staff),db:Session=Depends(get_db)):
    get_or_404(db,Room,key)
    if not 0<=(den_ngay-tu_ngay).days<=92:fail(422,'INVALID_RANGE','Lịch tối đa 93 ngày')
    bookings=db.scalars(select(Booking).where(Booking.ma_phong==key,Booking.ngay_nhan<=den_ngay,Booking.ngay_tra>tu_ngay,Booking.trang_thai.in_(HOLD)))
    closures=db.scalars(select(Closure).where(Closure.ma_phong==key,Closure.tu_ngay<=den_ngay,Closure.den_ngay>tu_ngay,Closure.dang_hieu_luc.is_(True)))
    return {'bookings':[{'id':str(b.ma_pdp),'start':str(b.ngay_nhan),'end':str(b.ngay_tra),'status':b.trang_thai} for b in bookings],
        'closures':[{'id':c.ma_ngung,'start':str(c.tu_ngay),'end':str(c.den_ngay),'reason':c.ly_do} for c in closures]}

@router.get('/staff/booking-reference/{reference}')
def lookup(reference:str,user=Depends(staff),db:Session=Depends(get_db)):
    try:key=UUID(reference.removeprefix('TETRA:1:').removeprefix('TTTP:1:'))
    except ValueError:fail(422,'INVALID_QR','Mã đặt phòng không hợp lệ')
    from app.schemas.responses import booking_out
    return booking_out(db,get_or_404(db,Booking,key),True)

def validate_rows(db,rows):
    errors=[];seen=set()
    if not 1<=len(rows)<=1000:fail(422,'CSV_LIMIT','CSV cần 1–1000 dòng')
    for index,r in enumerate(rows,2):
        try:
            if set(r)-{'so_phong','ma_lp','tang','ghi_chu'}:raise ValueError('Cột CSV không được hỗ trợ')
            number=str(r.get('so_phong','')).strip()
            if not 1<=len(number)<=20:raise ValueError('Số phòng cần 1–20 ký tự')
            if number in seen or db.scalar(select(Room.ma_phong).where(Room.so_phong==number)):raise ValueError('Số phòng đã tồn tại hoặc bị lặp')
            seen.add(number);kind=int(r['ma_lp'])
            if not db.get(RoomType,kind):raise ValueError('Loại phòng không tồn tại')
            floor=int(r['tang']) if r.get('tang') else None
            if floor is not None and not -32768<=floor<=32767:raise ValueError('Tầng ngoài giới hạn')
            if len(str(r.get('ghi_chu') or ''))>2000:raise ValueError('Ghi chú quá dài')
        except (ValueError,KeyError,TypeError) as e:errors.append({'line':index,'message':str(e) if isinstance(e,ValueError) else 'Thiếu hoặc sai cột dữ liệu'})
    return errors

@router.get('/admin/room-import/template')
def template(user=Depends(manager)):
    return Response('\ufeffso_phong,ma_lp,tang,ghi_chu\n',media_type='text/csv; charset=utf-8')

@router.post('/admin/room-import/preview')
def preview(file:UploadFile=File(),user=Depends(manager),db:Session=Depends(get_db)):
    raw=file.file.read(2*1024*1024+1)
    if len(raw)>2*1024*1024 or not (file.filename or '').lower().endswith('.csv'):fail(422,'CSV_LIMIT','Chọn CSV tối đa 2 MiB')
    try:rows=list(csv.DictReader(io.StringIO(raw.decode('utf-8-sig')),strict=True))
    except (UnicodeError,csv.Error):fail(422,'INVALID_CSV','CSV phải dùng UTF-8 và đúng dấu phân cách')
    errors=validate_rows(db,rows)
    batch=ImportBatch(nguoi_tao=user['account'].id,file_hash=hashlib.sha256(raw).hexdigest(),du_lieu=rows)
    db.add(batch);db.commit()
    return {'id':str(batch.id),'rows':rows,'errors':errors,'can_import':not errors}

@router.post('/admin/room-import/{key}/confirm')
def confirm(key:UUID,user=Depends(manager),db:Session=Depends(get_db)):
    batch=get_or_404(db,ImportBatch,key,True)
    if batch.nguoi_tao!=user['account'].id:fail(404,'NOT_FOUND','Không tìm thấy đợt nhập')
    if batch.da_nhap:return {'imported':len(batch.du_lieu),'replayed':True}
    if batch.ngay_tao<now()-timedelta(minutes=30):fail(409,'PREVIEW_EXPIRED','Bản xem trước đã hết hạn; chọn lại file')
    errors=validate_rows(db,batch.du_lieu)
    if errors:fail(409,'CSV_CONFLICT','Dữ liệu có lỗi hoặc đã thay đổi; xem trước lại trước khi nhập')
    for r in batch.du_lieu:db.add(Room(so_phong=r['so_phong'].strip(),ma_lp=int(r['ma_lp']),tang=int(r['tang']) if r.get('tang') else None,ghi_chu=r.get('ghi_chu') or None))
    batch.da_nhap=True;audit(db,user,'room_import',key,'confirm',None,{'rows':len(batch.du_lieu)},'');db.commit()
    return {'imported':len(batch.du_lieu),'replayed':False}

@router.post('/feedback',status_code=201)
def feedback(noi_dung:str=Form(min_length=1,max_length=4000),thiet_bi:str=Form('{}'),file:UploadFile|None=File(None),user=Depends(current),db:Session=Depends(get_db)):
    if not noi_dung.strip():fail(422,'INVALID_FEEDBACK','Nhập nội dung phản hồi')
    from app.api.recovery import throttle
    throttle(db,'feedback:'+str(user['account'].id),5)
    try:device=json.loads(thiet_bi)
    except ValueError:fail(422,'INVALID_DEVICE','Thông tin thiết bị không hợp lệ')
    if not isinstance(device,dict) or any(k not in ('model','os','app_version') or not isinstance(v,str) or len(v)>150 for k,v in device.items()):fail(422,'INVALID_DEVICE','Chỉ gửi model, OS và phiên bản app')
    name=None;path=None
    if file:
        if not settings().persistent_media_enabled:fail(503,'MEDIA_NOT_CONFIGURED','Lưu ảnh chưa được cấu hình; có thể gửi nội dung không kèm ảnh')
        raw,ext=image_bytes(file);name=str(uuid4())+ext;directory=settings().private_upload_dir;directory.mkdir(parents=True,exist_ok=True);path=directory/name;path.write_bytes(raw)
    row=Feedback(tai_khoan_id=user['account'].id,noi_dung=noi_dung.strip(),thiet_bi=device,anh=name);db.add(row)
    try:db.commit()
    except Exception:
        if path:path.unlink(missing_ok=True)
        raise
    return {'id':str(row.id),'status':row.trang_thai}

@router.get('/admin/feedback',dependencies=[Depends(manager)])
def feedback_list(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),db:Session=Depends(get_db)):
    return page_result(db,select(Feedback).order_by(Feedback.ngay_tao.desc(),Feedback.id),page,page_size,columns)

class FeedbackStatus(Input):trang_thai:str=Field(pattern='^(TIEP_NHAN|DANG_XU_LY|DA_XU_LY)$')
@router.patch('/admin/feedback/{key}')
def feedback_status(key:UUID,data:FeedbackStatus,user=Depends(manager),db:Session=Depends(get_db)):
    row=get_or_404(db,Feedback,key,True);audit(db,user,'feedback',key,'status',{'state':row.trang_thai},{'state':data.trang_thai},'');row.trang_thai=data.trang_thai;db.commit();return columns(row)

@router.get('/feedback/{key}/attachment')
def attachment(key:UUID,user=Depends(current),db:Session=Depends(get_db)):
    row=get_or_404(db,Feedback,key)
    if row.tai_khoan_id!=user['account'].id and user['role']!='QUAN_LY':fail(404,'NOT_FOUND','Không tìm thấy ảnh')
    if not row.anh:fail(404,'NOT_FOUND','Không có ảnh đính kèm')
    directory=settings().private_upload_dir.resolve();path=(directory/row.anh).resolve()
    if path.parent!=directory or not path.is_file():fail(404,'NOT_FOUND','Không tìm thấy ảnh')
    return FileResponse(path,headers={'Cache-Control':'no-store'})

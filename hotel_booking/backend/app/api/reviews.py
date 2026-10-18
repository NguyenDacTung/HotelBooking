from uuid import UUID
from datetime import date,datetime,time,timedelta,timezone
from fastapi import APIRouter,Depends,Query
from sqlalchemy import select,func
from sqlalchemy.orm import Session
from pydantic import Field
from app.db.session import get_db
from app.core.security import current,customer,manager
from app.core.errors import fail
from app.models import Review,Booking,Customer,Account,Room,Notification
from app.schemas.requests import Input
from app.services.bookings import get_or_404,visible_booking
from app.services.accounts import audit
from app.api.catalog import page_result
from app.services.stays import now,VN

router=APIRouter(tags=['Đánh giá'])
class ReviewInput(Input):
    so_sao:int=Field(ge=1,le=5,strict=True)
    nhan_xet:str|None=Field(None,max_length=1000)
class Visibility(Input):
    hien_thi:bool
    ly_do:str=Field('',max_length=2000)

def summary(db,room_ids):
    result={key:{'diem_trung_binh':None,'so_danh_gia':0} for key in room_ids}
    for rid,count,average in db.execute(select(Booking.ma_phong,func.count(Review.id),func.avg(Review.so_sao)).join(Review,Review.ma_pdp==Booking.ma_pdp)
        .where(Booking.ma_phong.in_(room_ids),Review.hien_thi.is_(True)).group_by(Booking.ma_phong)):
        result[rid]={'diem_trung_binh':round(float(average),1),'so_danh_gia':count}
    return result

def out(db,row,private=False):
    b=db.get(Booking,row.ma_pdp);owner=db.get(Customer,b.ma_kh);a=db.get(Account,b.ma_kh)
    words=owner.ho_ten.strip().split()
    name=words[-1]+(' '+words[0][0]+'.' if len(words)>1 else '') if words else 'Khách lưu trú'
    data={'id':str(row.id),'so_sao':row.so_sao,'nhan_xet':row.nhan_xet,'ngay_tao':row.ngay_tao.isoformat(),'ten_hien_thi':name,'avatar_url':a.avatar_url,'da_luu_tru':True}
    if private:data.update({'ma_pdp':str(b.ma_pdp),'ma_phong':b.ma_phong,'so_phong':db.get(Room,b.ma_phong).so_phong,
        'ngay_nhan':str(b.ngay_nhan),'ngay_tra':str(b.ngay_tra),'hien_thi':row.hien_thi,'ly_do_an':row.ly_do_an})
    return data

@router.post('/bookings/{key}/review',status_code=201)
def create(key:UUID,data:ReviewInput,user=Depends(customer),db:Session=Depends(get_db)):
    b=visible_booking(db,key,user,True)
    if b.trang_thai!='DA_HOAN_TAT' or b.tra_phong_luc is None:fail(409,'STAY_NOT_COMPLETED','Chỉ đánh giá sau khi đã hoàn tất trả phòng')
    if db.scalar(select(Review.id).where(Review.ma_pdp==key)):fail(409,'REVIEW_EXISTS','Bạn đã đánh giá kỳ lưu trú này')
    row=Review(ma_pdp=key,**data.model_dump());db.add(row);db.flush()
    audit(db,user,'review',row.id,'create',None,{'so_sao':row.so_sao},'')
    db.commit();return out(db,row,True)

@router.get('/bookings/{key}/review')
def detail(key:UUID,user=Depends(current),db:Session=Depends(get_db)):
    b=visible_booking(db,key,user)
    if b.ma_kh!=user['account'].id and user['role']!='QUAN_LY':fail(403,'FORBIDDEN','Không có quyền xem đánh giá riêng')
    row=db.scalar(select(Review).where(Review.ma_pdp==key))
    return {'review':out(db,row,True) if row else None,'can_review':user['role']=='KHACH_HANG' and b.trang_thai=='DA_HOAN_TAT' and b.tra_phong_luc is not None and row is None}

@router.get('/rooms/{key}/reviews')
def public(key:int,sort:str=Query('newest',pattern='^(newest|highest|lowest)$'),stars:int|None=Query(None,ge=1,le=5),
    page:int=Query(1,ge=1),page_size:int=Query(10,ge=1,le=50),db:Session=Depends(get_db)):
    room=get_or_404(db,Room,key)
    if not room.dang_kinh_doanh:fail(404,'NOT_FOUND','Không tìm thấy phòng')
    base=select(Review).join(Booking).where(Booking.ma_phong==key,Review.hien_thi.is_(True))
    query=base.where(Review.so_sao==stars) if stars else base
    order=Review.so_sao.desc() if sort=='highest' else Review.so_sao.asc() if sort=='lowest' else Review.ngay_tao.desc()
    data=page_result(db,query.order_by(order,Review.ngay_tao.desc(),Review.id),page,page_size,lambda r:out(db,r))
    data.update(summary(db,[key])[key]);data['phan_bo']={str(i):0 for i in range(1,6)}
    for stars,count in db.execute(select(Review.so_sao,func.count()).join(Booking).where(Booking.ma_phong==key,Review.hien_thi.is_(True)).group_by(Review.so_sao)):data['phan_bo'][str(stars)]=count
    return data

@router.get('/users/me/reviews')
def mine(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),user=Depends(current),db:Session=Depends(get_db)):
    return page_result(db,select(Review).join(Booking).where(Booking.ma_kh==user['account'].id).order_by(Review.ngay_tao.desc(),Review.id),page,page_size,lambda r:out(db,r,True))

@router.get('/admin/reviews')
def admin(ma_phong:int|None=None,ma_lp:int|None=None,so_sao:int|None=Query(None,ge=1,le=5),hien_thi:bool|None=None,
    tu_ngay:date|None=None,den_ngay:date|None=None,page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),user=Depends(manager),db:Session=Depends(get_db)):
    query=select(Review).join(Booking).join(Room)
    if ma_phong:query=query.where(Room.ma_phong==ma_phong)
    if ma_lp:query=query.where(Room.ma_lp==ma_lp)
    if so_sao:query=query.where(Review.so_sao==so_sao)
    if hien_thi is not None:query=query.where(Review.hien_thi==hien_thi)
    if tu_ngay:query=query.where(Review.ngay_tao>=datetime.combine(tu_ngay,time.min,VN))
    if den_ngay:query=query.where(Review.ngay_tao<datetime.combine(den_ngay+timedelta(days=1),time.min,VN))
    return page_result(db,query.order_by(Review.ngay_tao.desc(),Review.id),page,page_size,lambda r:out(db,r,True))

@router.patch('/admin/reviews/{key}/visibility')
def visibility(key:UUID,data:Visibility,user=Depends(manager),db:Session=Depends(get_db)):
    row=get_or_404(db,Review,key,True)
    if row.hien_thi!=data.hien_thi:
        audit(db,user,'review',key,'visibility',{'hien_thi':row.hien_thi},{'hien_thi':data.hien_thi},data.ly_do)
        row.hien_thi=data.hien_thi;row.ly_do_an=data.ly_do if not data.hien_thi else None;row.ngay_cap_nhat=now();db.commit()
    return out(db,row,True)

from fastapi import APIRouter,Depends
from pydantic import Field
from sqlalchemy import select,delete
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models import DeviceToken
from app.core.security import current
from app.schemas.requests import Input
from app.services.stays import now

router=APIRouter(tags=['Thiết bị'])
class Token(Input):token:str=Field(min_length=20,max_length=4096)

@router.post('/devices')
def register(data:Token,user=Depends(current),db:Session=Depends(get_db)):
    from sqlalchemy.dialects.postgresql import insert
    db.execute(insert(DeviceToken).values(tai_khoan_id=user['account'].id,token=data.token,token_version=user['account'].token_version,ngay_cap_nhat=now())
      .on_conflict_do_update(index_elements=['token'],set_={'tai_khoan_id':user['account'].id,'token_version':user['account'].token_version,'ngay_cap_nhat':now()}))
    db.commit();return {'status':'ok'}

@router.delete('/devices')
def remove(data:Token,user=Depends(current),db:Session=Depends(get_db)):
    db.execute(delete(DeviceToken).where(DeviceToken.token==data.token,DeviceToken.tai_khoan_id==user['account'].id));db.commit();return {'status':'ok'}

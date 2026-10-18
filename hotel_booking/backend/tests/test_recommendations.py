from datetime import timedelta
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from test_postgres import setup
from app.models import Booking, Closure, Room
from app.services.rules import today

pytestmark = pytest.mark.postgres


@pytest.mark.parametrize('state,offset,occupied', [
    ('CHO_XAC_NHAN',5,True), ('DA_XAC_NHAN',5,True),
    ('DA_XAC_NHAN',-1,True), ('DA_XAC_NHAN',-2,False),
    ('DA_HUY',5,False), ('DA_TU_CHOI',5,False),
])
def test_recommendations_exclude_unreturned_active_bookings(setup,state,offset,occupied):
    from app.main import app
    with Session(setup['engine']) as db:
        db.add(Booking(ma_phong=setup['room'],ma_kh=setup['ids'][0],
            ngay_nhan=today()+timedelta(days=offset),ngay_tra=today()+timedelta(days=offset+2),
            so_khach=2,don_gia_moi_dem=500000,tong_tien=1000000,
            ten_lien_he='Test',sdt_lien_he='0900000000',trang_thai=state,
            ly_do_tu_choi='Test rejection' if state=='DA_TU_CHOI' else None))
        db.commit()
    with TestClient(app) as client:
        stay={'ngay_nhan':str(today()),'ngay_tra':str(today()+timedelta(days=1)),'so_khach':2}
        response=client.get('/rooms/recommended',params=stay)
        assert response.status_code==200,response.text
        assert response.json()['total']==(0 if occupied else 1)
        detail=client.get(f'/rooms/{setup["room"]}').json()
        assert detail['trang_thai_su_dung']==('DA_DAT_TRUOC' if occupied else 'CON_TRONG')
        # Recommendation policy does not remove date-based future booking options.
        future=stay|{'ngay_nhan':str(today()+timedelta(days=20)),'ngay_tra':str(today()+timedelta(days=21))}
        assert client.get('/rooms/available',params=future).json()['total']==1


def test_recommendations_respect_capacity_closures_and_business_flags(setup):
    from app.main import app
    with TestClient(app) as client:
        stay={'ngay_nhan':str(today()),'ngay_tra':str(today()+timedelta(days=1)),'so_khach':2}
        assert client.get('/rooms/recommended',params=stay|{'so_khach':3}).json()['total']==0
        assert client.get('/rooms/recommended',params=stay|{'ngay_tra':str(today())}).status_code==422
        with Session(setup['engine']) as db:
            db.add(Closure(ma_phong=setup['room'],tu_ngay=today(),den_ngay=today()+timedelta(days=1),ly_do='Test',nguoi_tao=setup['ids'][2]));db.commit()
        assert client.get('/rooms/recommended',params=stay).json()['total']==0
        with Session(setup['engine']) as db:
            for closure in db.query(Closure).all(): closure.dang_hieu_luc=False
            db.get(Room,setup['room']).dang_kinh_doanh=False;db.commit()
        assert client.get('/rooms/recommended',params=stay).json()['total']==0

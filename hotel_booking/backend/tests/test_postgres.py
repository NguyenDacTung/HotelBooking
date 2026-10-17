"""Real PostgreSQL tests. Never substituted with SQLite or mocked sessions."""
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from threading import Barrier
from uuid import uuid4
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, func, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from app.models import Account, Customer, Staff, Role, RoomType, Room, Booking, History, Closure, RoomImage
from app.core.security import passwords, principal, issue_token
from app.core.errors import DomainError
from app.schemas.requests import BookingCreate, ClosureCreate
from app.services.rules import today
from app.services.bookings import create_booking, save_closure, transition

pytestmark = pytest.mark.postgres


@pytest.fixture
def setup(pg_engine):
    with Session(pg_engine, expire_on_commit=False) as db:
        role = Role(ten_chuc_vu='Quản lý', ma_quyen='QUAN_LY')
        reception = Role(ten_chuc_vu='Lễ tân', ma_quyen='LE_TAN')
        db.add_all([role, reception])
        db.flush()
        ids = []
        for i in range(4):
            account = Account(email=f'user{i}@example.com', mat_khau_bam=passwords.hash('test-password'),
                loai_tai_khoan='KHACH_HANG' if i < 2 else 'NHAN_VIEN')
            db.add(account)
            db.flush()
            if i < 2:
                db.add(Customer(id=account.id, ho_ten=f'Khách {i}'))
            else:
                db.add(Staff(id=account.id, ho_ten=f'Nhân viên {i}', ma_cv=role.ma_cv if i == 2 else reception.ma_cv))
            ids.append(account.id)
        kind = RoomType(ten_loai='Test', gia_co_ban=500000, suc_chua=2)
        db.add(kind)
        db.flush()
        room = Room(so_phong='101', ma_lp=kind.ma_lp)
        db.add(room)
        db.commit()
        return {'engine': pg_engine, 'ids': ids, 'room': room.ma_phong, 'type': kind.ma_lp}


def payload(env, offset=5, nights=2, **changes):
    return BookingCreate(**({'ma_phong': env['room'], 'ngay_nhan': today() + timedelta(days=offset),
        'ngay_tra': today() + timedelta(days=offset + nights), 'so_khach': 2,
        'ten_lien_he': 'Khách thử nghiệm', 'sdt_lien_he': '0900000000'} | changes))


def user(db, env, index=0):
    return principal(db, db.get(Account, env['ids'][index]))


def make(env, offset=5, **changes):
    with Session(env['engine'], expire_on_commit=False) as db:
        return create_booking(db, user(db, env), payload(env, offset=offset, **changes))


def client_for(env, index=0):
    from app.main import app
    with Session(env['engine']) as db:
        token = issue_token(db.get(Account, env['ids'][index]))
    client = TestClient(app)
    client.headers['Authorization'] = f'Bearer {token}'
    return client


def test_registration_login_and_mass_assignment(setup):
    client = client_for(setup)
    data = {'email': ' New@Example.com ', 'mat_khau': 'test-password', 'ho_ten': 'Người mới'}
    response = client.post('/auth/register', json=data)
    assert response.status_code == 201 and 'mat_khau_bam' not in response.text
    assert client.post('/auth/register', json=data | {'email': 'new@example.com'}).status_code == 409
    assert client.post('/auth/login', json={'email': 'new@example.com', 'mat_khau': 'wrong-password'}).status_code == 401
    assert client.post('/auth/register', json=data | {'email':'another@example.com','role':'QUAN_LY'}).status_code == 422
    with Session(setup['engine']) as db:
        account = db.scalar(select(Account).where(Account.email == 'new@example.com'))
        assert db.get(Customer, account.id)


def test_create_snapshot_history_and_back_to_back(setup):
    booking = make(setup)
    assert booking.trang_thai == 'CHO_XAC_NHAN' and booking.tong_tien == 1000000
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(History).where(History.ma_pdp == booking.ma_pdp)) == 1
        db.get(RoomType, setup['type']).gia_co_ban = 600000
        db.commit()
    following = make(setup, offset=7)
    assert following.don_gia_moi_dem == 600000 and booking.don_gia_moi_dem == 500000


@pytest.mark.parametrize('confirmed', [False, True])
def test_both_holding_states_block(setup, confirmed):
    booking = make(setup)
    with Session(setup['engine'], expire_on_commit=False) as db:
        if confirmed:
            transition(db, booking.ma_pdp, user(db, setup, 2), 'confirm')
    with pytest.raises(DomainError) as error:
        make(setup)
    assert error.value.status == 409


@pytest.mark.parametrize('action,index', [('cancel',0), ('reject',2)])
def test_terminal_state_releases_room(setup, action, index):
    booking = make(setup)
    with Session(setup['engine'], expire_on_commit=False) as db:
        transition(db, booking.ma_pdp, user(db, setup, index), action, 'Lý do thử nghiệm')
    assert make(setup).trang_thai == 'CHO_XAC_NHAN'


def test_ownership_roles_capacity_and_closure(setup):
    booking = make(setup)
    other = client_for(setup, 1)
    assert other.get(f'/bookings/{booking.ma_pdp}').status_code == 404
    assert other.patch(f'/bookings/{booking.ma_pdp}/cancel', json={}).status_code == 404
    assert other.get('/staff/rooms').status_code == 403
    assert client_for(setup,3).get('/staff/rooms').status_code == 403
    manager = client_for(setup,2)
    assert manager.patch(f'/staff/room-types/{setup["type"]}', json={'suc_chua':1}).status_code == 409
    assert manager.post('/staff/room-closures', json={'ma_phong':setup['room'], 'tu_ngay':booking.ngay_nhan.isoformat(),
        'den_ngay':booking.ngay_tra.isoformat(),'ly_do':'Bảo trì'}).status_code == 409
    with pytest.raises(DomainError):
        make(setup, offset=10, so_khach=3)


def test_hidden_rooms_and_closure_block_creation(setup):
    manager = client_for(setup,2)
    assert manager.patch(f'/staff/rooms/{setup["room"]}',json={'dang_kinh_doanh':False}).status_code == 200
    with pytest.raises(DomainError): make(setup)
    manager.patch(f'/staff/rooms/{setup["room"]}',json={'dang_kinh_doanh':True})
    data = payload(setup)
    assert manager.post('/staff/room-closures',json={'ma_phong':setup['room'],'tu_ngay':data.ngay_nhan.isoformat(),
        'den_ngay':data.ngay_tra.isoformat(),'ly_do':'Bảo trì'}).status_code == 201
    with pytest.raises(DomainError): make(setup)


def test_profile_and_cover_constraints(setup):
    with Session(setup['engine']) as db:
        account = Account(email='invalid@example.com',mat_khau_bam='not-used',loai_tai_khoan='KHACH_HANG')
        db.add(account)
        with pytest.raises(IntegrityError): db.commit()
        db.rollback()
        db.add_all([RoomImage(ma_lp=setup['type'],duong_dan=f'/uploads/{i}.png',la_anh_bia=True) for i in range(2)])
        with pytest.raises(IntegrityError): db.commit()


def test_history_failure_rolls_back(setup, monkeypatch):
    with Session(setup['engine'], expire_on_commit=False) as db:
        original = db.add
        def failing_add(obj, **kwargs):
            if isinstance(obj, History): raise RuntimeError('Injected history failure')
            return original(obj, **kwargs)
        monkeypatch.setattr(db, 'add', failing_add)
        with pytest.raises(RuntimeError): create_booking(db, user(db, setup), payload(setup))
        db.rollback()
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(Booking)) == 0


def test_upload_validation_and_cover_swap(setup):
    from io import BytesIO
    from PIL import Image
    client = client_for(setup,2)
    path = f'/staff/room-types/{setup["type"]}/images'
    assert client.post(path,files={'file':('fake.jpg',b'not an image','image/jpeg')}).status_code == 422
    assert client.post(path,files={'file':('huge.jpg',b'x'*(5*1024*1024+1),'image/jpeg')}).status_code == 422
    image = BytesIO(); Image.new('RGB',(16,16)).save(image,format='PNG')
    first = client.post(path,files={'file':('../../escape.png',image.getvalue(),'image/png')},data={'la_anh_bia':'true'})
    assert first.status_code == 201 and '..' not in first.json()['duong_dan']
    second = client.post(path,files={'file':('b.png',image.getvalue(),'image/png')},data={'la_anh_bia':'true'})
    assert second.status_code == 201
    with Session(setup['engine']) as db:
        assert db.scalar(select(func.count()).select_from(RoomImage).where(RoomImage.la_anh_bia.is_(True))) == 1


@pytest.mark.parametrize('race', ['booking', 'closure', 'transition'])
def test_real_independent_connection_races(setup, race):
    barrier = Barrier(2)
    booking = make(setup) if race == 'transition' else None
    def worker(index):
        with Session(setup['engine'], expire_on_commit=False) as db:
            current = user(db, setup, 2 if race in ('closure','transition') and index == 1 else 0)
            # Check out both connections before barrier, then contend for the same room row.
            db.execute(text('SELECT 1'))
            barrier.wait(timeout=10)
            try:
                if race == 'transition':
                    transition(db, booking.ma_pdp, current, 'confirm' if index else 'cancel')
                elif race == 'closure' and index:
                    data = payload(setup)
                    save_closure(db,current,ClosureCreate(ma_phong=setup['room'],tu_ngay=data.ngay_nhan,den_ngay=data.ngay_tra,ly_do='Bảo trì'))
                else:
                    create_booking(db,current,payload(setup))
                return 201
            except DomainError as error:
                db.rollback()
                return error.status
            except IntegrityError:
                db.rollback()
                return 409
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(worker, [0,1]))
    # Confirm then cancel is valid serial execution; cancel then confirm must conflict.
    if race == 'transition':
        assert results[0] == 201 and results[1] in (201,409)
        with Session(setup['engine']) as db:
            final = db.get(Booking, booking.ma_pdp)
            assert final.trang_thai == 'DA_HUY'
    else:
        assert sorted(results) == [201,409]

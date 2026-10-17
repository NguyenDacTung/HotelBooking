from datetime import timedelta, datetime, timezone
import pytest
import jwt
from pydantic import ValidationError
from fastapi.testclient import TestClient
from sqlalchemy.schema import CreateTable
from sqlalchemy.dialects import postgresql
from app.core.errors import DomainError
from app.core.config import Settings, settings
from app.core.security import passwords
from app.schemas.requests import BookingCreate, Register, Reject
from app.services.rules import today, validate_stay, next_state
from app.models import Base


def test_health_and_openapi_without_database():
    from app.main import app
    with TestClient(app) as client:
        assert client.get('/health').json() == {'status': 'ok'}
        schema = client.get('/openapi.json').json()
        assert '/rooms/available' in schema['paths']
        assert '/staff/room-closures/{key}' in schema['paths']


@pytest.mark.parametrize('offset,nights', [(-1, 2), (1, 0), (1, -1), (1, 31)])
def test_bad_dates(offset, nights):
    start = today() + timedelta(days=offset)
    with pytest.raises(DomainError):
        validate_stay(start, start + timedelta(days=nights), 1)


def test_capacity_and_good_dates():
    validate_stay(today(), today() + timedelta(days=30), 2, 2)
    with pytest.raises(DomainError):
        validate_stay(today(), today() + timedelta(days=1), 3, 2)


@pytest.mark.parametrize('field,value', [('ma_kh','forged'), ('trang_thai','DA_XAC_NHAN'), ('tong_tien',1), ('role','QUAN_LY')])
def test_mass_assignment_rejected(field, value):
    with pytest.raises(ValidationError):
        BookingCreate(**{'ma_phong': 1, 'ngay_nhan': today(), 'ngay_tra': today() + timedelta(days=1),
                         'so_khach': 1, 'ten_lien_he': 'A', 'sdt_lien_he': '0900000000', field: value})


def test_normalization_preserves_password():
    obj = Register(email='  Guest@EXAMPLE.com ', mat_khau='  password  ', ho_ten=' A ')
    assert obj.email == 'guest@example.com' and obj.mat_khau == '  password  ' and obj.ho_ten == 'A'
    with pytest.raises(ValidationError):
        Reject(ly_do='   ')


def test_transition_permissions_and_cutoff():
    tomorrow = today() + timedelta(days=1)
    assert next_state('CHO_XAC_NHAN','confirm',tomorrow,'LE_TAN',False) == 'DA_XAC_NHAN'
    assert next_state('DA_XAC_NHAN','cancel',tomorrow,'KHACH_HANG',True) == 'DA_HUY'
    for old, action, arrival, role, owner, expected in [
        ('DA_HUY','cancel',tomorrow,'KHACH_HANG',True,409),
        ('CHO_XAC_NHAN','cancel',today(),'KHACH_HANG',True,400),
        ('CHO_XAC_NHAN','cancel',tomorrow,'KHACH_HANG',False,404),
        ('CHO_XAC_NHAN','confirm',tomorrow,'KHACH_HANG',True,403),
        ('DA_XAC_NHAN','reject',tomorrow,'QUAN_LY',False,409)]:
        with pytest.raises(DomainError) as exc:
            next_state(old,action,arrival,role,owner)
        assert exc.value.status == expected


def test_password_hash():
    hashed = passwords.hash('test-password')
    assert hashed.startswith('$argon2') and passwords.verify('test-password', hashed)
    assert not passwords.verify('wrong-password', hashed)


def test_postgresql_metadata():
    assert len(Base.metadata.tables) == 16
    sql = str(CreateTable(Base.metadata.tables['phieu_dat_phong']).compile(dialect=postgresql.dialect()))
    assert 'EXCLUDE USING gist' in sql and 'daterange' in sql


def test_configuration_rejects_sqlite_and_placeholder():
    with pytest.raises(ValidationError):
        Settings(database_url='sqlite:///test.db', jwt_secret='x' * 40)
    with pytest.raises(ValidationError):
        Settings(database_url='postgresql+psycopg://a:b@localhost/db', jwt_secret='')


def test_expired_jwt():
    token = jwt.encode({'sub': 'test', 'iat': datetime.now(timezone.utc) - timedelta(hours=2),
        'exp': datetime.now(timezone.utc) - timedelta(hours=1)}, settings().jwt_secret, algorithm='HS256')
    with pytest.raises(jwt.ExpiredSignatureError):
        jwt.decode(token, settings().jwt_secret, algorithms=['HS256'])

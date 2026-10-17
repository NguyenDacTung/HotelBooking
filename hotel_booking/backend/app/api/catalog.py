from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, exists
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models import Room, RoomType, Booking, Closure, HOLD, Amenity, TypeAmenity, RoomImage
from app.schemas.requests import Stay
from app.services.bookings import get_or_404, check_room
from app.services.rules import validate_stay
from app.services.rules import today
from app.core.errors import fail

router = APIRouter(tags=['Phòng'])


def page_result(db, query, page, page_size, serialize):
    total = db.scalar(select(func.count()).select_from(query.order_by(None).subquery()))
    return {'items': [serialize(row) for row in db.scalars(query.offset((page - 1) * page_size).limit(page_size))],
            'page': page, 'page_size': page_size, 'total': total}


def columns(obj):
    # Only call for non-sensitive catalog models, never Account.
    from decimal import Decimal
    return {c.name: int(v) if isinstance(v := getattr(obj, c.name), Decimal) and c.type.scale == 0 else v
            for c in obj.__table__.columns}


def type_out(db, kind):
    data = columns(kind)
    data['tien_nghi'] = [columns(a) for a in db.scalars(select(Amenity).join(TypeAmenity).where(TypeAmenity.ma_lp == kind.ma_lp))]
    data['hinh_anh'] = [columns(i) for i in db.scalars(select(RoomImage).where(RoomImage.ma_lp == kind.ma_lp)
                        .order_by(RoomImage.la_anh_bia.desc(), RoomImage.thu_tu, RoomImage.ma_anh))]
    return data


def room_out(db, room, internal=False):
    data = type_out(db, db.get(RoomType, room.ma_lp))
    data.update({k: v for k, v in columns(room).items() if internal or k != 'ghi_chu'})
    occupied = db.scalar(select(exists().where(Booking.ma_phong == room.ma_phong,
        Booking.trang_thai.in_(HOLD), Booking.ngay_tra > today())))
    data['trang_thai_su_dung'] = 'DANG_SU_DUNG' if occupied else 'CON_TRONG'
    return data


def public_rooms():
    return select(Room).join(RoomType).where(Room.dang_kinh_doanh.is_(True), RoomType.dang_kinh_doanh.is_(True))


@router.get('/room-types')
def types(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    return page_result(db, select(RoomType).where(RoomType.dang_kinh_doanh.is_(True)).order_by(RoomType.ma_lp),
                       page, page_size, lambda x: type_out(db, x))


@router.get('/rooms')
def rooms(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    return page_result(db, public_rooms().order_by(RoomType.gia_co_ban, Room.ma_phong), page, page_size, lambda x: room_out(db, x))


@router.get('/rooms/available')
def available(ngay_nhan: date, ngay_tra: date, so_khach: int = Query(ge=1), ma_lp: int | None = None,
              gia_min: int | None = Query(None, ge=0), gia_max: int | None = Query(None, ge=0),
              page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    validate_stay(ngay_nhan, ngay_tra, so_khach)
    if gia_min is not None and gia_max is not None and gia_min > gia_max:
        fail(422, 'VALIDATION_ERROR', 'Khoảng giá không hợp lệ')
    query = public_rooms().where(RoomType.suc_chua >= so_khach,
        ~exists().where(Booking.ma_phong == Room.ma_phong, Booking.trang_thai.in_(HOLD),
                       Booking.ngay_nhan < ngay_tra, Booking.ngay_tra > ngay_nhan),
        ~exists().where(Closure.ma_phong == Room.ma_phong, Closure.dang_hieu_luc.is_(True),
                       Closure.tu_ngay < ngay_tra, Closure.den_ngay > ngay_nhan))
    if ma_lp is not None:
        query = query.where(Room.ma_lp == ma_lp)
    if gia_min is not None:
        query = query.where(RoomType.gia_co_ban >= gia_min)
    if gia_max is not None:
        query = query.where(RoomType.gia_co_ban <= gia_max)
    return page_result(db, query.order_by(RoomType.gia_co_ban, Room.ma_phong), page, page_size, lambda x: room_out(db, x))


@router.get('/rooms/recommended')
def recommended(ngay_nhan: date, ngay_tra: date, so_khach: int = Query(ge=1),
                page_size: int = Query(6, ge=1, le=12), db: Session = Depends(get_db)):
    validate_stay(ngay_nhan, ngay_tra, so_khach)
    query = public_rooms().where(RoomType.suc_chua >= so_khach,
        ~exists().where(Booking.ma_phong == Room.ma_phong, Booking.trang_thai.in_(HOLD),
                        Booking.ngay_tra > today()),
        ~exists().where(Closure.ma_phong == Room.ma_phong, Closure.dang_hieu_luc.is_(True),
                        Closure.tu_ngay < ngay_tra, Closure.den_ngay > ngay_nhan))
    return page_result(db, query.order_by(RoomType.gia_co_ban, Room.ma_phong),
                       1, page_size, lambda room: room_out(db, room))


@router.get('/rooms/{room_id}')
def detail(room_id: int, db: Session = Depends(get_db)):
    room = get_or_404(db, Room, room_id)
    if not room.dang_kinh_doanh or not db.get(RoomType, room.ma_lp).dang_kinh_doanh:
        fail(404, 'NOT_FOUND', 'Không tìm thấy phòng')
    return room_out(db, room)


@router.post('/rooms/{room_id}/quote')
def quote(room_id: int, data: Stay, db: Session = Depends(get_db)):
    room = get_or_404(db, Room, room_id)
    kind = db.get(RoomType, room.ma_lp)
    usable = check_room(db, room, kind, data)
    nights = (data.ngay_tra - data.ngay_nhan).days
    return {'ma_phong': room_id, **data.model_dump(), 'so_dem': nights,
            'don_gia_moi_dem': int(kind.gia_co_ban), 'tong_tien': int(kind.gia_co_ban * nights), 'kha_dung': usable}

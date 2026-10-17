from datetime import date
from io import BytesIO
from pathlib import Path
from uuid import uuid4
from fastapi import APIRouter, Depends, Query, UploadFile, File, Form, Response
from PIL import Image, UnidentifiedImageError
from sqlalchemy import select, delete, update
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import manager
from app.core.errors import fail
from app.core.config import settings
from app.models import RoomType, Room, Amenity, TypeAmenity, RoomImage, Closure, Booking, HOLD
from app.schemas.requests import (TypeCreate, TypePatch, RoomCreate, RoomPatch, AmenityCreate,
    AmenityPatch, AmenitySet, ClosureCreate, ClosurePatch, ImagePatch)
from app.services.bookings import get_or_404, lock_room, save_closure
from app.services.rules import today
from app.api.catalog import page_result, columns, type_out, room_out

router = APIRouter(prefix='/staff', tags=['Quản lý'], dependencies=[Depends(manager)])


def apply_values(obj, data, nullable=()):
    for key, value in data.model_dump(exclude_unset=True).items():
        if value is None and key not in nullable:
            fail(422, 'VALIDATION_ERROR', f'{key} không được null')
        setattr(obj, key, value)


@router.get('/room-types')
def types(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    return page_result(db, select(RoomType).order_by(RoomType.ma_lp), page, page_size, lambda x: type_out(db, x))


@router.post('/room-types', status_code=201)
def create_type(data: TypeCreate, db: Session = Depends(get_db)):
    obj = RoomType(**data.model_dump())
    db.add(obj)
    db.commit()
    return type_out(db, obj)


@router.patch('/room-types/{key}')
def patch_type(key: int, data: TypePatch, db: Session = Depends(get_db)):
    obj = get_or_404(db, RoomType, key, True)
    if data.suc_chua is not None and db.scalar(select(Booking.ma_pdp).join(Room).where(
        Room.ma_lp == key, Booking.trang_thai.in_(HOLD), Booking.ngay_tra > today(),
        Booking.so_khach > data.suc_chua).limit(1)):
        fail(409, 'STATE_CONFLICT', 'Sức chứa mới không phù hợp với phiếu đang giữ phòng')
    # No room locks after type lock: booking/room-edit lock room first, then type.
    apply_values(obj, data, ('mo_ta', 'dien_tich_m2', 'so_giuong'))
    db.commit()
    return type_out(db, obj)


@router.get('/rooms')
def rooms(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    return page_result(db, select(Room).order_by(Room.ma_phong), page, page_size, lambda x: room_out(db, x, True))


@router.post('/rooms', status_code=201)
def create_room(data: RoomCreate, db: Session = Depends(get_db)):
    get_or_404(db, RoomType, data.ma_lp)
    obj = Room(**data.model_dump())
    db.add(obj)
    db.commit()
    return room_out(db, obj, True)


@router.patch('/rooms/{key}')
def patch_room(key: int, data: RoomPatch, db: Session = Depends(get_db)):
    obj = lock_room(db, key)
    if data.ma_lp is not None and data.ma_lp != obj.ma_lp:
        if db.scalar(select(Booking.ma_pdp).where(Booking.ma_phong == key,
            Booking.trang_thai.in_(HOLD), Booking.ngay_tra > today()).limit(1)):
            fail(409, 'STATE_CONFLICT', 'Phòng đang có phiếu giữ chỗ, không thể đổi loại')
        if db.scalar(select(RoomType).where(RoomType.ma_lp == data.ma_lp).with_for_update(read=True)) is None:
            fail(404, 'NOT_FOUND', 'Không tìm thấy loại phòng')
    apply_values(obj, data, ('tang', 'ghi_chu'))
    db.commit()
    return room_out(db, obj, True)


@router.get('/amenities')
def amenities(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    return page_result(db, select(Amenity).order_by(Amenity.ma_tn), page, page_size, columns)


@router.post('/amenities', status_code=201)
def create_amenity(data: AmenityCreate, db: Session = Depends(get_db)):
    obj = Amenity(**data.model_dump())
    db.add(obj)
    db.commit()
    return columns(obj)


@router.patch('/amenities/{key}')
def patch_amenity(key: int, data: AmenityPatch, db: Session = Depends(get_db)):
    obj = get_or_404(db, Amenity, key, True)
    apply_values(obj, data, ('bieu_tuong',))
    db.commit()
    return columns(obj)


@router.put('/room-types/{key}/amenities')
def set_amenities(key: int, data: AmenitySet, db: Session = Depends(get_db)):
    obj = get_or_404(db, RoomType, key, True)
    for amenity_id in data.ma_tn:
        get_or_404(db, Amenity, amenity_id)
    db.execute(delete(TypeAmenity).where(TypeAmenity.ma_lp == key))
    db.add_all([TypeAmenity(ma_lp=key, ma_tn=i) for i in data.ma_tn])
    db.commit()
    return type_out(db, obj)


@router.get('/room-closures')
def closures(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
             ma_phong: int | None = None, tu_ngay: date | None = None, den_ngay: date | None = None,
             db: Session = Depends(get_db)):
    query = select(Closure)
    if ma_phong is not None:
        query = query.where(Closure.ma_phong == ma_phong)
    if tu_ngay:
        query = query.where(Closure.den_ngay > tu_ngay)
    if den_ngay:
        query = query.where(Closure.tu_ngay < den_ngay)
    return page_result(db, query.order_by(Closure.tu_ngay, Closure.ma_ngung), page, page_size, columns)


@router.post('/room-closures', status_code=201)
def create_closure(data: ClosureCreate, user=Depends(manager), db: Session = Depends(get_db)):
    return columns(save_closure(db, user, data))


@router.patch('/room-closures/{key}')
def patch_closure(key: int, data: ClosurePatch, user=Depends(manager), db: Session = Depends(get_db)):
    if any(v is None for v in data.model_dump(exclude_unset=True).values()):
        fail(422, 'VALIDATION_ERROR', 'Không chấp nhận null')
    return columns(save_closure(db, user, data, key))


def cover(db, type_id, exclude=None):
    query = update(RoomImage).where(RoomImage.ma_lp == type_id, RoomImage.la_anh_bia.is_(True))
    if exclude:
        query = query.where(RoomImage.ma_anh != exclude)
    db.execute(query.values(la_anh_bia=False))
    db.flush()


@router.post('/room-types/{key}/images', status_code=201)
def upload(key: int, file: UploadFile = File(), thu_tu: int = Form(0, ge=0, le=32767),
           la_anh_bia: bool = Form(False), db: Session = Depends(get_db)):
    raw = file.file.read(5 * 1024 * 1024 + 1)
    if len(raw) > 5 * 1024 * 1024:
        fail(422, 'VALIDATION_ERROR', 'Ảnh tối đa 5 MiB')
    try:
        with Image.open(BytesIO(raw)) as image:
            extension = {'JPEG': '.jpg', 'PNG': '.png', 'WEBP': '.webp'}.get(image.format)
            if not extension or image.width * image.height > 25_000_000:
                raise ValueError()
            image.verify()
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        fail(422, 'VALIDATION_ERROR', 'Cần ảnh JPEG, PNG hoặc WebP hợp lệ')
    get_or_404(db, RoomType, key, True)
    if la_anh_bia:
        cover(db, key)
    directory = settings().upload_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    name = f'{uuid4()}{extension}'
    path = directory / name
    try:
        path.write_bytes(raw)
        obj = RoomImage(ma_lp=key, duong_dan=f'/uploads/{name}', thu_tu=thu_tu, la_anh_bia=la_anh_bia)
        db.add(obj)
        db.commit()
    except Exception:
        db.rollback()
        path.unlink(missing_ok=True)
        raise
    return columns(obj)


@router.patch('/images/{key}')
def patch_image(key: int, data: ImagePatch, db: Session = Depends(get_db)):
    initial = get_or_404(db, RoomImage, key)
    get_or_404(db, RoomType, initial.ma_lp, True)
    obj = get_or_404(db, RoomImage, key, True)
    if data.la_anh_bia:
        cover(db, obj.ma_lp, key)
    apply_values(obj, data)
    db.commit()
    return columns(obj)


@router.delete('/images/{key}', status_code=204)
def delete_image(key: int, db: Session = Depends(get_db)):
    initial = get_or_404(db, RoomImage, key)
    get_or_404(db, RoomType, initial.ma_lp, True)
    obj = get_or_404(db, RoomImage, key, True)
    directory = settings().upload_dir.resolve()
    name = obj.duong_dan.removeprefix('/uploads/')
    path = (directory / name).resolve()
    if path.parent != directory or not obj.duong_dan.startswith('/uploads/'):
        fail(400, 'INVALID_OPERATION', 'Đường dẫn ảnh không hợp lệ')
    # Keep DB record on filesystem errors so the operation can be retried.
    previous = path.read_bytes() if path.exists() else None
    try:
        path.unlink(missing_ok=True)
        db.delete(obj)
        db.commit()
    except Exception:
        db.rollback()
        if previous is not None:
            path.write_bytes(previous)
        raise
    return Response(status_code=204)

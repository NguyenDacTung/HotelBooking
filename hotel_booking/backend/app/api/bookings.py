from datetime import date
from uuid import UUID
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import current, customer, staff
from app.models import Booking
from app.schemas.requests import BookingCreate, Reason, Reject
from app.schemas.responses import booking_out
from app.services.bookings import create_booking, visible_booking, transition
from app.api.catalog import page_result

router = APIRouter(tags=['Đặt phòng'])


@router.post('/bookings', status_code=201)
def create(data: BookingCreate, user=Depends(customer), db: Session = Depends(get_db)):
    return booking_out(db, create_booking(db, user, data))


def listing(db, user, page, page_size, trang_thai, ngay_nhan_tu, ngay_nhan_den):
    query = select(Booking)
    if user['role'] == 'KHACH_HANG':
        query = query.where(Booking.ma_kh == user['account'].id)
    if trang_thai:
        query = query.where(Booking.trang_thai == trang_thai)
    if ngay_nhan_tu:
        query = query.where(Booking.ngay_nhan >= ngay_nhan_tu)
    if ngay_nhan_den:
        query = query.where(Booking.ngay_nhan <= ngay_nhan_den)
    return page_result(db, query.order_by(Booking.ngay_tao.desc(), Booking.ma_pdp), page, page_size, lambda x: booking_out(db, x))


@router.get('/bookings/my')
def mine(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
         trang_thai: str | None = Query(None, pattern='^(CHO_XAC_NHAN|DA_XAC_NHAN|DA_HUY|DA_TU_CHOI)$'),
         ngay_nhan_tu: date | None = None, ngay_nhan_den: date | None = None,
         user=Depends(customer), db: Session = Depends(get_db)):
    return listing(db, user, page, page_size, trang_thai, ngay_nhan_tu, ngay_nhan_den)


@router.get('/staff/bookings')
def all_bookings(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
         trang_thai: str | None = Query(None, pattern='^(CHO_XAC_NHAN|DA_XAC_NHAN|DA_HUY|DA_TU_CHOI)$'),
         ngay_nhan_tu: date | None = None, ngay_nhan_den: date | None = None,
         user=Depends(staff), db: Session = Depends(get_db)):
    return listing(db, user, page, page_size, trang_thai, ngay_nhan_tu, ngay_nhan_den)


@router.get('/bookings/{booking_id}')
def detail(booking_id: UUID, user=Depends(current), db: Session = Depends(get_db)):
    return booking_out(db, visible_booking(db, booking_id, user), True)


@router.patch('/bookings/{booking_id}/cancel')
def cancel(booking_id: UUID, data: Reason, user=Depends(customer), db: Session = Depends(get_db)):
    return booking_out(db, transition(db, booking_id, user, 'cancel', data.ly_do), True)


@router.patch('/staff/bookings/{booking_id}/confirm')
def confirm(booking_id: UUID, user=Depends(staff), db: Session = Depends(get_db)):
    return booking_out(db, transition(db, booking_id, user, 'confirm'), True)


@router.patch('/staff/bookings/{booking_id}/reject')
def reject(booking_id: UUID, data: Reject, user=Depends(staff), db: Session = Depends(get_db)):
    return booking_out(db, transition(db, booking_id, user, 'reject', data.ly_do), True)

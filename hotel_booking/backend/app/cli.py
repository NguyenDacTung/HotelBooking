"""Explicit, repeatable development seed and trusted staff provisioning."""
import argparse
import os
from dotenv import dotenv_values
from datetime import timedelta, datetime, timezone
from getpass import getpass
from pathlib import Path
from sqlalchemy import select
from sqlalchemy.orm import Session
from PIL import Image, ImageDraw
from app.db.session import engine
from app.models import (Account, Customer, Staff, Role, RoomType, Room, Amenity,
    TypeAmenity, RoomImage, Booking, History, Closure)
from app.core.security import passwords
from app.core.config import settings
from app.services.rules import today


def account(db, email, name, password, role=None):
    email = email.strip().lower()
    existing = db.scalar(select(Account).where(Account.email == email))
    if existing:
        if existing.loai_tai_khoan != ('NHAN_VIEN' if role else 'KHACH_HANG'):
            raise ValueError('Email thuộc loại tài khoản khác; không đổi quyền tự động')
        return existing
    obj = Account(email=email, mat_khau_bam=passwords.hash(password),
                  loai_tai_khoan='NHAN_VIEN' if role else 'KHACH_HANG')
    db.add(obj)
    db.flush()
    if role:
        job = db.scalar(select(Role).where(Role.ma_quyen == role))
        db.add(Staff(id=obj.id, ho_ten=name, ma_cv=job.ma_cv))
    else:
        db.add(Customer(id=obj.id, ho_ten=name, so_dien_thoai='0900000000'))
    db.flush()
    return obj


def roles(db):
    for code, name in [('LE_TAN', 'Lễ tân'), ('QUAN_LY', 'Quản lý')]:
        if not db.scalar(select(Role).where(Role.ma_quyen == code)):
            db.add(Role(ma_quyen=code, ten_chuc_vu=name))
    db.flush()


def seed(db, password):
    roles(db)
    customers = [account(db, f'khach{i}@example.com', f'Khách mẫu {i}', password) for i in range(1, 4)]
    receptionist = account(db, 'letan@example.com', 'Lễ tân mẫu', password, 'LE_TAN')
    manager = account(db, 'quanly@example.com', 'Quản lý mẫu', password, 'QUAN_LY')
    amenities = []
    for name in ['Wi-Fi', 'Điều hòa', 'TV', 'Minibar', 'Ban công', 'Bồn tắm']:
        amenity = db.scalar(select(Amenity).where(Amenity.ten_tien_nghi == name))
        if not amenity:
            amenity = Amenity(ten_tien_nghi=name)
            db.add(amenity)
            db.flush()
        amenities.append(amenity)
    rooms = []
    for index, (name, price, capacity) in enumerate([('Standard', 500000, 2), ('Deluxe', 850000, 2), ('Family', 1200000, 4)]):
        kind = db.scalar(select(RoomType).where(RoomType.ten_loai == name))
        if not kind:
            kind = RoomType(ten_loai=name, gia_co_ban=price, suc_chua=capacity,
                mo_ta='Phòng minh họa cho đồ án, không phải khách sạn đã khảo sát.', dien_tich_m2=24 + index * 10, so_giuong=1 + index)
            db.add(kind)
            db.flush()
        for amenity in amenities[:4 + index]:
            if not db.get(TypeAmenity, (kind.ma_lp, amenity.ma_tn)):
                db.add(TypeAmenity(ma_lp=kind.ma_lp, ma_tn=amenity.ma_tn))
        directory = settings().upload_dir
        directory.mkdir(parents=True, exist_ok=True)
        for image_index in range(2):
            path = f'/uploads/demo-{name.lower()}-{image_index}.png'
            if not db.scalar(select(RoomImage).where(RoomImage.duong_dan == path)):
                image = Image.new('RGB', (800, 450), (30 + index * 20, 90, 100 + image_index * 30))
                ImageDraw.Draw(image).text((60, 200), f'DEMO PLACEHOLDER - {name} {image_index + 1}', fill='white')
                image.save(directory / Path(path).name)
                has_cover = db.scalar(select(RoomImage.ma_anh).where(RoomImage.ma_lp == kind.ma_lp, RoomImage.la_anh_bia.is_(True)))
                db.add(RoomImage(ma_lp=kind.ma_lp, duong_dan=path, la_anh_bia=image_index == 0 and not has_cover, thu_tu=image_index))
                db.flush()
        for room_index in range(4):
            number = str((index + 1) * 100 + room_index + 1)
            room = db.scalar(select(Room).where(Room.so_phong == number))
            if not room:
                room = Room(so_phong=number, ma_lp=kind.ma_lp, tang=index + 1)
                db.add(room)
                db.flush()
            rooms.append(room)
    db.flush()
    # Markers make repeated seed runs idempotent; do not rewrite old dates/history.
    for i, state in enumerate(['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DA_HUY', 'DA_TU_CHOI', 'CHO_XAC_NHAN', 'DA_XAC_NHAN']):
        marker = f'DEMO_SEED_BOOKING_{i}'
        if db.scalar(select(Booking.ma_pdp).where(Booking.ghi_chu == marker)):
            continue
        room = db.scalar(select(Room).where(Room.ma_phong == rooms[i].ma_phong).with_for_update())
        kind = db.get(RoomType, room.ma_lp)
        arrival = today() + timedelta(days=10 + i * 3)
        # Never overwrite real schedules if seed is run on a nonempty development DB.
        from app.services.bookings import conflict
        if conflict(db, room.ma_phong, arrival, arrival + timedelta(days=2)):
            raise ValueError('Seed gặp lịch đã có. Dùng database demo riêng; không reset tự động.')
        booking = Booking(ma_kh=customers[i % 3].id, ma_phong=room.ma_phong, ngay_nhan=arrival,
            ngay_tra=arrival + timedelta(days=2), so_khach=2, don_gia_moi_dem=kind.gia_co_ban,
            tong_tien=kind.gia_co_ban * 2, trang_thai=state, ten_lien_he=f'Khách mẫu {i % 3 + 1}',
            sdt_lien_he='0900000000', ghi_chu=marker,
            ly_do_tu_choi='Demo: bảo trì theo yêu cầu' if state == 'DA_TU_CHOI' else None,
            nhan_vien_xu_ly=receptionist.id if state in ('DA_XAC_NHAN','DA_TU_CHOI') else None,
            ngay_xu_ly=datetime.now(timezone.utc) if state in ('DA_XAC_NHAN','DA_TU_CHOI') else None)
        db.add(booking)
        db.flush()
        db.add(History(ma_pdp=booking.ma_pdp, den_trang_thai='CHO_XAC_NHAN', nguoi_thuc_hien=booking.ma_kh))
        if state != 'CHO_XAC_NHAN':
            db.add(History(ma_pdp=booking.ma_pdp, tu_trang_thai='CHO_XAC_NHAN', den_trang_thai=state,
                nguoi_thuc_hien=booking.ma_kh if state == 'DA_HUY' else receptionist.id,
                ly_do=booking.ly_do_tu_choi))
    for i in range(2):
        marker = f'DEMO_SEED_CLOSURE_{i}'
        if not db.scalar(select(Closure.ma_ngung).where(Closure.ly_do == marker)):
            from app.services.bookings import conflict
            room_id = rooms[10 + i].ma_phong
            db.scalar(select(Room).where(Room.ma_phong == room_id).with_for_update())
            start = today() + timedelta(days=5)
            if conflict(db, room_id, start, start + timedelta(days=2)):
                raise ValueError('Seed gặp lịch đã có')
            db.add(Closure(ma_phong=room_id, tu_ngay=start, den_ngay=start + timedelta(days=2), ly_do=marker, nguoi_tao=manager.id))
    db.commit()


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('seed')
    staff = sub.add_parser('create-staff')
    staff.add_argument('--email', required=True)
    staff.add_argument('--name', required=True)
    staff.add_argument('--role', choices=['LE_TAN', 'QUAN_LY'], required=True)
    args = parser.parse_args()
    password = (os.environ.get('DEMO_PASSWORD') or dotenv_values('.env').get('DEMO_PASSWORD')) if args.command == 'seed' else None
    password = password or getpass('Mật khẩu (8–128 ký tự): ')
    if not 8 <= len(password) <= 128:
        parser.error('Mật khẩu cần 8–128 ký tự')
    with Session(engine(), expire_on_commit=False) as db:
        if args.command == 'seed':
            seed(db, password)
        else:
            roles(db)
            account(db, args.email, args.name, password, args.role)
            db.commit()
    print('Đã hoàn tất. Không thay mật khẩu hoặc dữ liệu đã tồn tại.')


if __name__ == '__main__':
    main()

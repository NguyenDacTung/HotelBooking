"""Explicit catalog upgrade. No bookings/accounts/payments are removed or rewritten."""
from pathlib import Path
import shutil
from sqlalchemy import select, text
from sqlalchemy.orm import Session
from app.db.session import engine
from app.core.config import settings
from app.models import RoomType,Room,RoomImage,Amenity,TypeAmenity

CATALOG=[
 ('Standard Single',450000,1,18,1,'Phòng một giường dành cho khách đi một mình, có bàn làm việc và phòng tắm riêng.'),
 ('Standard Double',550000,2,24,1,'Một giường đôi, phòng tắm riêng và bàn làm việc.'),
 ('Standard Twin',550000,2,24,2,'Hai giường đơn, phù hợp bạn bè hoặc đồng nghiệp.'),
 ('Superior Double',700000,2,28,1,'Một giường đôi, không gian rộng và khu vực làm việc.'),
 ('Superior Twin',700000,2,28,2,'Hai giường đơn, không gian nghỉ ngơi thoáng rộng.'),
 ('Deluxe King',950000,2,34,1,'Một giường king, khu vực tiếp khách và phòng tắm riêng.'),
 ('Deluxe Twin',950000,2,34,2,'Hai giường đơn lớn, có khu vực thư giãn.'),
 ('Family Quad',1350000,4,42,2,'Hai giường đôi, phù hợp gia đình bốn người.'),
 ('Junior Suite',1700000,2,48,1,'Giường king cùng khu vực tiếp khách rộng.'),
 ('Executive Suite',2300000,2,64,1,'Phòng ngủ giường king và phòng khách riêng.'),
]

def seed(db,replace_images=False):
    # Serialize repeat invocations and keep catalogs unique.
    db.execute(text("SELECT pg_advisory_xact_lock(hashtextextended('tttp-catalog-upgrade-v1',0))"))
    for index,(name,price,capacity,area,beds,description) in enumerate(CATALOG):
        kind=db.scalar(select(RoomType).where(RoomType.ten_loai==name))
        if not kind:
            kind=RoomType(ten_loai=name,gia_co_ban=price,suc_chua=capacity,dien_tich_m2=area,so_giuong=beds,mo_ta=description)
            db.add(kind);db.flush()
        for amenity_name in ('Wi-Fi','Điều hòa','TV','Minibar'):
            amenity=db.scalar(select(Amenity).where(Amenity.ten_tien_nghi==amenity_name))
            if not amenity:amenity=Amenity(ten_tien_nghi=amenity_name);db.add(amenity);db.flush()
            if not db.get(TypeAmenity,(kind.ma_lp,amenity.ma_tn)):db.add(TypeAmenity(ma_lp=kind.ma_lp,ma_tn=amenity.ma_tn))
        number=str((5+index//5)*100+1+index%5)
        if not db.scalar(select(Room).where(Room.so_phong==number)):
            db.add(Room(so_phong=number,ma_lp=kind.ma_lp,tang=5+index//5))
    for kind in db.scalars(select(RoomType)):
        if kind.mo_ta and ('đồ án' in kind.mo_ta or 'không phải khách sạn' in kind.mo_ta):
            kind.mo_ta='Phòng nghỉ có điều hòa, Wi-Fi, TV và phòng tắm riêng.'
    db.flush()
    root=Path(__file__).resolve().parents[2]
    double_photos=[root/'assets/images/auth-hotel.jpg',root/'assets/room_photos/pexels-271618.jpg',root/'assets/room_photos/pexels-271619.jpg']
    twin_photos=[root/'assets/room_photos/pexels-2029722.jpg',root/'assets/room_photos/pexels-29000012.jpg']
    family_photos=[root/'assets/room_photos/pexels-34763215.jpg']
    suite_photos=[root/'assets/room_photos/pexels-262048.jpg',root/'assets/images/banner-deluxe.jpg']
    directory=settings().upload_dir.resolve();directory.mkdir(parents=True,exist_ok=True)
    if replace_images:
        # Metadata archive + untouched original files allow recovery of replaced images.
        db.execute(text('CREATE TABLE IF NOT EXISTS anh_phong_archive (LIKE anh_phong INCLUDING DEFAULTS)'))
    for room in db.scalars(select(Room).order_by(Room.ma_phong)):
        current=db.scalars(select(RoomImage).where(RoomImage.ma_phong==room.ma_phong)).all()
        if current and not replace_images:continue
        if any(i.duong_dan.startswith('/uploads/tttp-photo-v1-') for i in current):continue
        if replace_images and current:
            db.execute(text('INSERT INTO anh_phong_archive SELECT * FROM anh_phong WHERE ma_phong=:room'),{'room':room.ma_phong})
            for image in current:db.delete(image)
            db.flush()
        kind=db.get(RoomType,room.ma_lp)
        photos=twin_photos if 'Twin' in kind.ten_loai else family_photos if 'Family' in kind.ten_loai else suite_photos if 'Suite' in kind.ten_loai or 'Deluxe' in kind.ten_loai else double_photos
        for n in range(2):
            if n>=len(photos):break
            source=photos[(room.ma_phong+n)%len(photos)]
            filename=f'tttp-photo-v1-{room.ma_phong}-{n}.jpg'
            shutil.copyfile(source,directory/filename)
            db.add(RoomImage(ma_phong=room.ma_phong,duong_dan='/uploads/'+filename,la_anh_bia=n==0,thu_tu=n))
    db.commit()

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--replace-room-images',action='store_true');args=parser.parse_args()
    with Session(engine(),expire_on_commit=False) as db:seed(db,args.replace_room_images)
    print('Catalog upgraded idempotently; original financial/booking/account records preserved.')

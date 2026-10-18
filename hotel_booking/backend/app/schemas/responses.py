from datetime import date, datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, computed_field


class ProfileOut(BaseModel):
    id: UUID
    email: str | None
    ho_ten: str
    so_dien_thoai: str | None = None
    avatar_url: str | None = None
    loai_tai_khoan: str
    ma_quyen: str


class BookingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    ma_pdp: UUID
    ma_kh: UUID
    ma_phong: int
    so_phong: str = ''
    ngay_nhan: date
    ngay_tra: date
    so_khach: int
    don_gia_moi_dem: int
    tong_tien: int
    trang_thai: str
    ten_lien_he: str
    sdt_lien_he: str
    ghi_chu: str | None
    ly_do_tu_choi: str | None
    ngay_tao: datetime
    ngay_cap_nhat: datetime
    ngay_xu_ly: datetime | None

    @computed_field
    @property
    def so_dem(self) -> int:
        return (self.ngay_tra - self.ngay_nhan).days


def profile_out(user):
    account, profile = user['account'], user['profile']
    return ProfileOut(id=account.id, email=account.email, ho_ten=profile.ho_ten,
        so_dien_thoai=getattr(profile, 'so_dien_thoai', None),
        avatar_url=account.avatar_url, loai_tai_khoan=account.loai_tai_khoan, ma_quyen=user['role'])


def booking_out(db, booking, history=False):
    from sqlalchemy import select
    from app.models import Room, History
    data = BookingOut.model_validate(booking).model_dump(mode='json')
    data['so_phong'] = db.get(Room, booking.ma_phong).so_phong
    from app.services.payments import balance
    data.update(balance(db, booking))
    data['chinh_sach']=booking.chinh_sach
    for field in ('nhan_phong_luc','tra_phong_luc','yeu_cau_tra_luc','giu_cho_den'):
        value=getattr(booking,field);data[field]=value.isoformat() if value else None
    if history:
        from app.models import Charge,Audit
        from app.api.catalog import columns
        data['phu_thu']=[columns(c) for c in db.scalars(select(Charge).where(Charge.ma_pdp==booking.ma_pdp).order_by(Charge.ngay_tao))]
        data['nhat_ky']=[{'hanh_dong':a.action,'ly_do':a.ly_do,'thoi_diem':a.thoi_diem.isoformat()} for a in db.scalars(select(Audit).where(Audit.entity=='booking',Audit.entity_id==str(booking.ma_pdp)).order_by(Audit.id))]
    if history:
        data['lich_su'] = [{'tu_trang_thai': h.tu_trang_thai, 'den_trang_thai': h.den_trang_thai,
            'ly_do': h.ly_do, 'thoi_diem': h.thoi_diem, 'nguoi_thuc_hien': str(h.nguoi_thuc_hien)}
            for h in db.scalars(select(History).where(History.ma_pdp == booking.ma_pdp)
                                .order_by(History.thoi_diem, History.ma_ls))]
    return data

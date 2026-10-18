import uuid
from datetime import date, datetime
from decimal import Decimal
from sqlalchemy import (BigInteger, Boolean, CheckConstraint, Date, DateTime,
                        ForeignKey, Identity as IdentityColumn, Index, Numeric, SmallInteger,
                        String, Text, text)
from sqlalchemy.dialects.postgresql import UUID, ExcludeConstraint, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.db.session import Base


def pk():
    return mapped_column(BigInteger, IdentityColumn(), primary_key=True)


def stamp():
    return mapped_column(DateTime(timezone=True), server_default=text('now()'), nullable=False)


def flag(default=True):
    return mapped_column(Boolean, server_default=text('true' if default else 'false'), nullable=False)


class Account(Base):
    __tablename__ = 'tai_khoan'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str | None] = mapped_column(String(254), unique=True)
    mat_khau_bam: Mapped[str | None] = mapped_column(Text)
    dang_nhap_noi_bo: Mapped[bool] = flag()
    token_version: Mapped[int] = mapped_column(server_default='0')
    loai_tai_khoan: Mapped[str] = mapped_column(String(20))
    dang_hoat_dong: Mapped[bool] = flag()
    ngay_tao: Mapped[datetime] = stamp()
    avatar_url: Mapped[str | None] = mapped_column(Text)
    __table_args__ = (CheckConstraint("email = lower(trim(email))"),
                      CheckConstraint("loai_tai_khoan IN ('KHACH_HANG','NHAN_VIEN')"))


class BiometricDevice(Base):
    __tablename__ = 'thiet_bi_sinh_trac'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    public_key: Mapped[str] = mapped_column(Text)
    token_version: Mapped[int] = mapped_column()
    active: Mapped[bool] = flag(False)
    revoked: Mapped[bool] = flag(False)
    het_han: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ngay_tao: Mapped[datetime] = stamp()


class BiometricChallenge(Base):
    __tablename__ = 'thu_thach_sinh_trac'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('thiet_bi_sinh_trac.id'), index=True)
    message: Mapped[str] = mapped_column(Text)
    purpose: Mapped[str] = mapped_column(String(10))
    used: Mapped[bool] = flag(False)
    het_han: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    __table_args__ = (CheckConstraint("purpose IN ('ENROLL','LOGIN')"),)


class Role(Base):
    __tablename__ = 'chuc_vu'
    ma_cv: Mapped[int] = pk()
    ten_chuc_vu: Mapped[str] = mapped_column(String(80))
    ma_quyen: Mapped[str] = mapped_column(String(20), unique=True)
    dang_su_dung: Mapped[bool] = flag()
    __table_args__ = (CheckConstraint("ma_quyen IN ('LE_TAN','QUAN_LY')"),)


class Customer(Base):
    __tablename__ = 'khach_hang'
    id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), primary_key=True)
    ho_ten: Mapped[str] = mapped_column(String(120))
    so_dien_thoai: Mapped[str | None] = mapped_column(String(20))
    ngay_tao: Mapped[datetime] = stamp()


class Staff(Base):
    __tablename__ = 'nhan_vien'
    id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), primary_key=True)
    ho_ten: Mapped[str] = mapped_column(String(120))
    ma_cv: Mapped[int] = mapped_column(ForeignKey('chuc_vu.ma_cv'), index=True)
    dang_hoat_dong: Mapped[bool] = flag()
    ngay_tao: Mapped[datetime] = stamp()


class RoomType(Base):
    __tablename__ = 'loai_phong'
    ma_lp: Mapped[int] = pk()
    ten_loai: Mapped[str] = mapped_column(String(100), unique=True)
    mo_ta: Mapped[str | None] = mapped_column(Text)
    gia_co_ban: Mapped[Decimal] = mapped_column(Numeric(12, 0))
    suc_chua: Mapped[int] = mapped_column(SmallInteger)
    dien_tich_m2: Mapped[Decimal | None] = mapped_column(Numeric(6, 1))
    so_giuong: Mapped[int | None] = mapped_column(SmallInteger)
    dang_kinh_doanh: Mapped[bool] = flag()

    __table_args__ = (CheckConstraint('gia_co_ban >= 0'), CheckConstraint('suc_chua > 0'),
                      CheckConstraint('dien_tich_m2 > 0'), CheckConstraint('so_giuong > 0'))


class Room(Base):
    __tablename__ = 'phong'
    ma_phong: Mapped[int] = pk()
    so_phong: Mapped[str] = mapped_column(String(20), unique=True)
    ma_lp: Mapped[int] = mapped_column(ForeignKey('loai_phong.ma_lp'), index=True)
    tang: Mapped[int | None] = mapped_column(SmallInteger)
    ghi_chu: Mapped[str | None] = mapped_column(Text)
    dang_kinh_doanh: Mapped[bool] = flag()
    tinh_trang_van_hanh: Mapped[str] = mapped_column(String(20), server_default='SAN_SANG')


class Amenity(Base):
    __tablename__ = 'tien_nghi'
    ma_tn: Mapped[int] = pk()
    ten_tien_nghi: Mapped[str] = mapped_column(String(100), unique=True)
    bieu_tuong: Mapped[str | None] = mapped_column(String(80))


class TypeAmenity(Base):
    __tablename__ = 'loai_phong_tien_nghi'
    ma_lp: Mapped[int] = mapped_column(ForeignKey('loai_phong.ma_lp'), primary_key=True)
    ma_tn: Mapped[int] = mapped_column(ForeignKey('tien_nghi.ma_tn'), primary_key=True, index=True)


class RoomImage(Base):
    __tablename__ = 'anh_phong'
    ma_anh: Mapped[int] = pk()
    ma_phong: Mapped[int] = mapped_column(ForeignKey('phong.ma_phong'), index=True)
    duong_dan: Mapped[str] = mapped_column(Text)
    la_anh_bia: Mapped[bool] = flag(False)
    thu_tu: Mapped[int] = mapped_column(SmallInteger, server_default='0')
    __table_args__ = (CheckConstraint('thu_tu >= 0'),
                      Index('uq_anh_phong_bia', 'ma_phong', unique=True, postgresql_where=text('la_anh_bia')))


HOLD = ('CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DANG_O', 'CHO_THANH_TOAN')
STATES = "('CHO_XAC_NHAN','DA_XAC_NHAN','DA_HUY','DA_TU_CHOI','DANG_O','CHO_THANH_TOAN','DA_HOAN_TAT','HET_HAN','KHONG_DEN')"


class Booking(Base):
    __tablename__ = 'phieu_dat_phong'
    ma_pdp: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ma_kh: Mapped[uuid.UUID] = mapped_column(ForeignKey('khach_hang.id'), index=True)
    ma_phong: Mapped[int] = mapped_column(ForeignKey('phong.ma_phong'), index=True)
    ngay_nhan: Mapped[date] = mapped_column(Date)
    ngay_tra: Mapped[date] = mapped_column(Date)
    so_khach: Mapped[int] = mapped_column(SmallInteger)
    don_gia_moi_dem: Mapped[Decimal] = mapped_column(Numeric(12, 0))
    tong_tien: Mapped[Decimal] = mapped_column(Numeric(14, 0))
    trang_thai: Mapped[str] = mapped_column(String(20), server_default='CHO_XAC_NHAN')
    ten_lien_he: Mapped[str] = mapped_column(String(120))
    sdt_lien_he: Mapped[str] = mapped_column(String(20))
    ghi_chu: Mapped[str | None] = mapped_column(Text)
    nhan_vien_xu_ly: Mapped[uuid.UUID | None] = mapped_column(ForeignKey('nhan_vien.id'), index=True)
    ly_do_tu_choi: Mapped[str | None] = mapped_column(Text)
    ngay_tao: Mapped[datetime] = stamp()
    ngay_cap_nhat: Mapped[datetime] = stamp()
    ngay_xu_ly: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    nhan_phong_luc: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    tra_phong_luc: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    yeu_cau_tra_luc: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    giu_cho_den: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    chinh_sach: Mapped[dict] = mapped_column(JSONB, server_default=text("'{}'::jsonb"))
    __table_args__ = (
        CheckConstraint('ngay_tra > ngay_nhan AND ngay_tra - ngay_nhan <= 30'),
        CheckConstraint('so_khach > 0'), CheckConstraint('don_gia_moi_dem >= 0'),
        CheckConstraint('tong_tien >= 0 AND tong_tien = don_gia_moi_dem * (ngay_tra - ngay_nhan)'),
        CheckConstraint('trang_thai IN ' + STATES),
        Index('ix_phieu_khach_ngay', 'ma_kh', 'ngay_tao'),
        Index('ix_phieu_trang_thai_ngay', 'trang_thai', 'ngay_tao'),
        ExcludeConstraint(('ma_phong', '='), (text("daterange(ngay_nhan, ngay_tra, '[)')"), '&&'),
                          where=text("trang_thai IN ('CHO_XAC_NHAN','DA_XAC_NHAN','DANG_O','CHO_THANH_TOAN')"), name='ex_phong_khong_trung'),
    )


class History(Base):
    __tablename__ = 'lich_su_dat_phong'
    ma_ls: Mapped[int] = pk()
    ma_pdp: Mapped[uuid.UUID] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'))
    tu_trang_thai: Mapped[str | None] = mapped_column(String(20))
    den_trang_thai: Mapped[str] = mapped_column(String(20))
    nguoi_thuc_hien: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    ly_do: Mapped[str | None] = mapped_column(Text)
    thoi_diem: Mapped[datetime] = stamp()
    __table_args__ = (CheckConstraint('tu_trang_thai IN ' + STATES),
                      CheckConstraint('den_trang_thai IN ' + STATES),
                      CheckConstraint("tu_trang_thai IS NOT NULL OR den_trang_thai = 'CHO_XAC_NHAN'"),
                      Index('ix_lich_su_phieu_ngay', 'ma_pdp', 'thoi_diem'))


class Closure(Base):
    __tablename__ = 'phong_tam_ngung'
    ma_ngung: Mapped[int] = pk()
    ma_phong: Mapped[int] = mapped_column(ForeignKey('phong.ma_phong'), index=True)
    tu_ngay: Mapped[date] = mapped_column(Date)
    den_ngay: Mapped[date] = mapped_column(Date)
    ly_do: Mapped[str] = mapped_column(Text)
    dang_hieu_luc: Mapped[bool] = flag()
    nguoi_tao: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    ngay_tao: Mapped[datetime] = stamp()
    __table_args__ = (CheckConstraint('den_ngay > tu_ngay'),
                      ExcludeConstraint(('ma_phong', '='), (text("daterange(tu_ngay, den_ngay, '[)')"), '&&'),
                                        where=text('dang_hieu_luc'), name='ex_ngung_khong_trung'))


from sqlalchemy.dialects.postgresql import JSONB


class Identity(Base):
    __tablename__ = 'danh_tinh_dang_nhap'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    provider: Mapped[str] = mapped_column(String(20))
    provider_subject: Mapped[str] = mapped_column(String(255))
    ngay_tao: Mapped[datetime] = stamp()
    __table_args__ = (Index('uq_identity_subject', 'provider', 'provider_subject', unique=True),
                      CheckConstraint("provider IN ('GOOGLE','FACEBOOK')"))


class Notification(Base):
    __tablename__ = 'thong_bao'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    loai_su_kien: Mapped[str] = mapped_column(String(40))
    tieu_de: Mapped[str] = mapped_column(String(150))
    noi_dung: Mapped[str] = mapped_column(Text)
    ma_pdp: Mapped[uuid.UUID | None] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'), index=True)
    ngay_tao: Mapped[datetime] = stamp()
    ngay_doc: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    event_key: Mapped[str] = mapped_column(String(255), unique=True)
    push_luc: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    push_attempts: Mapped[int] = mapped_column(server_default='0')
    push_retry_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Payment(Base):
    __tablename__ = 'giao_dich_thanh_toan'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ma_pdp: Mapped[uuid.UUID] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'), index=True)
    loai: Mapped[str] = mapped_column(String(10))
    so_tien: Mapped[Decimal] = mapped_column(Numeric(14, 0))
    phuong_thuc: Mapped[str] = mapped_column(String(20))
    environment: Mapped[str] = mapped_column(String(12),server_default='production')
    thoi_diem_giao_dich: Mapped[datetime] = stamp()
    nguoi_ghi_nhan: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    ghi_chu: Mapped[str | None] = mapped_column(Text)
    ma_tham_chieu: Mapped[str | None] = mapped_column(String(150))
    giao_dich_goc_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey('giao_dich_thanh_toan.id'), index=True)
    request_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True)
    ngay_tao: Mapped[datetime] = stamp()
    __table_args__ = (CheckConstraint('so_tien > 0'), CheckConstraint("loai IN ('THU','HOAN')"),
                      CheckConstraint("phuong_thuc IN ('TIEN_MAT','CHUYEN_KHOAN','MOMO','VNPAY')"),
                      CheckConstraint("(loai='THU' AND giao_dich_goc_id IS NULL) OR (loai='HOAN' AND giao_dich_goc_id IS NOT NULL)"))


class Audit(Base):
    __tablename__ = 'audit_log'
    id: Mapped[int] = pk()
    entity: Mapped[str] = mapped_column(String(40))
    entity_id: Mapped[str] = mapped_column(String(100), index=True)
    action: Mapped[str] = mapped_column(String(40))
    actor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    before: Mapped[dict | None] = mapped_column(JSONB)
    after: Mapped[dict | None] = mapped_column(JSONB)
    ly_do: Mapped[str] = mapped_column(Text)
    thoi_diem: Mapped[datetime] = stamp()


class Charge(Base):
    __tablename__ = 'phu_thu'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ma_pdp: Mapped[uuid.UUID] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'), index=True)
    loai: Mapped[str] = mapped_column(String(30))
    noi_dung: Mapped[str] = mapped_column(String(500))
    don_gia: Mapped[Decimal] = mapped_column(Numeric(14, 0))
    so_luong: Mapped[int] = mapped_column(SmallInteger, server_default='1')
    nguoi_tao: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'))
    ngay_tao: Mapped[datetime] = stamp()
    da_huy: Mapped[bool] = flag(False)
    request_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True)
    __table_args__ = (CheckConstraint('don_gia >= 0 AND so_luong > 0'),)


class ResetCode(Base):
    __tablename__ = 'khoi_phuc_mat_khau'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    ma_bam: Mapped[str] = mapped_column(String(64))
    het_han: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    da_dung: Mapped[bool] = flag(False)
    so_lan_sai: Mapped[int] = mapped_column(server_default='0')


class LoginAttempt(Base):
    __tablename__ = 'gioi_han_dang_nhap'
    khoa: Mapped[str] = mapped_column(String(64), primary_key=True)
    so_lan: Mapped[int] = mapped_column(server_default='0')
    bat_dau: Mapped[datetime] = stamp()


class DeviceToken(Base):
    __tablename__ = 'thiet_bi_thong_bao'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'), index=True)
    token: Mapped[str] = mapped_column(Text, unique=True)
    token_version: Mapped[int] = mapped_column(server_default='0')
    ngay_cap_nhat: Mapped[datetime] = stamp()


class Review(Base):
    __tablename__ = 'danh_gia'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ma_pdp: Mapped[uuid.UUID] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'), unique=True)
    so_sao: Mapped[int] = mapped_column(SmallInteger)
    nhan_xet: Mapped[str | None] = mapped_column(String(1000))
    hien_thi: Mapped[bool] = flag()
    ly_do_an: Mapped[str | None] = mapped_column(String(2000))
    ngay_tao: Mapped[datetime] = stamp()
    ngay_cap_nhat: Mapped[datetime] = stamp()
    __table_args__ = (CheckConstraint('so_sao BETWEEN 1 AND 5'),)


class ImportBatch(Base):
    __tablename__ = 'dot_nhap_phong'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nguoi_tao: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'))
    file_hash: Mapped[str] = mapped_column(String(64))
    du_lieu: Mapped[list] = mapped_column(JSONB)
    ngay_tao: Mapped[datetime] = stamp()
    da_nhap: Mapped[bool] = flag(False)


class Feedback(Base):
    __tablename__ = 'phan_hoi'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tai_khoan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey('tai_khoan.id'),index=True)
    noi_dung: Mapped[str] = mapped_column(String(4000))
    thiet_bi: Mapped[dict] = mapped_column(JSONB,server_default='{}')
    anh: Mapped[str | None] = mapped_column(Text)
    trang_thai: Mapped[str] = mapped_column(String(20),server_default='TIEP_NHAN')
    ngay_tao: Mapped[datetime] = stamp()
    __table_args__ = (CheckConstraint("trang_thai IN ('TIEP_NHAN','DANG_XU_LY','DA_XU_LY')"),)


class HotelSettings(Base):
    __tablename__ = 'cau_hinh_cong_khai'
    key: Mapped[str] = mapped_column(String(40),primary_key=True)
    value: Mapped[dict] = mapped_column(JSONB)


class PaymentAttempt(Base):
    __tablename__ = 'phien_thanh_toan'
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True),primary_key=True,default=uuid.uuid4)
    ma_pdp: Mapped[uuid.UUID] = mapped_column(ForeignKey('phieu_dat_phong.ma_pdp'),index=True)
    provider: Mapped[str] = mapped_column(String(10))
    environment: Mapped[str] = mapped_column(String(12))
    request_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True),unique=True)
    reference: Mapped[str] = mapped_column(String(80),unique=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14,0))
    state: Mapped[str] = mapped_column(String(24),server_default='CREATED')
    payment_url: Mapped[str | None] = mapped_column(Text)
    provider_transaction: Mapped[str | None] = mapped_column(String(100))
    ngay_tao: Mapped[datetime] = stamp()
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    __table_args__ = (CheckConstraint("provider IN ('MOMO','VNPAY')"),CheckConstraint('amount>0'),
        CheckConstraint("state IN ('CREATED','PENDING','SUCCEEDED','FAILED')",name='ck_attempt_state'),
        Index('uq_attempt_provider_transaction','provider','environment','provider_transaction',unique=True),
        Index('uq_payment_attempt_active','ma_pdp',unique=True,postgresql_where=text("state IN ('CREATED','PENDING')")),)

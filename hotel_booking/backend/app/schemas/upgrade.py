from datetime import date
from uuid import UUID
from typing import Literal
from pydantic import Field, EmailStr
from app.schemas.requests import Input, Name, Phone, Email


class AccountCreate(Input):
    email: Email
    ho_ten: Name
    mat_khau: str = Field(min_length=8, max_length=128)
    ma_quyen: Literal['LE_TAN','QUAN_LY']


class AccountEdit(Input):
    ho_ten: Name | None = None
    so_dien_thoai: Phone | None = None


class RoleEdit(Input):
    ma_quyen: Literal['LE_TAN','QUAN_LY']
    ly_do: str = Field(default='', max_length=2000)


class StatusEdit(Input):
    dang_hoat_dong: bool
    ly_do: str = Field(default='', max_length=2000)


class OperationEdit(Input):
    tinh_trang_van_hanh: Literal['SAN_SANG','CAN_DON_DEP','DANG_DON_DEP','BAO_TRI']
    ly_do: str = Field(default='', max_length=2000)
    tu_ngay: date | None = None
    den_ngay: date | None = None


class PaymentCreate(Input):
    request_id: UUID
    so_tien: int = Field(gt=0, le=99999999999999)
    phuong_thuc: Literal['TIEN_MAT','CHUYEN_KHOAN']
    ghi_chu: str | None = Field(default=None, max_length=2000)
    ma_tham_chieu: str | None = Field(default=None, max_length=150)


class RefundCreate(PaymentCreate):
    ghi_chu: str = Field(default='', max_length=2000)


class SocialCredential(Input):
    credential: str = Field(min_length=1, max_length=16000)


class PasswordChange(Input):
    mat_khau_cu: str | None = Field(default=None, max_length=128)
    mat_khau: str = Field(min_length=8, max_length=128)

from datetime import date
from typing import Annotated
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator, AfterValidator
from email_validator import validate_email, EmailNotValidError


def check_email(value):
    try:
        return validate_email(value,check_deliverability=False,test_environment=True).normalized.lower()
    except EmailNotValidError:
        raise ValueError('Email không hợp lệ')


Email = Annotated[str, AfterValidator(check_email)]

Name = Annotated[str, Field(min_length=1, max_length=120)]
Phone = Annotated[str, Field(min_length=1, max_length=20)]
Money = Annotated[int, Field(ge=0, le=999999999999)]


class Input(BaseModel):
    model_config = ConfigDict(extra='forbid')

    @field_validator('*', mode='before')
    @classmethod
    def trim(cls, value, info):
        return value.strip() if isinstance(value, str) and info.field_name not in ('mat_khau', 'mat_khau_cu') else value


class Login(Input):
    email: Email
    mat_khau: str = Field(min_length=1, max_length=128)

    @field_validator('email')
    @classmethod
    def normalize(cls, value):
        return value.lower()


class Register(Login):
    mat_khau: str = Field(min_length=8, max_length=128)
    ho_ten: Name
    so_dien_thoai: Phone | None = None


class ProfilePatch(Input):
    ho_ten: Name | None = None
    so_dien_thoai: Phone | None = None


class Stay(Input):
    ngay_nhan: date
    ngay_tra: date
    so_khach: int = Field(ge=1, le=32767)


class BookingCreate(Stay):
    ma_phong: int = Field(gt=0)
    ten_lien_he: Name
    sdt_lien_he: Phone
    ghi_chu: str | None = Field(default=None, max_length=2000)
    expected_don_gia_moi_dem: Money | None = None


class Reason(Input):
    ly_do: str | None = Field(default=None, max_length=2000)


class Reject(Input):
    ly_do: str = Field(min_length=1, max_length=2000)


class TypeCreate(Input):
    ten_loai: Annotated[str, Field(min_length=1, max_length=100)]
    mo_ta: str | None = None
    gia_co_ban: Money
    suc_chua: int = Field(gt=0, le=32767)
    dien_tich_m2: float | None = Field(default=None, gt=0, le=99999.9)
    so_giuong: int | None = Field(default=None, gt=0, le=32767)
    dang_kinh_doanh: bool = True


class TypePatch(Input):
    ten_loai: Annotated[str, Field(min_length=1, max_length=100)] | None = None
    mo_ta: str | None = None
    gia_co_ban: Money | None = None
    suc_chua: int | None = Field(default=None, gt=0, le=32767)
    dien_tich_m2: float | None = Field(default=None, gt=0, le=99999.9)
    so_giuong: int | None = Field(default=None, gt=0, le=32767)
    dang_kinh_doanh: bool | None = None


class RoomCreate(Input):
    so_phong: Annotated[str, Field(min_length=1, max_length=20)]
    ma_lp: int = Field(gt=0)
    tang: int | None = Field(default=None, ge=-32768, le=32767)
    ghi_chu: str | None = None
    dang_kinh_doanh: bool = True


class RoomPatch(Input):
    so_phong: Annotated[str, Field(min_length=1, max_length=20)] | None = None
    ma_lp: int | None = Field(default=None, gt=0)
    tang: int | None = Field(default=None, ge=-32768, le=32767)
    ghi_chu: str | None = None
    dang_kinh_doanh: bool | None = None


class AmenityCreate(Input):
    ten_tien_nghi: Annotated[str, Field(min_length=1, max_length=100)]
    bieu_tuong: str | None = Field(default=None, max_length=80)


class AmenityPatch(Input):
    ten_tien_nghi: Annotated[str, Field(min_length=1, max_length=100)] | None = None
    bieu_tuong: str | None = Field(default=None, max_length=80)


class AmenitySet(Input):
    ma_tn: list[Annotated[int, Field(gt=0)]]

    @model_validator(mode='after')
    def unique(self):
        if len(self.ma_tn) != len(set(self.ma_tn)):
            raise ValueError('Tiện nghi bị lặp')
        return self


class ClosureCreate(Input):
    ma_phong: int = Field(gt=0)
    tu_ngay: date
    den_ngay: date
    ly_do: str = Field(min_length=1, max_length=2000)
    dang_hieu_luc: bool = True


class ClosurePatch(Input):
    tu_ngay: date | None = None
    den_ngay: date | None = None
    ly_do: str | None = Field(default=None, min_length=1, max_length=2000)
    dang_hieu_luc: bool | None = None


class ImagePatch(Input):
    thu_tu: int | None = Field(default=None, ge=0, le=32767)
    la_anh_bia: bool | None = None

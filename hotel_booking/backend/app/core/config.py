from functools import lru_cache
from pathlib import Path
from pydantic import Field, field_validator, model_validator
from sqlalchemy import URL
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', extra='ignore')
    database_url: str | None = None
    db_host: str = '127.0.0.1'
    db_port: int = 5432
    db_user: str = 'postgres'
    db_password: str = ''
    db_name: str = 'hotel_booking'
    jwt_secret: str
    access_token_expire_minutes: int = 60
    upload_dir: Path = Path('uploads')
    google_client_id: str = ''
    facebook_app_id: str = ''
    facebook_app_secret: str = ''
    facebook_graph_version: str = 'v24.0'
    report_font_path: Path = Path('C:/Windows/Fonts/arial.ttf')
    checkin_hour: int = Field(14, ge=6, le=23)
    checkout_hour: int = Field(12, ge=0, le=14)
    hold_hours: int = Field(24, ge=1, le=168)
    extra_bed_price: int = Field(250000, ge=0, le=100000000)
    smtp_host: str = ''
    smtp_port: int = 587
    smtp_user: str = ''
    smtp_password: str = ''
    smtp_from: str = ''
    smtp_starttls: bool = True
    firebase_project_id: str = ''
    firebase_credentials: str = ''
    private_upload_dir: Path = Path('private_uploads')
    payment_environment: str = 'sandbox'
    payment_public_base_url: str = ''
    momo_partner_code: str = ''
    momo_access_key: str = ''
    momo_secret_key: str = ''
    momo_endpoint: str = 'https://test-payment.momo.vn/v2/gateway/api'
    vnpay_tmn_code: str = ''
    vnpay_hash_secret: str = ''
    vnpay_payment_url: str = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'
    vnpay_query_url: str = 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction'
    persistent_media_enabled: bool = True

    @field_validator('database_url')
    @classmethod
    def postgres_only(cls, value):
        if value is None:
            return value
        if not value.startswith('postgresql+psycopg://'):
            raise ValueError('DATABASE_URL phải dùng PostgreSQL và psycopg')
        return value

    @model_validator(mode='after')
    def build_database_url(self):
        if self.database_url is None:
            self.database_url = URL.create('postgresql+psycopg', username=self.db_user,
                password=self.db_password, host=self.db_host, port=self.db_port,
                database=self.db_name).render_as_string(hide_password=False)
        return self

    @field_validator('jwt_secret')
    @classmethod
    def strong_secret(cls, value):
        if len(value) < 32 or value.startswith('replace-'):
            raise ValueError('JWT_SECRET cần ít nhất 32 ký tự ngẫu nhiên')
        return value


@lru_cache
def settings():
    return Settings()

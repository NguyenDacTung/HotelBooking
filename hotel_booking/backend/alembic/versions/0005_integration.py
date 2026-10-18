"""Reviews, integration metadata and optional reasons; retain all existing records."""
from alembic import op
from sqlalchemy import text
revision='0005'
down_revision='0004'

def upgrade():
    conn=op.get_bind()
    op.execute('ALTER TABLE tai_khoan ADD COLUMN avatar_url text')
    # Original generated CHECK names differ per PostgreSQL version.
    for table,needle in [('phieu_dat_phong','ly_do_tu_choi'),('phong_tam_ngung','ly_do')]:
        for name,definition in conn.execute(text("SELECT conname,pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=cast(:t AS regclass) AND contype='c'"),{'t':table}):
            if needle in definition:op.execute(f'ALTER TABLE {table} DROP CONSTRAINT "{name}"')
    from app.models import Review,ImportBatch,Feedback,HotelSettings,PaymentAttempt
    for model in (Review,ImportBatch,Feedback,HotelSettings,PaymentAttempt):model.__table__.create(conn)
    for name,definition in conn.execute(text("SELECT conname,pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid='giao_dich_thanh_toan'::regclass AND contype='c'")):
        if 'phuong_thuc' in definition:op.execute(f'ALTER TABLE giao_dich_thanh_toan DROP CONSTRAINT "{name}"')
    op.execute("ALTER TABLE giao_dich_thanh_toan ADD CONSTRAINT ck_payment_methods_v5 CHECK(phuong_thuc IN ('TIEN_MAT','CHUYEN_KHOAN','MOMO','VNPAY'))")
    op.execute("ALTER TABLE giao_dich_thanh_toan ADD COLUMN environment varchar(12) NOT NULL DEFAULT 'production' CHECK (environment IN ('sandbox','production'))")

def downgrade():raise RuntimeError('Integration contains customer reviews and financial history; use an explicit retention migration.')

"""Additive TTTP upgrade. Existing accounts, bookings and exclusion constraints stay."""
from pathlib import Path
from alembic import op

revision = '0002'
down_revision = '0001'


def upgrade():
    op.execute('ALTER TABLE tai_khoan ALTER COLUMN email DROP NOT NULL, ALTER COLUMN mat_khau_bam DROP NOT NULL')
    op.execute('ALTER TABLE tai_khoan ADD COLUMN dang_nhap_noi_bo boolean NOT NULL DEFAULT true, ADD COLUMN token_version integer NOT NULL DEFAULT 0')
    op.execute("ALTER TABLE tai_khoan ADD CONSTRAINT ck_local_identity CHECK (NOT dang_nhap_noi_bo OR (email IS NOT NULL AND mat_khau_bam IS NOT NULL))")
    op.execute("ALTER TABLE phong ADD COLUMN tinh_trang_van_hanh varchar(20) NOT NULL DEFAULT 'SAN_SANG'")
    op.execute("ALTER TABLE phong ADD CONSTRAINT ck_operational_status CHECK (tinh_trang_van_hanh IN ('SAN_SANG','CAN_DON_DEP','DANG_DON_DEP','BAO_TRI'))")
    sql = Path(__file__).with_name('0002_tables.sql').read_text(encoding='utf-8')
    if op.get_context().as_sql:
        op.execute(sql)
    else:
        op.get_bind().exec_driver_sql(sql)


def downgrade():
    # Do not silently discard social accounts or the financial/audit ledger.
    raise RuntimeError('Downgrade 0002 requires an explicit reviewed data-retention migration; no data was removed.')

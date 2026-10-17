"""Initial PostgreSQL schema, frozen snapshot; downgrade destroys business data."""
from pathlib import Path
from alembic import op

revision = '0001'
down_revision = None


def upgrade():
    # SQL snapshot is independent from future ORM changes.
    sql = Path(__file__).with_name('0001_schema.sql').read_text(encoding='utf-8')
    # psycopg accepts the entire script through the driver, including PL/pgSQL.
    if op.get_context().as_sql:
        op.execute(sql)
    else:
        op.get_bind().exec_driver_sql(sql)


def downgrade():
    op.execute('DROP FUNCTION IF EXISTS verify_account_profile() CASCADE')
    for table in ('lich_su_dat_phong', 'phong_tam_ngung', 'phieu_dat_phong',
                  'anh_loai_phong', 'loai_phong_tien_nghi', 'tien_nghi', 'phong',
                  'loai_phong', 'nhan_vien', 'khach_hang', 'chuc_vu', 'tai_khoan'):
        op.execute(f'DROP TABLE public.{table}')
    # btree_gist may be shared by other applications; retain it.

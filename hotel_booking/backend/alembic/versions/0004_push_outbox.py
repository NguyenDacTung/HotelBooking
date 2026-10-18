from alembic import op
revision='0004'
down_revision='0003'
def upgrade():
    op.execute('ALTER TABLE thong_bao ADD COLUMN IF NOT EXISTS push_luc timestamptz')
    op.execute('ALTER TABLE thiet_bi_thong_bao ADD COLUMN IF NOT EXISTS token_version integer NOT NULL DEFAULT 0')
def downgrade():raise RuntimeError('Preserve delivery/session audit metadata.')

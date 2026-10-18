"""Durable retry scheduling for the existing push outbox."""
from alembic import op
revision='0007'
down_revision='0006'
def upgrade():
    op.execute('ALTER TABLE thong_bao ADD COLUMN push_attempts integer NOT NULL DEFAULT 0')
    op.execute('ALTER TABLE thong_bao ADD COLUMN push_retry_at timestamptz')
def downgrade():raise RuntimeError('Keep notification delivery history')

"""Durable, sandbox-only full refund requests."""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0009'
down_revision = '0008'


def upgrade():
    op.create_table('hoan_tien_sandbox',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('attempt_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('phien_thanh_toan.id'), nullable=False),
        sa.Column('request_id', postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column('reference', sa.String(80), nullable=False, unique=True),
        sa.Column('amount', sa.Numeric(14, 0), nullable=False),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('tai_khoan.id'), nullable=False),
        sa.Column('state', sa.String(24), server_default='CREATED', nullable=False),
        sa.Column('provider_transaction', sa.String(100)),
        sa.Column('ngay_tao', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.CheckConstraint('amount > 0'),
        sa.CheckConstraint("state IN ('CREATED','PENDING','SUCCEEDED','FAILED')"))
    op.create_index('ix_hoan_tien_sandbox_attempt_id', 'hoan_tien_sandbox', ['attempt_id'])
    op.create_index('uq_sandbox_refund_reserved', 'hoan_tien_sandbox', ['attempt_id'], unique=True,
                    postgresql_where=sa.text("state IN ('CREATED','PENDING','SUCCEEDED')"))


def downgrade():
    raise RuntimeError('Preserve refund request history; do not downgrade this migration.')

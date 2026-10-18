"""Payment reconciliation uniqueness across reservations."""
from alembic import op
revision='0006'
down_revision='0005'
def upgrade():
    op.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_attempt_provider_transaction ON phien_thanh_toan(provider,environment,provider_transaction)")
    op.execute("""DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ck_attempt_state' AND conrelid='phien_thanh_toan'::regclass) THEN ALTER TABLE phien_thanh_toan ADD CONSTRAINT ck_attempt_state CHECK (state IN ('CREATED','PENDING','SUCCEEDED','FAILED')); END IF; END $$""")
def downgrade():raise RuntimeError('Keep financial reconciliation history')

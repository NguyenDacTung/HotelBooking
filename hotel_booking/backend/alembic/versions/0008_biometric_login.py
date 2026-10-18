"""Public-key devices and one-use challenges for biometric sign-in."""
from alembic import op
from app.models import BiometricDevice, BiometricChallenge
revision = '0008'
down_revision = '0007'

def upgrade():
    BiometricDevice.__table__.create(op.get_bind(), checkfirst=True)
    BiometricChallenge.__table__.create(op.get_bind(), checkfirst=True)

def downgrade():
    raise RuntimeError('Do not remove registered sign-in device history')

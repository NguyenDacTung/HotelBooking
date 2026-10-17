import os
import pytest

# Test-only settings, not application defaults or production credentials.
os.environ.setdefault('DATABASE_URL', 'postgresql+psycopg://unused:unused@127.0.0.1/hotel_booking_test')
os.environ.setdefault('JWT_SECRET', 'test-only-secret-not-for-production-32-characters')


@pytest.fixture
def pg_engine(request):
    from sqlalchemy import create_engine, text
    from sqlalchemy.engine import make_url
    from alembic.config import Config
    from alembic import command
    from app.core.config import settings
    from app.db.session import engine
    url = os.environ.get('TEST_DATABASE_URL')
    if not url:
        pytest.skip('Chưa có TEST_DATABASE_URL: cần PostgreSQL test thật')
    parsed = make_url(url)
    if parsed.drivername != 'postgresql+psycopg' or parsed.database != 'hotel_booking_test':
        pytest.fail('Chỉ chạy fixture trên PostgreSQL database hotel_booking_test')
    tmp_path = request.getfixturevalue('tmp_path')
    previous = os.environ['DATABASE_URL']
    previous_upload = os.environ.get('UPLOAD_DIR')
    os.environ['DATABASE_URL'] = url
    os.environ['UPLOAD_DIR'] = str(tmp_path / 'uploads')
    settings.cache_clear()
    engine.cache_clear()
    command.upgrade(Config('alembic.ini'), 'head')
    db_engine = create_engine(url, isolation_level='READ COMMITTED')
    from app.models import Base
    tables = ', '.join('public.' + t.name for t in reversed(Base.metadata.sorted_tables))
    with db_engine.begin() as conn:
        if conn.scalar(text('SELECT current_database()')) != 'hotel_booking_test':
            pytest.fail('Actual connection is not hotel_booking_test; refusing TRUNCATE')
        conn.execute(text('TRUNCATE ' + tables + ' RESTART IDENTITY CASCADE'))
    yield db_engine
    db_engine.dispose()
    engine().dispose()
    engine.cache_clear()
    os.environ['DATABASE_URL'] = previous
    if previous_upload is None:
        os.environ.pop('UPLOAD_DIR', None)
    else:
        os.environ['UPLOAD_DIR'] = previous_upload
    settings.cache_clear()

"""Local setup/test commands. Credentials stay in .env, never printed."""
import argparse
import os
from pathlib import Path
import secrets
import subprocess
import sys
from uuid import uuid4
from dotenv import dotenv_values
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.session import engine


def development_fingerprint():
    from app.models import Base
    result = {}
    with engine().connect() as conn:
        if conn.scalar(text('SELECT current_database()')) != 'hotel_booking':
            raise SystemExit('Development database guard failed')
        from sqlalchemy import inspect
        for name in inspect(conn).get_table_names(schema='public'):
            # Only fixed ORM table identifiers; compare data without displaying it.
            row = conn.execute(text(f'''SELECT count(*), md5(coalesce(string_agg(h, '' ORDER BY h), ''))
                FROM (SELECT md5(to_jsonb(t)::text) h FROM public."{name}" t) hashes''')).one()
            result[name] = tuple(row)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['prepare', 'test-postgres'])
    parser.add_argument('--only',help='Optional pytest selector under tests/, still guarded to hotel_booking_test')
    args = parser.parse_args()
    if args.only and (not args.only.startswith('tests/') or '..' in args.only):parser.error('--only must select a test under tests/')
    config = settings()
    url = make_url(config.database_url)
    if url.database != 'hotel_booking':
        raise SystemExit('Local setup requires database hotel_booking; configuration preserved.')
    test_url = url.set(database='hotel_booking_test')
    if args.command == 'prepare':
        with engine().connect() as conn:
            if conn.scalar(text('SELECT current_database()')) != 'hotel_booking':
                raise SystemExit('Unexpected database; no changes made.')
        with engine().connect().execution_options(isolation_level='AUTOCOMMIT') as conn:
            if not conn.scalar(text("SELECT 1 FROM pg_database WHERE datname='hotel_booking_test'")):
                conn.exec_driver_sql('CREATE DATABASE hotel_booking_test')
                print('Created hotel_booking_test (separate from hotel_booking).')
            else:
                print('hotel_booking_test already exists; preserved until explicit tests.')
        env_path = Path('.env')
        password = os.environ.get('DEMO_PASSWORD') or dotenv_values(env_path).get('DEMO_PASSWORD')
        if not password:
            password = secrets.token_urlsafe(18)
            with env_path.open('a', encoding='utf-8') as stream:
                stream.write('\n# Password shared by newly seeded demonstration accounts only.\nDEMO_PASSWORD=' + password + '\n')
            print('Generated DEMO_PASSWORD in backend/.env; not displayed.')
        from app.cli import seed
        with Session(engine(), expire_on_commit=False) as db:
            seed(db, password)
        print('Seed completed without resetting hotel_booking.')
    else:
        before = development_fingerprint()
        env = os.environ.copy()
        env['DATABASE_URL'] = test_url.render_as_string(hide_password=False)
        env['TEST_DATABASE_URL'] = env['DATABASE_URL']
        env['JWT_SECRET'] = config.jwt_secret
        # All tests, including unit/API imports, are isolated from the development DB.
        base = Path('.test-runs').resolve() / uuid4().hex
        base.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run([sys.executable, '-m', 'pytest', '-q', '-p', 'no:cacheprovider',
                                 '--basetemp', str(base), '--tb=short', *([args.only] if args.only else [])], env=env)
        if development_fingerprint() != before:
            raise SystemExit('Development database changed during test run; investigate before continuing.')
        print('Verified: hotel_booking data unchanged across test run.', flush=True)
        raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()

"""Additive migration with a local dump and old-column data comparison.
Run from project root: backend/.venv/Scripts/python.exe scripts/migrate_preserving_data.py
Never prints connection URLs or record contents. Never resets any database.
"""
import os,sys,json,subprocess
from pathlib import Path
from datetime import datetime
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'backend'));os.chdir(ROOT/'backend')
from app.core.config import settings
from app.db.session import engine
from sqlalchemy import inspect,text
from sqlalchemy.engine import make_url
from alembic.config import Config
from alembic import command

def snapshot(conn,shape):
    result={}
    for table,cols in shape.items():
        name='public.'+conn.dialect.identifier_preparer.quote(table)
        fields=','.join(conn.dialect.identifier_preparer.quote(c) for c in cols)
        query=f"SELECT count(*),md5(coalesce(string_agg(h,'' ORDER BY h),'')) FROM (SELECT md5(row_to_json(t)::text) h FROM (SELECT {fields} FROM {name}) t) hashes"
        result[table]=tuple(conn.execute(text(query)).one())
    return result

with engine().connect() as conn:
    if conn.scalar(text('SELECT current_database()'))!='hotel_booking':raise SystemExit('Refusing migration: expected hotel_booking')
    inspector=inspect(conn);shape={table:[c['name'] for c in inspector.get_columns(table)] for table in inspector.get_table_names(schema='public') if table!='alembic_version'}
    before=snapshot(conn,shape)
stamp=datetime.now().strftime('%Y%m%d-%H%M%S');directory=ROOT/'.local-backups'/('tetra-v3-'+stamp);directory.mkdir(parents=True,exist_ok=False)
u=make_url(settings().database_url);env=os.environ.copy();env['PGPASSWORD']=u.password or ''
pgdump=Path('C:/Program Files/PostgreSQL/18/bin/pg_dump.exe')
if not pgdump.is_file():raise SystemExit('pg_dump 18 missing; no migration performed')
result=subprocess.run([str(pgdump),'-h',u.host or 'localhost','-p',str(u.port or 5432),'-U',u.username or 'postgres','-d','hotel_booking','-Fc','-f',str(directory/'hotel_booking.dump')],env=env,capture_output=True)
if result.returncode:raise SystemExit('Backup failed; migration not performed. Details withheld to protect credentials.')
command.upgrade(Config('alembic.ini'),'head')
with engine().connect() as conn:
    after=snapshot(conn,shape);head=conn.scalar(text('SELECT version_num FROM alembic_version'))
if after!=before:raise SystemExit('Old-column data changed; investigate the backup before continuing. No automatic restore performed.')
(directory/'verification.json').write_text(json.dumps({'revision':head,'unchanged_original_tables':len(shape),'verified':True},indent=2),encoding='utf8')
print('Migration revision:',head)
print('Verified original rows/columns unchanged in',len(shape),'tables.')
print('Backup:',directory.relative_to(ROOT)/'hotel_booking.dump')

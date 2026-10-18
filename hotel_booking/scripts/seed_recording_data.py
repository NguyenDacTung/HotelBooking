"""Add recording data safely. Default validates in a rolled-back test transaction.

Run from repository root using backend/.venv/Scripts/python.exe.
--apply explicitly backs up and adds to hotel_booking. Never resets a database.
"""
import argparse, json, os, secrets, subprocess, sys
from collections import Counter
from datetime import datetime
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'backend'));os.chdir(ROOT/'backend')
from dotenv import dotenv_values
from sqlalchemy import create_engine, inspect, select, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models import RoomType
from app.seed_operations import CATALOG
from app.seed_recording import seed

def snapshot(conn):
    rows={}
    for name in inspect(conn).get_table_names(schema='public'):
        quoted=conn.dialect.identifier_preparer.quote(name)
        rows[name]=Counter(dict(conn.execute(text(f'SELECT md5(row_to_json(t)::text),count(*) FROM public.{quoted} t GROUP BY 1')).all()))
    return rows

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args()
    url=make_url(settings().database_url)
    if url.database!='hotel_booking':raise SystemExit('Expected original database configuration; nothing changed')
    target=url if args.apply else url.set(database='hotel_booking_test')
    eng=create_engine(target)
    with eng.connect() as conn:
        assert conn.scalar(text('select current_database()'))==target.database
        before=snapshot(conn)
    env_path=ROOT/'backend/.env';values=dotenv_values(env_path)
    password=values.get('TETRA_RECORDING_PASSWORD') or values.get('TTTP_STAFF_PASSWORD') or values.get('DEMO_PASSWORD') or secrets.token_urlsafe(18)
    assert len(password)>=8
    directory=None
    if args.apply:
        directory=ROOT/'.local-backups'/('recording-'+datetime.now().strftime('%Y%m%d-%H%M%S'));directory.mkdir(parents=True)
        env=os.environ.copy();env['PGPASSWORD']=url.password or ''
        result=subprocess.run(['C:/Program Files/PostgreSQL/18/bin/pg_dump.exe','-h',url.host or 'localhost','-p',str(url.port or 5432),'-U',url.username or 'postgres','-d','hotel_booking','-Fc','-f',str(directory/'hotel_booking.dump')],env=env,capture_output=True)
        if result.returncode:raise SystemExit('Backup failed; no data applied. Credentials withheld.')
    with Session(eng,expire_on_commit=False) as db:
        if not args.apply:
            for name,price,capacity,area,beds,description in CATALOG:
                if not db.scalar(select(RoomType).where(RoomType.ten_loai==name)):
                    db.add(RoomType(ten_loai=name,gia_co_ban=price,suc_chua=capacity,dien_tich_m2=area,so_giuong=beds,mo_ta=description))
            db.flush()
        manifest=seed(db,password)
        db.execute(text('SET CONSTRAINTS ALL IMMEDIATE'))
        assert seed(db,password)['already_present'],'Repeat invocation must add nothing'
        if args.apply:db.commit()
        else:db.rollback()
    with eng.connect() as conn:
        after=snapshot(conn)
    assert all(not (hashes-after.get(name,Counter())) for name,hashes in before.items()),'An original row changed; inspect backup'
    if not args.apply:
        assert before==after,'Test validation must roll back all rows'
        print('Validated constraints/idempotence on hotel_booking_test; transaction rolled back.');print(json.dumps(manifest,ensure_ascii=False));return
    if not values.get('TETRA_RECORDING_PASSWORD'):
        with env_path.open('a',encoding='utf8') as f:f.write('\n# Local password for the newly added recording accounts only.\nTETRA_RECORDING_PASSWORD='+password+'\n')
    manifest.update({'verified_original_rows_unchanged':True,'backup':str(directory.relative_to(ROOT)/'hotel_booking.dump')})
    (directory/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    credentials={role:{'email':email,'password':password} for role,email in [('customer','minhanh@tetra.test'),('staff','thutrang@tetra.test')]}
    credentials['admin']={'email':'admin@tttp.test','password':values.get('TTTP_ADMIN_PASSWORD') or values.get('DEMO_PASSWORD','')}
    (ROOT/'.local-backups/recording-session.json').write_text(json.dumps(credentials),encoding='utf8')
    print(json.dumps(manifest,ensure_ascii=False));print('New account password stored only in backend/.env as TETRA_RECORDING_PASSWORD.')

if __name__=='__main__':main()

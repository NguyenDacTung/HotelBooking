"""Explicit development-only TETRA accounts. Never overwrites existing credentials/roles."""
import os
from dotenv import dotenv_values
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.db.session import engine
from app.models import Account, Role, Staff, Customer
from app.core.security import passwords
from app.cli import roles


def seed_tttp(db, values):
    roles(db)
    for email,name,role,key in [
        ('admin@tttp.test','Quản trị TETRA','QUAN_LY','TTTP_ADMIN_PASSWORD'),
        ('staff@tttp.test','Nhân viên TETRA','LE_TAN','TTTP_STAFF_PASSWORD'),
        ('customer@tttp.test','Khách TETRA','KHACH_HANG','TTTP_CUSTOMER_PASSWORD')]:
        password = values.get(key)
        if not password:
            print(key+': missing; account not created.')
            continue
        if not 8<=len(password)<=128:
            raise ValueError('Demo password must contain 8–128 characters.')
        old = db.scalar(select(Account).where(Account.email==email))
        if old:
            profile = db.get(Customer,old.id) if role=='KHACH_HANG' else db.get(Staff,old.id)
            matches = old.loai_tai_khoan==('KHACH_HANG' if role=='KHACH_HANG' else 'NHAN_VIEN') and profile is not None
            if matches and role!='KHACH_HANG': matches=db.get(Role,profile.ma_cv).ma_quyen==role
            if not matches: raise ValueError('Existing account conflicts with TETRA seed role; no changes committed.')
            print(email+': preserved.')
            continue
        account = Account(email=email,mat_khau_bam=passwords.hash(password),loai_tai_khoan='KHACH_HANG' if role=='KHACH_HANG' else 'NHAN_VIEN')
        db.add(account);db.flush()
        if role=='KHACH_HANG': db.add(Customer(id=account.id,ho_ten=name))
        else: db.add(Staff(id=account.id,ho_ten=name,ma_cv=db.scalar(select(Role.ma_cv).where(Role.ma_quyen==role))))
        db.flush()
        print(email+': prepared.')
    db.commit()


if __name__=='__main__':
    config = dict(dotenv_values('.env'));config.update(os.environ)
    with Session(engine(),expire_on_commit=False) as db: seed_tttp(db,config)
    print('TETRA account seed committed; passwords not displayed.')

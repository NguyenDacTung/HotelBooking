from sqlalchemy import select, text, func
from app.models import Account, Staff, Customer, Role, Audit, Identity
from app.core.security import principal, passwords
from app.core.errors import fail
from app.services.bookings import get_or_404


def audit(db, user, entity, key, action, before, after, reason):
    db.add(Audit(entity=entity, entity_id=str(key), action=action, actor_id=user['account'].id,
        before=before, after=after, ly_do=reason))


def account_out(db, account, detail=False):
    profile = db.get(Customer, account.id) if account.loai_tai_khoan == 'KHACH_HANG' else db.get(Staff, account.id)
    role = 'KHACH_HANG' if isinstance(profile, Customer) else db.get(Role, profile.ma_cv).ma_quyen
    result = {'id': str(account.id), 'email': account.email, 'ho_ten': profile.ho_ten,
        'so_dien_thoai': getattr(profile,'so_dien_thoai',None), 'ma_quyen': role,
        'dang_hoat_dong': account.dang_hoat_dong, 'ngay_tao': account.ngay_tao,
        'cach_dang_nhap': (['EMAIL'] if account.mat_khau_bam else []) +
            list(db.scalars(select(Identity.provider).where(Identity.tai_khoan_id == account.id)))}
    if detail:
        result['lich_su'] = [{'action':a.action, 'before':a.before,'after':a.after,'ly_do':a.ly_do,
            'actor_id':str(a.actor_id),'thoi_diem':a.thoi_diem} for a in db.scalars(
                select(Audit).where(Audit.entity=='account',Audit.entity_id==str(account.id)).order_by(Audit.id.desc()))]
    return result


def change_access(db, user, key, data):
    # One database transaction lock coordinates all admin role/status changes.
    db.execute(text('SELECT pg_advisory_xact_lock(84721001)'))
    acting = principal(db, user['account'])
    if acting['role'] != 'QUAN_LY':
        fail(403,'FORBIDDEN','Quyền quản trị đã thay đổi')
    target = get_or_404(db, Account, key, True)
    before = account_out(db, target)
    role = getattr(data,'ma_quyen',None)
    active = getattr(data,'dang_hoat_dong',None)
    removing_admin = before['ma_quyen']=='QUAN_LY' and (role=='LE_TAN' or active is False)
    if key == user['account'].id and (role=='LE_TAN' or active is False):
        fail(400,'INVALID_OPERATION','Không thể tự khóa hoặc tự hạ quyền')
    if removing_admin:
        count = db.scalar(select(func.count()).select_from(Account).join(Staff).join(Role).where(
            Account.dang_hoat_dong.is_(True),Staff.dang_hoat_dong.is_(True),
            Role.dang_su_dung.is_(True),Role.ma_quyen=='QUAN_LY'))
        if count <= 1:
            fail(409,'LAST_ADMIN','Không thể bỏ quản trị viên hoạt động cuối cùng')
    if role:
        if target.loai_tai_khoan != 'NHAN_VIEN':
            fail(400,'INVALID_OPERATION','Không chuyển tài khoản khách thành nhân viên')
        staff = get_or_404(db, Staff, key, True)
        staff.ma_cv = db.scalar(select(Role.ma_cv).where(Role.ma_quyen==role, Role.dang_su_dung.is_(True)))
        if staff.ma_cv is None:
            fail(409,'STATE_CONFLICT','Chức vụ không còn được sử dụng')
    else:
        target.dang_hoat_dong = active
    target.token_version += 1
    db.flush()
    after = account_out(db, target)
    audit(db,user,'account',key,'role' if role else 'status',
        {k:before[k] for k in ('ma_quyen','dang_hoat_dong')},
        {k:after[k] for k in ('ma_quyen','dang_hoat_dong')},data.ly_do)
    db.commit()
    return account_out(db,target,True)

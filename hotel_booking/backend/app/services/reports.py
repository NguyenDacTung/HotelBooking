from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo
from sqlalchemy import select, func, case
from app.models import Booking, Payment
from app.core.errors import fail

VN = ZoneInfo('Asia/Ho_Chi_Minh')


def revenue(db, start, end, mode='day'):
    if end<start or (end-start).days>365:
        fail(422,'VALIDATION_ERROR','Kỳ báo cáo từ 1 đến 366 ngày')
    low = datetime.combine(start,time.min,VN).astimezone(timezone.utc)
    high = datetime.combine(end+timedelta(days=1),time.min,VN).astimezone(timezone.utc)
    dates = {}
    for offset in range((end-start).days+1):
        key = (start+timedelta(days=offset)).isoformat()
        dates[key] = {'ngay':key,'thu':0,'hoan':0,'thu_rong':0,'so_dat_phong':0}
    pay_day = func.date(func.timezone('Asia/Ho_Chi_Minh',Payment.thoi_diem_giao_dich))
    for day, kind, amount in db.execute(select(pay_day,Payment.loai,func.sum(Payment.so_tien)).where(
        Payment.thoi_diem_giao_dich>=low,Payment.thoi_diem_giao_dich<high,Payment.environment=='production').group_by(pay_day,Payment.loai)):
        dates[day.isoformat()]['thu' if kind=='THU' else 'hoan'] += int(amount)
    booking_day = func.date(func.timezone('Asia/Ho_Chi_Minh',Booking.ngay_tao))
    for day,count in db.execute(select(booking_day,func.count()).where(
        Booking.ngay_tao>=low,Booking.ngay_tao<high).group_by(booking_day)):
        dates[day.isoformat()]['so_dat_phong'] = count
    selected = [Booking.ngay_tao>=low,Booking.ngay_tao<high]
    statuses = dict(db.execute(select(Booking.trang_thai,func.count()).where(*selected).group_by(Booking.trang_thai)).all())
    from app.services.payments import balance
    cohort = list(db.scalars(select(Booking).where(*selected)))
    balances = [(b,balance(db,b)) for b in cohort]
    value = sum(t['tong_thanh_toan'] for b,t in balances if b.trang_thai not in ('CHO_XAC_NHAN','DA_TU_CHOI','HET_HAN'))
    due = sum(t['con_phai_thu'] for b,t in balances)
    pending_refund = sum(t['can_hoan_tien'] for b,t in balances)
    series = list(dates.values())
    for row in series: row['thu_rong']=row['thu']-row['hoan']
    kpi = {'thu':sum(r['thu'] for r in series),'hoan':sum(r['hoan'] for r in series),
           'thu_rong':sum(r['thu_rong'] for r in series),'gia_tri_dat':value,
           'so_dat_phong':sum(statuses.values()),'con_phai_thu':due,'can_hoan_tien':pending_refund}
    if mode=='month':
        monthly = {}
        for row in series:
            key = row['ngay'][:7]
            target = monthly.setdefault(key,{'ngay':key,'thu':0,'hoan':0,'thu_rong':0,'so_dat_phong':0})
            for field in ('thu','hoan','thu_rong','so_dat_phong'): target[field]+=row[field]
        series = list(monthly.values())
    return {'tu_ngay':str(start),'den_ngay':str(end),'mui_gio':'Asia/Ho_Chi_Minh',
        'dinh_nghia':'Thu/hoàn theo ngày giao dịch; giá trị hóa đơn gồm phụ thu, công nợ và khoản cần hoàn của các đơn tạo trong kỳ.',
        'kpi':kpi,'trang_thai':statuses,'series':series}

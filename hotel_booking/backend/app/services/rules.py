from datetime import datetime
from zoneinfo import ZoneInfo
from app.core.errors import fail


def today():
    return datetime.now(ZoneInfo('Asia/Ho_Chi_Minh')).date()


def validate_stay(start, end, guests, capacity=None):
    if start < today() or not 1 <= (end - start).days <= 30:
        fail(422, 'VALIDATION_ERROR', 'Ngày nhận từ hôm nay, lưu trú từ 1 đến 30 đêm')
    if guests < 1 or capacity is not None and guests > capacity:
        fail(422, 'VALIDATION_ERROR', 'Số khách vượt sức chứa phòng')


def next_state(old, action, arrival, role, owner):
    if action == 'cancel':
        if not owner or role != 'KHACH_HANG':
            fail(404, 'NOT_FOUND', 'Không tìm thấy phiếu')
        allowed, new = ('CHO_XAC_NHAN', 'DA_XAC_NHAN'), 'DA_HUY'
    else:
        if role not in ('LE_TAN', 'QUAN_LY'):
            fail(403, 'FORBIDDEN', 'Không đủ quyền')
        allowed, new = ('CHO_XAC_NHAN',), {'confirm': 'DA_XAC_NHAN', 'reject': 'DA_TU_CHOI'}[action]
    if old not in allowed:
        fail(409, 'STATE_CONFLICT', 'Trạng thái phiếu đã thay đổi')
    if today() >= arrival:
        fail(400, 'INVALID_OPERATION', 'Đã đến hạn nhận phòng, không thể xử lý phiếu')
    return new

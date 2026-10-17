from fastapi import Depends
from app.core.security import current
from app.core.errors import fail

PERMISSIONS = {
    'KHACH_HANG': {'bookings.own', 'notifications.own'},
    'LE_TAN': {'bookings.staff', 'rooms.operations', 'payments.collect', 'notifications.own'},
    'QUAN_LY': {'bookings.staff', 'rooms.operations', 'payments.collect', 'payments.refund',
               'accounts.manage', 'catalog.manage', 'reports.read', 'notifications.own'},
}


def permission(name):
    def dependency(user=Depends(current)):
        if name not in PERMISSIONS.get(user['role'], set()):
            fail(403, 'FORBIDDEN', 'Bạn không có quyền thực hiện thao tác này')
        return user
    return dependency

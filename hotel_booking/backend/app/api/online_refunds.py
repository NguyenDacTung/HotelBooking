"""Durable full sandbox refunds. Production money and balances are never touched."""
from uuid import UUID, uuid4
from fastapi import APIRouter, Depends, Request
from sqlalchemy import select, text
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.errors import fail
from app.core.security import current, manager, principal
from app.db.session import get_db
from app.models import SandboxRefund, PaymentAttempt, Payment, Booking, Account
from app.schemas.requests import Input
from app.services import gateways
from app.services.bookings import get_or_404, lock_room, visible_booking
from app.services.accounts import audit

router = APIRouter(tags=['Hoàn tiền sandbox'])


class Create(Input):
    request_id: UUID


def dto(row):
    return {'id': str(row.id), 'attempt_id': str(row.attempt_id), 'state': row.state,
            'amount': int(row.amount), 'environment': 'sandbox',
            'note': 'Hoàn sandbox không thay đổi công nợ thật'}


def configured(attempt):
    return settings().payment_environment == 'sandbox' and attempt.environment == 'sandbox' and gateways.configured(attempt.provider)


def reconcile(db, key, attempt, request, *, query_only=False):
    row = get_or_404(db, SandboxRefund, key)
    db.expunge(row)
    db.expunge(attempt)
    db.rollback()  # No database transaction or locks during provider I/O.
    try:
        state, transaction = gateways.refund_transport(row, attempt, request.client.host if request.client else '127.0.0.1', query_only=query_only)
    except Exception:
        fail(503, 'REFUND_UNCERTAIN', 'Chưa xác minh được hoàn sandbox. Kiểm tra kết quả; không tạo yêu cầu khác.')
    if state == 'SUCCEEDED' and (not transaction or transaction == '0'):
        fail(503, 'REFUND_UNCERTAIN', 'Thiếu mã hoàn của nhà cung cấp; cần tiếp tục đối soát.')
    db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key,0))'),
               {'key': 'sandbox-refund:' + attempt.provider + ':' + transaction if state == 'SUCCEEDED' else str(key)})
    row = get_or_404(db, SandboxRefund, key, True)
    if row.state in ('SUCCEEDED', 'FAILED'):
        return dto(row)
    if state == 'SUCCEEDED':
        duplicate = db.scalar(select(SandboxRefund.id).join(PaymentAttempt, PaymentAttempt.id == SandboxRefund.attempt_id).where(
            PaymentAttempt.provider == attempt.provider, SandboxRefund.provider_transaction == transaction,
            SandboxRefund.state == 'SUCCEEDED', SandboxRefund.id != key))
        if duplicate:
            fail(409, 'TRANSACTION_CONFLICT', 'Mã hoàn đã được ghi nhận cho yêu cầu khác.')
        original = db.scalar(select(Payment).where(Payment.request_id == attempt.request_id, Payment.loai == 'THU', Payment.environment == 'sandbox'))
        if original is None or original.ma_pdp != attempt.ma_pdp or original.so_tien != row.amount:
            fail(409, 'ORIGINAL_PAYMENT_MISSING', 'Không tìm thấy khoản thu sandbox gốc; giữ yêu cầu để đối soát.')
        row.provider_transaction = transaction
        if not db.scalar(select(Payment.id).where(Payment.request_id == row.request_id)):
            db.add(Payment(ma_pdp=original.ma_pdp, loai='HOAN', so_tien=row.amount,
                           phuong_thuc=attempt.provider, environment='sandbox', nguoi_ghi_nhan=row.created_by,
                           giao_dich_goc_id=original.id, request_id=row.request_id, ma_tham_chieu=transaction,
                           ghi_chu='Cổng xác nhận hoàn sandbox; không thay đổi công nợ thật'))
    old_state = row.state
    row.state = state if state in ('SUCCEEDED', 'FAILED') else 'PENDING'
    if old_state != row.state:
        audit(db, {'account': db.get(Account, row.created_by)}, 'sandbox_refund', row.id,
              'reconcile', {'state': old_state}, {'state': row.state, 'environment': 'sandbox'}, '')
    db.commit()
    return dto(row)


@router.get('/bookings/{key}/online-refunds')
def refunds(key: UUID, user=Depends(current), db: Session = Depends(get_db)):
    visible_booking(db, key, user)
    rows = db.scalars(select(SandboxRefund).join(PaymentAttempt, SandboxRefund.attempt_id == PaymentAttempt.id)
                      .where(PaymentAttempt.ma_pdp == key).order_by(SandboxRefund.ngay_tao.desc()).limit(100))
    return {'items': [dto(row) for row in rows]}


@router.post('/admin/online-payments/{key}/refunds')
def create(key: UUID, data: Create, request: Request, user=Depends(manager), db: Session = Depends(get_db)):
    db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key,0))'), {'key': str(data.request_id)})
    attempt = get_or_404(db, PaymentAttempt, key)
    booking = get_or_404(db, Booking, attempt.ma_pdp)
    lock_room(db, booking.ma_phong)
    attempt = get_or_404(db, PaymentAttempt, key, True)
    if principal(db, user['account'])['role'] != 'QUAN_LY':
        fail(403, 'FORBIDDEN', 'Chỉ quản lý được hoàn sandbox.')
    existing = db.scalar(select(SandboxRefund).where(SandboxRefund.request_id == data.request_id))
    if existing:
        if existing.attempt_id != key or existing.created_by != user['account'].id:
            fail(409, 'REQUEST_CONFLICT', 'Mã yêu cầu đã được dùng.')
        return dto(existing)
    if (db.scalar(select(Payment.id).where(Payment.request_id == data.request_id))
            or db.scalar(select(PaymentAttempt.id).where(PaymentAttempt.request_id == data.request_id))):
        fail(409, 'REQUEST_CONFLICT', 'Mã yêu cầu đã được dùng cho giao dịch thu.')
    if not configured(attempt):
        fail(503, 'REFUND_NOT_CONFIGURED', 'Chỉ hỗ trợ hoàn sandbox với merchant đã cấu hình.')
    if attempt.state != 'SUCCEEDED' or not attempt.provider_transaction:
        fail(409, 'PAYMENT_NOT_SUCCEEDED', 'Chỉ hoàn khoản thanh toán sandbox đã xác minh thành công.')
    if db.scalar(select(SandboxRefund.id).where(SandboxRefund.attempt_id == key, SandboxRefund.state != 'FAILED')):
        fail(409, 'REFUND_RESERVED', 'Khoản thu đã hoàn hoặc đang chờ đối soát hoàn.')
    if attempt.provider == 'MOMO' and not 1000 <= int(attempt.amount) <= 50000000:
        fail(422, 'REFUND_AMOUNT_LIMIT', 'Khoản hoàn toàn phần nằm ngoài giới hạn hỗ trợ của MoMo.')
    if not db.scalar(select(Payment.id).where(Payment.request_id == attempt.request_id, Payment.environment == 'sandbox',
                                            Payment.loai == 'THU', Payment.ma_pdp == attempt.ma_pdp, Payment.so_tien == attempt.amount)):
        fail(409, 'ORIGINAL_PAYMENT_MISSING', 'Không tìm thấy khoản thu sandbox gốc.')
    row = SandboxRefund(attempt_id=key, request_id=data.request_id, reference='RF' + uuid4().hex,
                        amount=attempt.amount, created_by=user['account'].id)
    db.add(row)
    db.flush()
    refund_id = row.id
    audit(db, user, 'sandbox_refund', row.id, 'create', None,
          {'state': 'CREATED', 'amount': int(row.amount), 'environment': 'sandbox'}, '')
    db.commit()  # Reserve before contacting the provider, even if the process crashes.
    return reconcile(db, refund_id, attempt, request)


@router.post('/admin/online-refunds/{key}/query')
def query(key: UUID, request: Request, user=Depends(manager), db: Session = Depends(get_db)):
    row = get_or_404(db, SandboxRefund, key)
    if row.state in ('SUCCEEDED', 'FAILED'):
        return dto(row)
    attempt = get_or_404(db, PaymentAttempt, row.attempt_id)
    if not configured(attempt):
        fail(503, 'REFUND_NOT_CONFIGURED', 'Cấu hình merchant không khớp yêu cầu hoàn sandbox.')
    return reconcile(db, key, attempt, request, query_only=True)

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from starlette.exceptions import HTTPException


class DomainError(Exception):
    def __init__(self, status, code, message, details=None):
        self.status, self.code, self.message = status, code, message
        self.details = details


def fail(status, code, message):
    raise DomainError(status, code, message)


def handlers(app: FastAPI):
    @app.exception_handler(DomainError)
    async def domain(request: Request, exc: DomainError):
        return JSONResponse({'error': {'code': exc.code, 'message': exc.message,
            **({'details': exc.details} if exc.details is not None else {})}}, status_code=exc.status)

    @app.exception_handler(RequestValidationError)
    async def validation(request: Request, exc: RequestValidationError):
        return JSONResponse({'error': {'code': 'VALIDATION_ERROR', 'message': 'Dữ liệu không hợp lệ',
            'details': [{'field': '.'.join(map(str, e['loc'])), 'message': e['msg']} for e in exc.errors()]}}, status_code=422)

    @app.exception_handler(IntegrityError)
    async def integrity(request: Request, exc: IntegrityError):
        overlap = getattr(exc.orig, 'sqlstate', '') == '23P01'
        return JSONResponse({'error': {'code': 'ROOM_UNAVAILABLE' if overlap else 'STATE_CONFLICT',
            'message': 'Lịch phòng bị trùng' if overlap else 'Dữ liệu xung đột, vui lòng làm mới'}}, status_code=409)

    @app.exception_handler(HTTPException)
    async def http(request: Request, exc: HTTPException):
        return JSONResponse({'error': {'code': 'NOT_FOUND' if exc.status_code == 404 else 'INVALID_OPERATION',
                                      'message': str(exc.detail)}}, status_code=exc.status_code)

    @app.exception_handler(Exception)
    async def unexpected(request: Request, exc: Exception):
        return JSONResponse({'error': {'code': 'INTERNAL_ERROR', 'message': 'Không thể xử lý yêu cầu lúc này'}}, status_code=500)

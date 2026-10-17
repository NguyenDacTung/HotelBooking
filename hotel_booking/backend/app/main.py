from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from fastapi.responses import JSONResponse
from app.db.session import get_db
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.core.errors import handlers
from app.api import auth, catalog, bookings, staff
from app.api import upgrade, reports, social


@asynccontextmanager
async def lifespan(app):
    config = settings()  # Reject missing/placeholder secrets before serving requests.
    config.upload_dir.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(title='Khách sạn • Đặt phòng', lifespan=lifespan)
handlers(app)
for router in (auth.router, catalog.router, bookings.router, staff.router, upgrade.router, reports.router, social.router):
    app.include_router(router)


@app.get('/health')
def health():
    return {'status': 'ok'}


@app.get('/health/db')
def health_db(db: Session = Depends(get_db)):
    try:
        db.execute(text('SELECT 1'))
        return {'status': 'ok', 'database': 'connected'}
    except Exception:
        db.rollback()
        return JSONResponse({'status': 'unavailable', 'database': 'disconnected'}, status_code=503)


# Directory is configured without opening a database connection.
app.mount('/uploads', StaticFiles(directory=settings().upload_dir, check_dir=False), name='uploads')

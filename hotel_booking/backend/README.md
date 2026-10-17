# Backend FastAPI + PostgreSQL

Hiện đã kết nối PostgreSQL **18.6**, migrate/seed `hotel_booking` không reset. Mật khẩu nhập ở DB_PASSWORD trong `.env`; URL tự dựng từ từng trường. `DEMO_PASSWORD` trong file này là mật khẩu ngẫu nhiên của các tài khoản seed mới, không phải mật khẩu PostgreSQL. CLI seed đọc biến môi trường hoặc giá trị DEMO_PASSWORD từ .env.

Kiểm tra kết nối thực: `GET /health/db` (200 connected / 503 disconnected). Chạy toàn bộ test bằng `.\.venv\Scripts\python.exe manage_local.py test-postgres`: chỉ dùng hotel_booking_test, kiểm tra tên DB thực trước TRUNCATE và so sánh dấu vân tay hotel_booking trước/sau. Kết quả hiện tại 31 passed, không skip. Trên Windows cần quyền truy cập thư mục tạm pytest.

Lệnh chạy từ thư mục `backend`. Đọc [README gốc](../README.md) để chuẩn bị môi trường, database, secret và cấu hình mạng. API `/docs`, liveness `/health`; health không kiểm tra database.

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
# Sửa DATABASE_URL và JWT_SECRET trong .env trước khi chạy tiếp.
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m app.cli seed
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Seed đọc DEMO_PASSWORD từ environment/.env hoặc hỏi qua prompt nếu chưa có. Không ghi mật khẩu vào mã. Tài khoản mẫu: `khach1@example.com` đến `khach3@example.com`, `letan@example.com`, `quanly@example.com`. Seed chạy lại không nhân đôi marker, không đổi mật khẩu/dữ liệu hiện có; không tự dời ngày phiếu đã seed lần trước. Các ngày khi tạo mới tính theo ngày Việt Nam tại lúc chạy. Nếu gặp lịch xung đột thì seed rollback thay vì ghi đè.

CLI cấp nhân viên tin cậy:

```powershell
.\.venv\Scripts\python.exe -m app.cli create-staff --email staff@example.com --name 'Nhân viên mới' --role LE_TAN
```

`--role QUAN_LY` cấp quản lý. Email đã có không bị đổi vai trò/mật khẩu tự động.

Migration 0001 có snapshot SQL độc lập với model tương lai: 12 bảng, FK/index/check/exclusion, extension btree_gist và deferred profile trigger. Không dùng create_all lúc startup. Không chạy lại `freeze_schema.py` sau khi đã áp dụng migration; thay đổi schema phải thêm revision mới. `alembic downgrade base` **xóa toàn bộ bảng/dữ liệu nghiệp vụ**, chỉ dùng khi đã chủ động chấp nhận mất dữ liệu; công việc hiện tại chưa thực thi downgrade/reset DB.

Chạy kiểm tra: `.\.venv\Scripts\python.exe -m pytest -q`. Không có TEST_DATABASE_URL thì test PostgreSQL được skip có lý do. Xem [test_cases](../docs/test_cases.md).

Ảnh trong uploads do seed/upload tạo; không commit. Khi lỗi ghi DB, upload mới được dọn; xóa ảnh lưu bản tạm trong RAM để khôi phục nếu commit thất bại. Nếu filesystem hỏng cả lúc khôi phục thì cần sửa file từ backup; không thể bảo đảm transaction phân tán giữa filesystem và PostgreSQL.

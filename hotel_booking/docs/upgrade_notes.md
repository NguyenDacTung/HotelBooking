# Cập nhật 18/10/2026

Bản hiện tại dùng migration 0004, ảnh theo phòng, nghiệp vụ nhận/trả/phụ thu và khôi phục mật khẩu có cấu hình. Chạy Wi-Fi bằng `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1 -Lan`; APK dùng API_BASE_URL LAN và DEMO_MODE=false, không cần adb reverse. Xem [quy tắc mới](business_rules.md), [kiểm chứng nâng cấp](upgrade_verification.md), [cấu hình dịch vụ](service_configuration.md).

Phần 17/10 bên dưới là nhật ký phiên bản cũ; các giới hạn chưa có check-in/reset/push và hướng dẫn chỉ dùng USB đã được thay thế bởi các tài liệu cập nhật trên.

# TTTP — bản nâng cấp 17/10/2026

## Chạy cục bộ

Giữ PostgreSQL 18 và database `hotel_booking`. Migration bổ sung `0002_tttp` thêm 4 bảng và các cột; không sửa `0001`, không reset dữ liệu. Backend có 16 bảng ORM. Các lệnh dưới chạy từ `backend/`, dùng virtualenv đã cài requirements:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m app.seed_tttp
.\.venv\Scripts\python.exe manage_local.py test-postgres
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Backend hiện dùng thống nhất cổng **8000**. Kiểm tra `http://127.0.0.1:8000/health/db` và `/docs`. Từ thư mục gốc:

```powershell
adb -s R58T801R8BD reverse tcp:8000 tcp:8000
flutter run -d R58T801R8BD --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Điện thoại truy cập cổng 8000, ADB chuyển tới backend 8000 trên máy tính. Phải lập lại ánh xạ sau khi rút USB. APK debug dùng HTTP cho phát triển; bản phát hành cần HTTPS và khóa ký riêng.

Mở `backend/.env` và điền mật khẩu PostgreSQL ở `DB_PASSWORD='...'`, giữ nháy đơn. Không gửi mật khẩu vào chat. `DB_USER=postgres`, `DB_NAME=hotel_booking`; JWT_SECRET phải đủ 32 ký tự. Không commit `.env`.

Tài khoản `admin@tttp.test` và `staff@tttp.test` đã có; mật khẩu theo lựa chọn mới nhất của người dùng được lưu cục bộ ở `TTTP_ADMIN_PASSWORD` / `TTTP_STAFF_PASSWORD` và hash Argon2 trong DB. Seed yêu cầu 8–128 ký tự, chạy lại giữ mật khẩu/quyền đã có và báo xung đột nếu vai trò không khớp. Không reset tài khoản cũ. Chưa tạo `customer@tttp.test` vì chưa đặt `TTTP_CUSTOMER_PASSWORD`; có thể dùng khách seed cũ hoặc đăng ký mới.

## Hợp đồng bổ sung

- `POST /bookings`: thêm điều kiện tùy chọn `expected_don_gia_moi_dem`. Giá vẫn lấy từ DB dưới khóa; khác điều kiện trả `409 PRICE_CHANGED` với `error.details` chứa báo giá mới, chưa tạo đơn/thông báo. Client hiển thị giá mới và yêu cầu bấm xác nhận lại. Request cũ không có điều kiện vẫn được hỗ trợ.
- `GET/POST /admin/accounts`; `GET/PATCH /admin/accounts/{id}`; `PATCH .../{id}/role`, `.../{id}/status`: chỉ admin, lý do bắt buộc khi đổi quyền/khóa. Không tự khóa/hạ quyền, không chuyển khách thành nhân viên, không loại bỏ admin cuối. Advisory lock tuần tự hóa thay đổi, audit trước/sau, JWT token_version vô hiệu phiên cũ.
- `POST /users/me/change-password`: đổi mật khẩu, vô hiệu phiên cũ. Xem tên phương thức chính xác trong OpenAPI; không có gửi email/reset giả.
- `GET /staff/rooms/status`: lọc `tang`, `ma_lp`, `tinh_trang`, phân trang. `PATCH /staff/rooms/{id}/operational-status`: chuỗi vệ sinh, hoặc BAO_TRI có ngày/lý do và kỳ ngừng cùng transaction. Không tự bỏ qua lịch đặt. Kết thúc chỉ dừng kỳ ngừng gắn với lần bảo trì đó.
- `GET/POST /staff/bookings/{id}/payments`: thu tiền thực tế trên đơn đã xác nhận. `POST /admin/payments/{id}/refunds`: hoàn có liên kết giao dịch gốc. `request_id` UUID duy nhất; gửi lại cùng nội dung trả giao dịch cũ, đổi nội dung trả 409. Khóa phòng/phiếu bảo vệ hạn mức thu/hoàn. Không có sửa/xóa giao dịch.
- Booking detail bổ sung `da_thu`, `da_hoan`, `thu_rong`, `con_phai_thu`, `can_hoan_tien`. Hủy không tự hoàn tiền.
- `GET /admin/reports/revenue` và `/revenue/export`: `tu_ngay`, `den_ngay`, `mode=day|month`; export thêm `format=csv|pdf`. Tối đa 366 ngày bao gồm hai đầu, giờ Việt Nam chuyển khoảng UTC nửa mở. Zero-fill, thực thu theo ngày giao dịch; giá trị đặt/công nợ theo đơn tạo trong kỳ, được mô tả trên báo cáo. CSV BOM/chống formula injection, PDF font tiếng Việt/bảng/biểu đồ cùng tổng. `REPORT_FONT_PATH` mặc định Arial hệ thống Windows; môi trường khác phải cung cấp font Unicode có giấy phép phù hợp (ví dụ Noto Sans). Không đóng gói font Windows.
- `GET /notifications`, `/notifications/unread-count`; `PATCH /notifications/{id}/read`, `/notifications/read-all`: chỉ dữ liệu chủ tài khoản, phân trang. Event cùng transaction với đặt/chuyển trạng thái, dedup theo người nhận và sự kiện.
- `GET /auth/providers`; `POST /auth/google`, `/auth/facebook`; `GET /users/me/identities`; `POST/DELETE /users/me/identities/{provider}`: xác minh provider tại server, không tự liên kết bằng email. Social mới chỉ là khách; không unlink phương thức cuối.

## Giới hạn thông báo

Inbox làm việc với backend thật, polling 45 giây khi foreground và dừng khi background/logout. Nhắc cục bộ chỉ bật khi người dùng đồng ý quyền; 18:00 giờ Việt Nam trước ngày nhận cho đơn đã xác nhận, không exact alarm. Hủy lịch sau đồng bộ đơn hủy/từ chối hoặc logout. Nếu đơn thay đổi ở thiết bị khác lúc app này đóng, lịch cục bộ có thể chưa cập nhật. Chưa có FCM/push, chưa có OAuth credentials thật: không tuyên bố E2E các phần này.

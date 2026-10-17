# Chẩn đoán đăng nhập — 17/10/2026

## Trạng thái lúc kiểm tra

- SM A135F được ADB nhận đúng serial R58T801R8BD.
- Không có backend lắng nghe ở cổng 8000 hoặc 8001; kiểm tra HTTP ban đầu không có response/status code.
- `adb reverse --list` trống. App trên điện thoại dùng `API_BASE_URL=http://127.0.0.1:8000`, `DEMO_MODE=false`; localhost này cần ánh xạ USB tới máy tính.
- PostgreSQL 18 đang chạy, kết nối trực tiếp bằng `.env` tới đúng `hotel_booking` và `SELECT 1` thành công. Không chạy migration/seed/reset trong lần sửa lỗi kết nối này.

Đã chạy lại backend ở 127.0.0.1:8000 và `adb reverse tcp:8000 tcp:8000`. Chuỗi HTTP kiểm tra với thông tin demo đọc cục bộ từ `.env`: `/health`200, `/health/db`200, `POST /auth/login`200, `GET /users/me`200, `GET /admin/reports/revenue`200.

## Tái hiện và xác nhận trên SM A135F

Đã cài đè APK sửa lỗi và thao tác UI đăng nhập bằng tài khoản demo. Với ánh xạ USB tạm ngắt, log đúng tiến trình TTTP ghi `POST /auth/login -> TRANSPORT_ERROR (no HTTP status)`. Không gọi `/users/me`, không có HTTP lỗi server trong lần thử này. Ánh xạ được khôi phục trong finally của công cụ thử cục bộ.

Sau khôi phục và bấm đăng nhập lại, log điện thoại ghi:

```text
POST /auth/login -> HTTP 200
GET /users/me -> HTTP 200
GET /admin/reports/revenue -> HTTP 200
GET /notifications -> HTTP 200
GET /notifications/unread-count -> HTTP 200
```

Kết luận: lỗi được tái hiện ở request `/auth/login`, trước bước tải hồ sơ; nguyên nhân ban đầu là backend đã dừng và ánh xạ localhost USB đã mất. PostgreSQL và dữ liệu tài khoản vẫn hoạt động. Không phải lỗi `/users/me` hoặc dashboard. Ảnh sau đăng nhập: artifacts/tttp-login-fixed.png. Không lưu ảnh mật khẩu/token.

## Sửa mã

- ApiService chỉ bắt lỗi transport trong phạm vi gửi/nhận HTTP; giải mã response và callback phiên nằm ngoài catch transport.
- ApiError giữ method, path, status, code. HTTP lỗi với HTML/JSON sai cấu trúc giữ status thật; response thành công nhưng JSON lỗi dùng INVALID_RESPONSE. Không gán chúng thành lỗi mạng.
- Debug log chỉ có `[TTTP API] METHOD /path -> HTTP status` hoặc TIMEOUT/TRANSPORT_ERROR; không log body, header, query, mật khẩu hoặc token. Không in raw response xác thực.
- Phân biệt thông báo retry đăng nhập với POST tạo đơn có kết quả chưa rõ; không tự retry lệnh ghi dữ liệu.
- SessionProvider kiểm tra cấu trúc token/hồ sơ trước khi lưu; nếu `/users/me` lỗi thì chưa công bố đăng nhập thành công. Dữ liệu dashboard lỗi riêng không biến thành mất phiên đăng nhập.

17 kiểm thử Flutter đã qua, gồm lỗi transport ở login (không gọi /users/me), HTTP500 ở hồ sơ, HTML502, JSON hỏng, error sai kiểu, lỗi503 dữ liệu sau đăng nhập và kiểm tra log không có mật khẩu/email đầu vào. Flutter analyze không có vấn đề; APK build thành công.

## Chạy lại sau khi khởi động máy hoặc cắm USB

Chọn cấu hình VS Code **TTTP - SM A135F - API PostgreSQL** rồi F5. Pre-launch task gọi `scripts/start_phone_api.ps1`: kiểm tra health/database, chỉ khởi động backend khi cần, kiểm tra điện thoại và tạo lại ánh xạ USB. Đã chạy thử đúng lệnh pre-launch, kết quả health/database và ánh xạ điện thoại OK. Không dừng tiến trình không xác định hoặc sửa/reset DB. Nếu cổng8000 đã có tiến trình nhưng health không tốt, script báo rõ để kiểm tra log.

Có thể chạy script từ thư mục gốc:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_phone_api.ps1
```

Giữ USB và backend khi dùng APK localhost. Việc bật Wi-Fi không thay thế ánh xạ này. Log backend: backend/server.stdout.log (status/request path) và server.stderr.log. APK cập nhật: artifacts/tttp-login-fix-SM-A135F-debug.apk, cài đè giữ dữ liệu; không uninstall/clear storage.

# Kiểm thử và giới hạn môi trường

Ngày triển khai: 17/10/2026. Xem kết quả cuối trong [STATUS.md](STATUS.md).

## Không cần database/thiết bị

Từ `backend`: `.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider`.
Unit test kiểm tra ngày VN, 1–30 đêm, sức chứa, quyền chuyển trạng thái/hạn hủy, chặn mass assignment, normalize email nhưng giữ nguyên mật khẩu, Argon2, token hết hạn, metadata PostgreSQL, từ chối cấu hình SQLite/secret thiếu, health/OpenAPI không mở DB.

Từ gốc Flutter: `flutter analyze`, `flutter test`.
Test JSON phân trang, request không chứa giá/quyền khách tự chèn, HTTP JSON/bearer/lỗi, 401 xóa token, Provider dừng loading khi lỗi, demo gắn nhãn không có nút đặt, form đăng nhập không gửi request khi chưa hợp lệ.

## PostgreSQL thật — chỉ database test riêng

Đã chạy trên PostgreSQL 18.6: **31 test đạt**, gồm 15 test PostgreSQL và 16 unit test, không skip. Có luồng HTTP đăng nhập → tìm → quote → đặt → nhân viên xác nhận → khách refresh → hủy.

Fixture từ chối URL không có driver `postgresql+psycopg` hoặc tên DB khác chính xác `hotel_booking_test`. Kiểm tra thêm `current_database()` trước TRUNCATE.
Fixture migrate rồi **TRUNCATE dữ liệu nghiệp vụ** của DB test trước mỗi test. Không trỏ vào DB người dùng; không tự chạy khi mở server.

```powershell
cd backend
.\.venv\Scripts\python.exe manage_local.py test-postgres
```

Runner lấy mật khẩu từ cấu hình cục bộ, chỉ đưa URL hotel_booking_test vào subprocess test; so sánh dấu vân tay hotel_booking trước/sau, đã xác nhận không đổi. Thư mục tạm dưới backend/.test-runs; trên Windows cần quyền filesystem cho pytest. Không in password/token ra kết quả test.

Các test đã chạy đạt: đăng ký/email trùng/login sai/chèn quyền, đặt và giá chốt/lịch sử, hai trạng thái giữ phòng, hủy/từ chối giải phóng lịch, hai kỳ liền nhau, quyền sở hữu/phân quyền, sức chứa, phòng ẩn/kỳ ngừng, deferred profile và ảnh bìa unique, rollback khi lỗi ghi lịch sử, upload giả/quá lớn/traversal/thay bìa, ba cuộc đua dùng hai kết nối độc lập với barrier: đặt–đặt, đặt–ngừng, hủy–xác nhận.

Hủy và xác nhận cạnh tranh có thể cùng thành công theo thứ tự hợp lệ `chờ → xác nhận → hủy`; test cho phép trường hợp này, nhưng không cho ghi đè trạng thái không hợp lệ.

## Kiểm chứng điện thoại và phần còn lại

SM A135F đã chạy app với DEMO_MODE=false qua USB reverse, tải danh mục/phòng trống/ảnh từ backend thật với HTTP 200. Đã quan sát ảnh chụp giao diện thật. Luồng nhiều tài khoản đã đạt qua HTTP với PostgreSQL test, chưa thao tác toàn bộ qua UI điện thoại. Checklist UI còn lại:

1. Migrate và seed DB phát triển; chạy toàn bộ test trên DB test riêng.
2. Khách 1 đăng nhập, tìm ngày tương lai, báo giá, đặt; xác minh ID và giá server.
3. Lễ tân đăng nhập, lọc phiếu chờ, xác nhận; khách làm mới và thấy trạng thái/lịch sử mới.
4. Khách 2 không đọc/hủy được phiếu khách 1; lễ tân không quản lý danh mục.
5. Thử lỗi mạng/timeout sau gửi: không báo thành công giả, không tự retry POST; kiểm tra Đơn của tôi trước khi gửi lại.
6. Kiểm tra secure storage sau đóng/mở, đăng xuất, token hết hạn điều hướng đăng nhập, layout/bàn phím, chọn ảnh và permissions trên Android.
7. Quản lý thêm/sửa/ẩn loại/phòng, tiện nghi/ảnh bìa, lịch ngừng; xác minh xung đột và sức chứa bằng DB thật.

Đây là các bước chưa chạy, không phải kết quả đã đạt. Bộ test hiện chưa bao phủ tự động toàn bộ TC01–TC29; đặc biệt cần bổ sung E2E thiết bị, deadline gần nửa đêm VN và thao tác đồng thời hai nhân viên cùng xử lý một phiếu.

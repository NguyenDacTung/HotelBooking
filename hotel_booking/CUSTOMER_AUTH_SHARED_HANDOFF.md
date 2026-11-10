# Bàn giao Customer, Auth, Shared – HotelBooking TETRA

## Phạm vi

Giữ nguyên giao diện, các chức năng và nghiệp vụ đang có. Không thay đổi cấu trúc cơ sở dữ liệu.

## Các thay đổi trong bản bàn giao này

1. `lib/services/api_service.dart`: chỉ kích hoạt xử lý phiên hết hạn khi yêu cầu có gửi token đang được sử dụng; phản hồi cũ và HTTP 401 khi chưa đăng nhập không làm đăng xuất. Token được xóa trước callback để tránh xử lý trùng.
2. `lib/app/app_root.dart`: chặn điều hướng đăng nhập lặp lại; không điều hướng khi chỉ đang kiểm tra phiên lúc khởi động; không giữ callback HTTP chờ cho đến khi người dùng rời màn hình đăng nhập.
3. `lib/providers/booking_provider.dart`: mỗi lần tải mới có phiên bản yêu cầu riêng; kết quả cũ không được ghi đè bộ lọc mới. Giữ quy tắc chỉ một yêu cầu phân trang mỗi lần.
4. `lib/screens/customer/my_bookings_screen.dart`: cho phép thay đổi bộ lọc ngay khi đang tải, mở rộng dropdown theo chiều ngang để tránh tràn trên màn hình hẹp. Không thay đổi màu sắc và bố cục.
5. `lib/core/config.dart`: địa chỉ API mặc định là `http://192.168.2.2:8000` theo mạng Wi-Fi lúc kiểm thử. Có thể ghi đè bằng `--dart-define=API_BASE_URL=http://<IP-MAY-TINH>:8000` khi IP thay đổi.
6. `test/customer_auth_shared_regression_test.dart`: ba kiểm thử cho HTTP 401 và kết quả API cũ.

## Các thay đổi được giữ lại từ bản đã sửa trước

- Khôi phục/đăng xuất phiên trong `session_provider.dart`.
- Xử lý trạng thái tìm phòng trong `search_provider.dart`.
- Các trường hợp đặt phòng/thanh toán trong `booking_review_screen.dart`, `online_payment_screen.dart`, `booking_detail_screen.dart`.
- Làm mới dữ liệu liên kết tài khoản trong `linked_accounts_screen.dart`.
- `test/customer_flow_regression_test.dart`.

## Chạy và xác minh trên Windows

Backend: trong `hotel_booking/backend`, tạo `.env` riêng (không commit), chạy Uvicorn với host `0.0.0.0` để điện thoại thật kết nối qua LAN.

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Flutter: trong `hotel_booking`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://192.168.2.2:8000
```

Nếu Run từ Android Studio, kiểm tra các `Additional run args`: `API_BASE_URL` được truyền tại đây sẽ ghi đè địa chỉ mặc định. Khi đổi mạng, kiểm tra IP máy tính bằng `ipconfig`.

**Trước khi đẩy GitHub:** `git status --short` và `git ls-files backend/.env` (kết quả sau phải rỗng). Tuyệt đối không commit `.env`, token, mật khẩu, các tệp trong `backend/.venv` hay thư mục `build`.

## Giới hạn xác minh

Đã kiểm tra mã nguồn và chuẩn bị test; môi trường đóng gói không có Flutter SDK, nên chưa chạy được `flutter analyze`, `flutter test` hoặc kiểm thử điện thoại thật. Các luồng Auth/Customer/Shared được người sử dụng báo đã kiểm thử cơ bản; **chưa thể xác nhận hoàn thiện 100% mọi tình huống**. Lỗi Facebook SDK đã thấy trong log cần kiểm tra cấu hình Facebook nếu ứng dụng dùng đăng nhập Facebook. Các ảnh phòng chưa được bổ sung vì ngoài phạm vi bàn giao này.

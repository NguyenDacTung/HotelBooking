# Đối chiếu học phần với mã TTTP

Đối chiếu danh sách trong đặc tả nâng cấp; chưa có slide gốc được mở/đọc trong workspace. Phiên bản chính xác được khóa trong pubspec.lock. Không thêm thư viện chỉ để đủ số lượng.

| Nhóm | Package / nơi dùng | Lý do và kiểm tra |
| --- | --- | --- |
| Hiệu ứng | shimmer 3.0.0 — search_screen; flutter_animate 4.5.2 — home_screen | Skeleton tải dữ liệu, chuyển động nhẹ có xét giảm chuyển động |
| Slider/lịch | carousel_slider 5.1.2 — home_screen; showDateRangePicker Flutter — search_form/review | Banner và chọn khoảng ngày thực; không cài hai thư viện carousel |
| Ảnh | cached_network_image 3.4.1 — common; image_picker — room_images_screen; easy_image_viewer 1.5.1 — room_detail | Cache/placeholder, admin upload, zoom; không thêm editor |
| File | path_provider 2.1.6, share_plus 11.1.0 — export_service | Tải CSV/PDF server vào file tạm và chia sẻ qua Android, không quyền toàn bộ bộ nhớ |
| Hệ thống | connectivity_plus 6.1.5 — connectivity_banner; url_launcher 6.3.3 — home_screen | Banner nhắc trạng thái mạng không thay kết quả API; hotline/map chỉ có khi cấu hình |
| Media | Không thêm | Không có nghiệp vụ audio/video/record |
| Thông báo | flutter_local_notifications 19.5.0 + timezone 0.10.1 — reminder_service; badge Material | Nhắc inexact theo giờ Việt Nam; plugin tự xin quyền theo hành động người dùng |
| Push/thanh toán | Inbox FastAPI + ledger PostgreSQL, uuid 4.6.0 — payments_screen | Thu thủ công có request ID; chưa FCM/Momo/VNPAY, không coi local là push |
| Bản đồ | url_launcher | Mở bản đồ ngoài khi có vị trí, không GPS/Google Maps SDK |
| Camera/mã | image_picker | Chọn ảnh phòng; không quét mã/giấy tờ |
| Bảo mật | flutter_secure_storage — token_storage; Google/FB SDK — social_login_service | JWT lưu an toàn; phân quyền trên backend; OAuth thật chờ cấu hình |
| Biểu đồ | fl_chart 1.2.0 — dashboard/revenue_report | Thu/hoàn/ròng và trạng thái; server tổng hợp |
| Lưu cục bộ | shared_preferences 2.5.6 — notifications_provider | Chỉ tùy chọn nhắc theo tài khoản; không lưu mật khẩu/JWT vào preferences |
| Launcher | flutter_launcher_icons 0.14.4 — pubspec | Sinh tài nguyên build từ logo người dùng, không phụ thuộc runtime |

Dependencies backend: google-auth xác minh Google, httpx xác minh Meta, reportlab xuất PDF và thư viện csv chuẩn. requirements.lock.txt ghi phiên bản môi trường cục bộ. Giấy phép các package được cung cấp bởi tác giả trên pub.dev và LICENSE trong cache; Flutter có LicenseRegistry để hiển thị khi phát hành. Không sao chép font thương mại. Việc compile/analyze và test được ghi trong acceptance_checklist.md; không mặc định coi mọi tích hợp đã E2E chỉ vì package đã cài.

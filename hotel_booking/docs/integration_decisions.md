# Quyết định tích hợp TETRA — 18/10/2026

Hai tài liệu gốc được lưu cùng thư mục. Yêu cầu trực tiếp mới nhất của chủ dự án được ưu tiên khi đặc tả cũ khác hệ thống hiện hành.

| Chủ đề | Quyết định và căn cứ |
|---|---|
| Tên | Trong giao diện: TETRA. Nhãn Android: TETRA Hotel. Giữ `com.example.hotel_booking`, tên package Dart và các khóa lưu trữ `tttp_*` để bảo toàn cập nhật tại chỗ. Không đổi email/tài khoản hoặc mật khẩu đã có. |
| Lý do | Tất cả trường lý do là tùy chọn, kể cả ẩn đánh giá, hủy/từ chối, đổi phòng, hoàn tiền và tạm ngừng. Bỏ hộp lý do nhận/trả phòng. Actor, thời điểm và trước/sau vẫn có audit. Nội dung dịch vụ phụ thu, số tiền, quyền và điều kiện nghiệp vụ vẫn được kiểm tra. |
| Đánh giá | Dùng `DA_HOAN_TAT` cùng `tra_phong_luc` thực tế, không tạo trạng thái hoàn tất mới. Một đánh giá/đơn bằng UNIQUE và khóa PostgreSQL; không dùng ngày trả dự kiến để tự mở đánh giá. |
| Ảnh | Ảnh thuộc phòng theo yêu cầu đã chốt, không chuyển lại về loại phòng. Avatar dùng cùng chuỗi chọn/chụp–crop–preview–upload; URL mới theo UUID. Ảnh góp ý lưu riêng ngoài `/uploads`. |
| Toast | Không dùng `toast_notification 1.0.0`: mã gói cố định vị trí cách đáy 50 px, Timer gọi setState không kiểm tra mounted/không hủy trong dispose; có thể che thanh điều hướng và lỗi khi đóng màn. Giữ một hàng đợi SnackBar nổi từ ScaffoldMessenger, ẩn thông báo cũ khi có thông báo mới. EasyLoading dùng cho tác vụ nhập CSV, có finally dismiss. |
| Điều hướng | Giữ NavigationBar nổi xanh/vàng đã được người dùng chọn. Không thêm convex_bottom_bar hoặc thanh thứ hai. Drawer dùng chung theo vai trò, các mục chính vẫn ở bottom bar. |
| Badge | Tái sử dụng Material Badge có sẵn, số chưa đọc từ server; không thêm gói badges trùng chức năng. |
| Lịch | table_calendar và easy_date_timeline dùng cùng ngày chọn trong lịch nhân viên; picker ngày lưu trú hiện tại được giữ nguyên. API giới hạn 93 ngày, ngày trả không chiếm đêm. |
| Build Android | file_picker 11.0.3 bỏ KGP chỉ dựa vào AGP≥9, trong khi dự án tắt built-in Kotlin vì các plugin hiện có. Lỗi native xác minh bằng compileDebugJavaWithJavac: không tìm thấy FilePickerPlugin. `android/build.gradle.kts` áp dụng KGP riêng cho file_picker khi cờ built-in=false, giữ Java/Kotlin target 17; không sửa pub cache hoặc nâng mọi thư viện. |
| PDF | pdfrx (MIT, xem cache package/lockfile) cho xem trước báo cáo server; giữ reportlab/fl_chart/export cũ. Tệp ứng dụng nằm trong thư mục tạm riêng, được xóa khi đăng xuất; bản người dùng đã chia sẻ/lưu ra ngoài do người dùng quản lý. |
| Map | Pin flutter_osm_plugin 1.4.6: bản 2.1.0+1 kéo mapscore 3.7.1 yêu cầu minSdk 26, manifest merger đã xác minh xung đột minSdk 24 của dự án. Không dùng overrideLibrary hoặc nâng minSdk chỉ để ép gói. Bản 1.4.6 không có phụ thuộc mapscore đó; bridge KGP trong root áp dụng cho plugin khi built-in Kotlin=false. Một flutter_osm_plugin với điểm cố định trong đặc tả; không tự bịa địa chỉ/hotline. Geolocator chỉ xin khi bấm tính khoảng cách thẳng, chỉ đường mở ứng dụng ngoài. Không cache hàng loạt tile. |
| WebView | Không thêm một trình duyệt WebView khi chưa có nội dung website chính sách đáng tin cần hiển thị. Cổng thanh toán mở ngoài bằng HTTPS/allowlist; trang return không chứng minh đã thu tiền. |
| Video | Chỉ hiện khi admin có URL video HTTPS trực tiếp; không dùng URL trang YouTube hoặc video giả. Không cấu hình thì không tạo khung video trống ở trang khách. |
| Image editor | Crop/preview cùng xử lý định hướng từ picker đáp ứng chọn ảnh hiện tại; không thêm bộ chỉnh sửa ảnh tổng hợp. |
| QR | mobile_scanner + qr_flutter; mã tham chiếu UUID, không PII/JWT. Không tự nhận/trả phòng hoặc thu tiền sau quét. Nhập mã thủ công vẫn dùng được nếu camera bị từ chối. |
| Đăng nhập vân tay (thay đổi tiếp theo ngày 18/10) | Theo yêu cầu mới, bỏ LocalSessionGate và yêu cầu quét sau mật khẩu. Đăng ký thiết bị một lần bằng mật khẩu hiện tại + sinh trắc; Android Keystore P-256/BiometricPrompt CryptoObject ký challenge một lần, backend xác minh và cấp JWT mới. Khóa riêng không rời thiết bị, không lưu mật khẩu; 90 ngày, thu hồi/đổi mật khẩu/quyền được kiểm tra. Xem profile_biometric_acceptance.md. |
| Feedback | BetterFeedback chỉ bao màn góp ý riêng; không tự chụp trang đăng nhập/hồ sơ/thanh toán. Người gửi xem lại và bỏ ảnh trước khi gửi; metadata opt-in chỉ model/OS/app version. |
| Thanh toán | API backend MoMo `payWithMethod`, VNPAY 2.1.0; không dùng SDK giả. Cho đơn xác nhận/đang ở/chờ trả phòng còn nợ, phù hợp hóa đơn phụ thu đã chốt trước đây. Mỗi đơn một attempt hoạt động; lưu trước network, không giữ khóa DB trong I/O. Timeout không tự tạo giao dịch mới hoặc tự thu tiền. |
| Sandbox | Ledger có `environment`; sandbox không giảm công nợ, không vào doanh thu thật, không được hoàn bằng tiền thật. Production đến muộn sau hủy vẫn ghi nhận số đã thu để xử lý khoản cần hoàn, không phục hồi đơn. |
| Dịch vụ ngoài | Thiếu OAuth/SMTP/Firebase/merchant không phải lý do bỏ mã; chuẩn bị cấu hình và adapter. Chưa có credentials thì UI ghi rõ trạng thái. Hoàn tiền tự động gateway chưa bật; hoàn thủ công vẫn phải là tiền đã hoàn thực tế và có audit. |
| Không thêm | Không AI/ML/Tools, InAppPurchase, Firebase Auth/Firestore thay backend PostgreSQL, nhiều scanner/map/notifier cho một việc. |

Những giới hạn nghiệm thu và thao tác thiết bị/dịch vụ thực tế được ghi ở `integration_acceptance.md`. Không suy diễn test giao thức bằng fixture thành thanh toán merchant thành công.

### Bản đồ sau QA điện thoại

SM A135F mở native map nhưng nhận tile lỗi 403. Mặc định package ví dụ không nhận diện TETRA rõ ràng. MainActivity thiết lập User-Agent TETRAHotel/version trước khi plugin khởi tạo, giữ preference khi map reload; URL tile dùng HTTPS canonical. Cache tile mới ở cache riêng ứng dụng, không xóa dữ liệu hay phiên đăng nhập. Đã cài lại và xác nhận bản đồ/ghim hiển thị đúng trên SM A135F; ảnh `artifacts/QA-TETRA-map-fixed.png`. Chính sách nguồn: https://operations.osmfoundation.org/policies/tiles/ ; khóa cấu hình osmdroid: https://github.com/osmdroid/osmdroid/blob/osmdroid-parent-6.1.20/osmdroid-android/src/main/java/org/osmdroid/config/DefaultConfigurationProvider.java .

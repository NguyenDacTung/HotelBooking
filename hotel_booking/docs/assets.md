# Tài sản giao diện TTTP

| File | Nguồn / mục đích |
| --- | --- |
| assets/images/tttp_app_icon.png | Logo người dùng cung cấp; giữ nguyên ảnh gốc 1254×1254 |
| auth-hotel.jpg | Pexels, ảnh 271624, nền đăng nhập |
| banner-deluxe.jpg | Pexels, ảnh 164595, banner minh họa |
| banner-family.jpg | Pexels, ảnh 271639, banner minh họa |

Ảnh chụp không khẳng định là ảnh một cơ sở TTTP đã khảo sát. Nguồn: https://www.pexels.com/photo/271624/ , https://www.pexels.com/photo/164595/ , https://www.pexels.com/photo/271639/ . Giấy phép: https://www.pexels.com/license/ .

Ngày 18/10/2026 bổ sung ảnh chụp thật `assets/room_photos/pexels-262048.jpg`, `pexels-271618.jpg`, `pexels-271619.jpg`, nguồn https://www.pexels.com/photo/262048/ , https://www.pexels.com/photo/271618/ , https://www.pexels.com/photo/271619/ . Đã kiểm tra bằng mắt là ảnh phòng ngủ. Ảnh do Pexels cho phép sử dụng trên ứng dụng theo giấy phép trên, không phải ảnh AI.

`python -m app.seed_operations --replace-room-images` thêm danh mục và sao chép ảnh vào uploads từng phòng, cập nhật `anh_phong`. Chỉ chạy cờ thay ảnh khi chủ dự án yêu cầu. Metadata ảnh cũ giữ trong `anh_phong_archive`/`anh_loai_phong_legacy`, file cũ không xóa. Chạy lặp không tạo ảnh trùng. Khi triển khai cơ sở thật, quản lý thay ảnh từng phòng bằng ảnh do cơ sở cung cấp, kiểm tra ảnh khớp số giường/tiện nghi thực tế; seed hiện là dữ liệu danh mục dùng để trình diễn.

Launcher Android sinh bằng `flutter_launcher_icons 0.14.4` (MIT), cấu hình trong pubspec.yaml. Chạy lại `dart run flutter_launcher_icons` sau khi đổi logo. Mật độ mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi có icon 48/72/96/144/192 px. Adaptive icon Android 26+ có foreground theo mật độ, nền xanh `#103B54`, inset 16%; logo có khoảng trống gốc và inset bổ sung để nằm trong vùng an toàn khi launcher dùng mặt nạ tròn/squircle. Không đổi applicationId `com.example.hotel_booking`; nhãn TTTP. Icon thông báo `ic_stat_tttp.xml` đơn sắc riêng, không dùng logo vuông cho status bar.

Report PDF đọc font hệ thống do người triển khai cấu hình, không phân phối Arial của Windows trong repo. Flutter giữ bộ font mặc định có hỗ trợ tiếng Việt. Xem giấy phép package trong cache/pub.dev; có thể tạo danh mục khi phát hành bằng `flutter pub licenses` nếu SDK hỗ trợ hoặc trang AboutLicense Flutter.

Ảnh hai giường: https://www.pexels.com/photo/2029722/ , https://www.pexels.com/photo/29000012/ ; ảnh gia đình hai giường lớn: https://www.pexels.com/photo/34763215/ . Lưu tại assets/room_photos, áp dụng cùng giấy phép Pexels; đã xem ảnh kiểm tra số giường trước seed.

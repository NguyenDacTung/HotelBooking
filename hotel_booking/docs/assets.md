# Tài sản giao diện TTTP

| File | Nguồn / mục đích |
| --- | --- |
| assets/images/tttp_app_icon.png | Logo người dùng cung cấp; giữ nguyên ảnh gốc 1254×1254 |
| auth-hotel.jpg | Pexels, ảnh 271624, nền đăng nhập |
| banner-deluxe.jpg | Pexels, ảnh 164595, banner minh họa |
| banner-family.jpg | Pexels, ảnh 271639, banner minh họa |

Ảnh khách sạn chỉ minh họa, không khẳng định là ảnh cơ sở TTTP thật. Nguồn: https://www.pexels.com/photo/271624/ , https://www.pexels.com/photo/164595/ , https://www.pexels.com/photo/271639/ . Giấy phép: https://www.pexels.com/license/ . Ảnh upload phòng vẫn do backend phục vụ, không thay ảnh hiện có trong DB.

Launcher Android sinh bằng `flutter_launcher_icons 0.14.4` (MIT), cấu hình trong pubspec.yaml. Chạy lại `dart run flutter_launcher_icons` sau khi đổi logo. Mật độ mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi có icon 48/72/96/144/192 px. Adaptive icon Android 26+ có foreground theo mật độ, nền xanh `#103B54`, inset 16%; logo có khoảng trống gốc và inset bổ sung để nằm trong vùng an toàn khi launcher dùng mặt nạ tròn/squircle. Không đổi applicationId `com.example.hotel_booking`; nhãn TTTP. Icon thông báo `ic_stat_tttp.xml` đơn sắc riêng, không dùng logo vuông cho status bar.

Report PDF đọc font hệ thống do người triển khai cấu hình, không phân phối Arial của Windows trong repo. Flutter giữ bộ font mặc định có hỗ trợ tiếng Việt. Xem giấy phép package trong cache/pub.dev; có thể tạo danh mục khi phát hành bằng `flutter pub licenses` nếu SDK hỗ trợ hoặc trang AboutLicense Flutter.

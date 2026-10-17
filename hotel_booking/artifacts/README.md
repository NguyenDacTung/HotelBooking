# APK kiểm tra

`hotel-booking-api-SM-A135F-debug.apk`: bản API thật, DEMO_MODE=false, đã cài/chạy trên SM A135F (ARM 32 bit). API http://127.0.0.1:8000 qua `adb reverse tcp:8000 tcp:8000`, cần backend chạy trên máy. Khởi chạy/tải phòng/ảnh đã được kiểm tra; chưa thao tác đủ luồng nhiều tài khoản bằng UI điện thoại.

`SM-A135F-api.png`: ảnh chụp app trên điện thoại, hiện 12 phòng thật từ database seed qua API.

`hotel-booking-demo-debug.apk`: bản Android debug, bật DEMO_MODE=true, chỉ xem giao diện phòng mẫu; không gọi backend, không đăng nhập/đặt phòng và không lưu dữ liệu thật. Chưa chạy trên điện thoại/emulator.

APK được build từ mã nguồn, không được commit vào source. Sau build có thể chép từ `build/app/outputs/flutter-apk/app-debug.apk` vào đây; đọc STATUS để biết artifact đã được tạo hay chưa.

Bản dùng API thật: build lại tại gốc với `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000` (emulator), không đặt DEMO_MODE. Điện thoại thật đổi sang IPv4 LAN máy backend. Release cần HTTPS và signing riêng. APK không bao gồm backend/PostgreSQL.

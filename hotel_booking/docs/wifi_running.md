# Chạy TTTP qua Wi-Fi — 17/10/2026

## Nguyên nhân lỗi cũ

Đã tái hiện trên SM A135F: `POST /auth/login -> TRANSPORT_ERROR (no HTTP status)`, chưa tới `/users/me`. Khi kiểm tra ban đầu backend không chạy và `adb reverse --list` trống. PostgreSQL vẫn chạy, kết nối trực tiếp đúng hotel_booking thành công. Không có bằng chứng lỗi cũ do token/JSON/PostgreSQL; nguyên nhân là đường tới backend không hoạt động.

Bản USB cũ gọi `http://127.0.0.1:8000`; localhost trên điện thoại cần `adb reverse`. Khởi động lại server và tạo lại reverse khắc phục tình trạng lúc đó, chưa loại bỏ sự phụ thuộc USB. Việc phân loại ApiError và thêm trace an toàn giúp sửa chẩn đoán/thông báo, không tự làm backend luôn sẵn sàng.

## Cấu hình mới

- APK Wi-Fi đã build với `DEMO_MODE=false`, `API_BASE_URL=http://192.168.31.112:8000`, giữ applicationId/dữ liệu app. Sau sự cố cài lại bản localhost lúc19:34, source mặc định cũng được đổi sang IP LAN này để chạy từ IDE không có dart-define vẫn dùng Wi-Fi. Cấu hình USB/emulator phải truyền URL riêng; giá trị thực được log lúc khởi tạo ApiService.
- Máy tính WiFi Private: 192.168.31.112. Điện thoại sau khi người dùng đổi mạng: 192.168.31.50. Backend nghe `0.0.0.0:8000`; điện thoại gọi IP LAN, không gọi 0.0.0.0.
- Luật `TTTP-Local-API-Private-WiFi`: TCP8000 inbound, chỉ Private, interface WiFi, local192.168.31.112, remote LocalSubnet. Đã tạo bằng quyền Administrator qua UAC và đọc lại các bộ lọc. Không tắt Firewall, không thêm luật PostgreSQL5432.
- Database chỉ được backend truy cập bằng cấu hình .env tại127.0.0.1:5432/hotel_booking. Điện thoại không kết nối trực tiếp DB. PostgreSQL đã có cấu hình listen trên các interface từ trước; lần này không thay cấu hình hay mở Firewall5432.
- Đã gỡ reverse8000 khi thử bản Wi-Fi. Backend log thấy client192.168.31.50 và đăng nhập/hồ sơ/dashboard/inbox200. USB chỉ còn dùng để cài/debug/điều khiển và lấy bằng chứng trong lúc thử.

## Đã kiểm chứng và giới hạn

| Phép thử | Kết quả |
| --- | --- |
| Đăng nhập / hồ sơ / dữ liệu sau login qua USB sau sửa lỗi cũ | 200 / 200 / 200 trên điện thoại |
| Đăng xuất / đăng nhập lại qua Wi-Fi | Đã thao tác nhiều lần trên SM A135F; POST /auth/login và GET /users/me200 |
| Tải danh sách phòng qua Wi-Fi | GET /room-types200 và GET /rooms/available200 trên SM A135F, không có reverse8000; backend nhận từ192.168.31.50 |
| Token thật hết hạn gửi tới API thật | /users/me401, không gán thành lỗi mạng |
| Restart backend với JWT còn hạn, giữ .env | JWT cũ lấy hồ sơ200; đăng nhập mới200 |
| Dữ liệu hotel_booking trước/sau phép thử restart | Fingerprint từng bảng không đổi |
| Khôi phục phiên sau mở app / xóa token khi401 | Force-stop rồi mở lại TTTP trên SM A135F: GET /users/me200, không POST login lại; Flutter test xóa token khi401 đã đạt |
| Flutter | 19 tests passed; analyze sạch; APK Wi-Fi build thành công |
| Luồng đặt phòng trên PostgreSQL test riêng | 1 test HTTP end-to-end đăng nhập/tìm/quote/tạo/xác nhận/hủy đã qua; 42 test khác không chạy lại trong phép thử chọn lọc này; hotel_booking không đổi |
| Rút cáp vật lý | Người dùng đã xác nhận rút USB thật vẫn mở được health, đăng nhập và tải phòng; phân biệt với kiểm tra tự động không có reverse |
| Đặt phòng mới trên database phát triển qua Wi-Fi | Chưa tạo thêm đơn trong lần kiểm tra này; không tuyên bố đã xác minh thao tác submit trên điện thoại |

Không có refresh token tự động. Token hết hạn/khóa tài khoản/đổi quyền/đổi mật khẩu sẽ yêu cầu đăng nhập lại. Backend tắt, máy tính sleep, PostgreSQL dừng, Wi-Fi khác mạng/guest isolation, đổi IP, Firewall đổi sang Public đều có thể làm mất kết nối. Không thể cam kết không bao giờ gặp lại lỗi mạng.

## Lần sau bật máy tính

PostgreSQL service `postgresql-x64-18` được kiểm tra là **Running, StartMode=Auto**. Không cần mở pgAdmin. Backend chưa được cài thành Windows service và không tự chạy cùng Windows. Mở PowerShell tại thư mục gốc dự án và chạy:

```powershell
cd 'C:\Mobie app dev\HotelBooking\hotel_booking'
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Lan -ExpectedLanAddress 192.168.31.112
```

Script kiểm tra WiFi Private và /health/db, khởi động backend ẩn nếu chưa chạy. Script không migration/seed/reset DB và không cần điện thoại/ADB cho chế độ LAN. Nếu đang có backend localhost do phiên USB cũ, dùng thêm `-Restart`; script chỉ dừng tiến trình khớp PID và command line của chính dự án. Nếu health lỗi hoặc cổng do tiến trình khác giữ, script báo và giữ nguyên tiến trình đó. Log: backend/server.stdout.log và server.stderr.log. Kiểm tra `http://192.168.31.112:8000/health/db` phải có database connected.

Sau đó mở TTTP trên điện thoại cùng Wi-Fi, không cần VS Code/USB để dùng APK đã cài. Máy tính và backend phải tiếp tục chạy.

Để chạy/debug/cài lại bằng VS Code, chọn **TTTP - WiFi LAN - API PostgreSQL**. Pre-launch kiểm tra backend và IP khớp APK; cài/debug lần đầu vẫn cần điện thoại được ADB nhận. Cấu hình **TTTP - USB localhost (chi dung khi cam cap)** là bản USB localhost riêng, không dùng khi cần rút cáp.

Firewall đã cấu hình một lần. Nếu cần tạo lại sau đổi IP, chạy PowerShell **Administrator**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\configure_private_firewall.ps1
```

ExecutionPolicy ở đây chỉ áp dụng tiến trình chạy script, không thay chính sách toàn máy. Script từ chối mạng không Private; không yêu cầu đổi mạng công cộng thành Private.

IP máy tính có thể thay đổi do DHCP. Khi đó cần IP đặt trước trong DHCP của router hoặc cập nhật API_BASE_URL trong launch.json và build/cài lại APK, đồng thời cập nhật rule Firewall. Start task Wi-Fi có kiểm tra ExpectedLanAddress để không âm thầm chạy sai IP. Không tự sửa router trong lần này.

## Tự thử sau khi rút cáp

1. Giữ máy tính/backend chạy; điện thoại ở cùng Wi-Fi, tạm tắt dữ liệu di động nếu cần loại trừ đường khác.
2. Rút USB; trên trình duyệt điện thoại mở `http://192.168.31.112:8000/health/db` — cần thấy status ok/database connected.
3. Mở TTTP, đăng xuất/đăng nhập lại, tìm phòng với ngày/số khách hợp lệ, mở chi tiết và xem báo giá. Khi muốn tạo đơn thật mới bấm Xác nhận đặt phòng; không gửi lặp nếu timeout, kiểm tra Đặt phòng của tôi trước.
4. Đóng rồi mở lại app: phiên còn hạn phải lấy lại hồ sơ. Nếu401 thì đăng nhập lại; nếu không mở được health thì kiểm tra backend/mạng trước, không reset DB.

APK: artifacts/tttp-wifi-SM-A135F-debug.apk. Bằng chứng chi tiết cũ: login_connection_fix.md; log trước đổi LAN đã sao lưu cục bộ, không chứa credential payload.

## Sự cố cài lại bản localhost lúc 19:34

Kiểm tra lại lúc19:38 cho thấy backend/PostgreSQL và IP LAN vẫn tốt, /health/db, /auth/login, /users/me và tìm phòng từ máy tính đều200. Điện thoại vẫn192.168.31.50, nhưng app vừa cập nhật19:34 log baseUrl=http://127.0.0.1:8000; /auth/login, /room-types, /bookings/my, /rooms/available lỗi TRANSPORT_ERROR không có HTTP status. Đây là cấu hình app bị quay về localhost khi build/chạy lại, khác sự cố backend dừng trước đó.

Đã đổi defaultValue của API_BASE_URL trong lib/core/config.dart sang IP LAN192.168.31.112; profile USB vẫn có override riêng và được đổi tên rõ là chỉ dùng khi cắm cáp. Bản mới được build không truyền API_BASE_URL để kiểm tra đúng hành vi chạy từ IDE không có define.19 Flutter tests đạt; tài liệu Word bàn giao cập nhật theo giá trị mặc định mới. Không thay đổi DB hay Firewall trong lần sửa này.

Đã cài đè và xác minh thực tế lúc19:43: log điện thoại baseUrl=http://192.168.31.112:8000; POST/auth/login200, GET/users/me200, dashboard/inbox/unread-count200. Không có adb reverse trong phép thử, dữ liệu ứng dụng được giữ.

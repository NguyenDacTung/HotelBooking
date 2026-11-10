# Kiểm tra cấu hình và kiểm thử

## Cập nhật 11/11/2026: thống nhất `flutter run`

- Android build tự đọc `config/flutter.local.json`, dùng mẫu trống nếu chưa có file local. Cấu hình public được dùng chung cho Dart và SDK native; từ chối trường lạ, kiểu dữ liệu sai, Firebase thiếu trường, Facebook bật nhưng thiếu ID/token và URL API có credentials/query/fragment. Không đọc hoặc nhúng `backend/.env`.
- Trước khi tạo dịch vụ, Flutter nhận cấu hình native qua platform channel. Các cờ `--dart-define` vẫn ưu tiên, kể cả chuỗi rỗng hoặc `FACEBOOK_ENABLED=false`.
- Khi `API_BASE_URL` trống hoặc không có: emulator dùng `10.0.2.2:8000`, điện thoại USB dùng `127.0.0.1:8000`. Build debug thiết lập ADB reverse cho điện thoại USB đã cấp quyền. Backend vẫn chạy riêng; không thay firewall, migration hoặc seed.
- README, hướng dẫn dịch vụ và cấu hình F5 có cách chạy USB/Emulator thống nhất. Script LAN/USB cũ vẫn được giữ.

| Kiểm tra trong lượt cập nhật này | Kết quả |
| --- | --- |
| `flutter analyze` | Không có vấn đề |
| `flutter test` | 53 bài đạt, gồm 3 bài nạp cấu hình client |
| Kiểm thử ghi đè bằng build flags | Đạt với URL khác, Google ID rỗng, Facebook false và Firebase project khác |
| Runner PostgreSQL, `--only tests/test_configuration.py` | 24 bài đạt; runner xác nhận dữ liệu phát triển không đổi |
| `check_configuration.py --client-only` với file local | Cấu trúc hợp lệ; không xác minh credentials hoặc kết nối nhà cung cấp |
| `flutter build apk --debug` không truyền cấu hình | Thành công |
| `flutter run` chọn điện thoại USB, không truyền cấu hình | Cài và chạy thành công; log chọn localhost, có HTTP 200 và ánh xạ cổng 8000 |
| `flutter run` chọn emulator, không truyền cấu hình | Cài và chạy thành công; log chọn `10.0.2.2`, có HTTP 200 |
| Xóa ánh xạ USB cổng API rồi chạy lại Flutter | Build tự tạo lại ánh xạ cổng 8000 thành công |
| Cấu hình client được nhúng vào Android | Khớp file public local; không in giá trị |
| Log khởi động trên hai thiết bị | Tiến trình còn chạy; không thấy lỗi khởi động/kênh cấu hình trong mẫu kiểm tra |

Kiểm tra chạy thiết bị dùng `-d` để chọn đích và `--no-resident` để kết thúc phiên kiểm tra; không truyền `--dart-define` hoặc `--dart-define-from-file`. Chưa thực hiện OAuth, nhận push, gửi email, thanh toán hoặc hoàn tiền thật với nhà cung cấp trong lượt này. Các kết quả lịch sử bên dưới thuộc lượt kiểm tra 10/11/2026.

## Kiểm tra ngày 10/11/2026

## Phạm vi và lựa chọn

Chủ dự án xác nhận chưa có tài khoản Google Cloud/Meta/Firebase/SMTP/merchant, chọn thanh toán sandbox và giữ trống thông tin liên hệ/video. Vì vậy chưa thể nghiệm thu các dịch vụ ngoài. Không tạo credentials giả hoặc bật capability để giả định dịch vụ đã hoạt động.

## Những thay đổi đã thực hiện

- Thêm `backend/check_configuration.py` để đọc cấu hình cục bộ, chỉ báo tên trường thiếu và mã vấn đề. Kiểm tra sự khớp nhau giữa backend/client, cấu trúc tài khoản Firebase, SMTP auth, URL callback public HTTPS và endpoint thanh toán đúng môi trường. Không gọi nhà cung cấp, không sửa database.
- Thêm mẫu `config/flutter.example.json`; bỏ qua `config/*.local.json` trong Git. Từ chối tên trường lạ và kiểu dữ liệu sai để tránh nhúng nhầm secret backend vào app.
- Thêm `scripts/run_android.ps1` để dùng chung cấu hình public cho Dart và native Android, chọn thiết bị tự động khi chỉ có một thiết bị, hỗ trợ LAN/USB/build APK/dry run và phục hồi biến môi trường khi xong.
- Bỏ IP LAN/mã điện thoại cố định khỏi cấu hình VS Code và script USB. API mặc định của mã nguồn dành cho Android emulator; điện thoại thật phải truyền URL cụ thể hoặc dùng script USB.
- Sửa ba cảnh báo null-aware elements, giữ nguyên hành vi bộ lọc đơn.
- Cập nhật tài liệu dịch vụ: các adapter thanh toán đã tồn tại; phần còn thiếu là tài khoản merchant và cấu hình. Hướng dẫn dùng công cụ mới tại `docs/service_configuration.md`.
- Bổ sung migration `0009`, API và UI quản lý hoàn toàn phần sandbox cho MoMo/VNPAY, lưu yêu cầu trước khi gọi mạng, đối soát, chống lặp/cạnh tranh và ghi sổ riêng sandbox. Không hỗ trợ hoàn production hoặc từng phần trong luồng mới.

## Kết quả kiểm thử

| Kiểm tra | Kết quả |
| --- | --- |
| Backend đầy đủ qua `manage_local.py test-postgres` | 127 passed, không skip, 1 cảnh báo deprecation từ thư viện TestClient/httpx |
| Kiểm thử mới | 15 ca cấu hình và 10 ca hoàn sandbox; đã nằm trong 127 ca trên, không cộng lần nữa |
| Dữ liệu phát triển | Runner đối chiếu trước/sau và xác nhận không đổi |
| `flutter analyze` | No issues found |
| `flutter test` sau thay đổi | 50 passed, gồm ba ca UI hoàn sandbox |
| Build APK debug trực tiếp | Thành công |
| Build APK debug qua script mới | Thành công với cấu hình public trống; bản cuối dùng localhost qua USB theo lựa chọn của chủ dự án |
| PowerShell và VS Code | Parse script/JSON thành công; dry run thành công |
| Kiểm tra yêu cầu đủ sáu dịch vụ bằng `--require` | Exit code 1 đúng dự kiến do chưa có credentials |
| Backend đang chạy | `/health/db`, `/app/capabilities`, `/hotel/info`, `/room-types` trả HTTP 200 |
| API tìm phòng | `/rooms/recommended` và `/rooms/available` trả HTTP 200 với ngày nhận/trả và số khách hợp lệ |
| Android thật | Cài cập nhật bằng `adb install -r` thành công, mở activity thành công, tiến trình còn chạy |
| Log tiến trình Android tại lúc kiểm tra | Không thấy `FATAL EXCEPTION` hoặc `Unhandled Exception` trong phần log lấy mẫu; chưa có bằng chứng HTTP 200 từ log mẫu này |
| Migration database phát triển | Đã sao lưu bằng pg_dump rồi áp dụng `0009`; script đối chiếu 28 bảng gốc và xác nhận các dòng/cột cũ không đổi |
| Backend sau migration | Đã xác minh tiến trình thuộc project, restart và xác nhận OpenAPI có endpoint hoàn sandbox mới |
| Mạng và cách chạy cuối | Giữ Wi-Fi Public theo lựa chọn chủ dự án; backend chỉ nghe `127.0.0.1:8000`, đã tạo ADB reverse cổng 8000; không thay profile mạng hoặc firewall |

Lượt đầu thiếu database `hotel_booking_test`: 17 passed, 85 lỗi setup. Đã tạo riêng database test, không seed/reset database phát triển, rồi chạy lại thành công như bảng trên. Một lần gọi API phòng đề xuất thiếu tham số bị trả 422 đúng validation; gọi lại với đủ tham số trả 200.

Build Android vẫn có cảnh báo Java native access và việc một số dependency dùng Kotlin Gradle Plugin trước thay đổi tương thích tương lai của Flutter. Build hiện tại thành công; không coi cảnh báo này là lỗi đã được khắc phục.

## Phần còn thiếu để hoàn tất yêu cầu

| Tính năng | Trạng thái thực tế và việc cần làm |
| --- | --- |
| Google | Tạo OAuth Android/Web client, đăng ký package/fingerprint; điền backend và client, sau đó kiểm thử đăng nhập/liên kết thật |
| Facebook | Tạo app Meta, cấu hình Android/key hash/test users, điền App ID/secret backend và public client settings; kiểm thử thật |
| Email khôi phục | Cấp SMTP hợp lệ, điền cấu hình và thử gửi/nhận thư, mã sai/hết hạn/dùng lại và lỗi dịch vụ |
| Firebase push | Tạo project/app và service account backend, điền cấu hình public, build lại; thử foreground/background/đóng app và quyền Android |
| MoMo/VNPAY | Cấp merchant sandbox và public HTTPS/IPN, kiểm thử giao dịch/đối soát trên hệ thống nhà cung cấp |
| Hoàn tiền sandbox | Đã có mã/API/UI/kiểm thử fixture; cần merchant có quyền hoàn để nghiệm thu giao dịch và đối soát thật. Hoàn production/từng phần chưa thuộc phạm vi sandbox đã chọn |
| Thông tin khách sạn | Để trống theo lựa chọn của chủ dự án, có thể nhập sau trong màn quản lý |
| Release production | Chưa yêu cầu triển khai production; APK hiện là debug nội bộ, chưa có khóa ký release riêng |

Các ca tự động đã kiểm tra nghiệp vụ và các transport fixture sẵn có; không thay cho OAuth, gửi SMTP, nhận FCM hoặc thanh toán/hoàn tiền trên nhà cung cấp. Chưa thao tác thủ công mọi màn hình hay mọi tổ hợp quyền trên điện thoại. Không thể cam kết phần mềm không bao giờ phát sinh lỗi dựa trên các phép thử này.

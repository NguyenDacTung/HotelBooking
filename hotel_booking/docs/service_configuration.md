# Cấu hình dịch vụ ngoài cho TTTP

Hiện chưa có tài khoản dịch vụ OAuth/SMTP/Firebase. Các nút đã được chuẩn bị và không báo thành công giả. Đăng nhập mật khẩu, đặt phòng và nghiệp vụ lễ tân vẫn dùng API/PostgreSQL thật.

## Email khôi phục mật khẩu

Điền trực tiếp trong `backend/.env`, không gửi mật khẩu vào chat, không đưa `.env` vào gói code chia sẻ:

```dotenv
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-mail-user
SMTP_PASSWORD='your-local-app-password'
SMTP_FROM=TTTP <your-mail@example.com>
SMTP_STARTTLS=true
```

Dùng thông tin SMTP do nhà cung cấp cấp. Với cổng 465, backend dùng TLS trực tiếp; cổng 587 dùng STARTTLS. Khởi động lại backend sau khi lưu. Mở Đăng nhập → Quên mật khẩu, gửi mã rồi nhập mã 6 số và mật khẩu mới. Mã có hạn 10 phút, chỉ dùng một lần, tối đa 5 lần nhập sai; yêu cầu được giới hạn theo email/IP. Đổi mật khẩu thu hồi phiên đăng nhập cũ. Backend chỉ lưu bản băm mã và không log mã/mật khẩu.

Khi chưa cấu hình, endpoint trả 503 `RECOVERY_NOT_CONFIGURED`, giao diện báo rõ. Đã kiểm thử nghiệp vụ bằng PostgreSQL và SMTP giả lập; **chưa kiểm thử gửi mail thật**. Sau khi cấu hình phải thử cả thư rác, sai mã, mã hết hạn, gửi lại, email không tồn tại và lỗi nhà cung cấp.

## Google

Tạo dự án Google Cloud, OAuth consent screen và OAuth Android client cho package `com.example.hotel_booking`, đăng ký SHA-1/SHA-256 của khóa ký bản cài. Tạo thêm OAuth Web client làm server client. Dùng cùng Web client ID ở:

- `GOOGLE_CLIENT_ID` trong `backend/.env`.
- `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` khi build Flutter.

Backend xác minh chữ ký, audience và Google subject; không tin email do client tự khai. Không đặt Google client secret trong Flutter. Bản debug và release cần fingerprint đúng khóa ký. Tham khảo [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in), [xác minh ID token](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).

## Facebook

Tạo app Meta và Android platform đúng package, activity `com.example.hotel_booking.MainActivity`, key hashes của khóa ký. Cấu hình Facebook Login/test users trước khi đưa app ra live. Backend điền `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET`, phiên bản Graph API được app Meta hỗ trợ (`FACEBOOK_GRAPH_VERSION`). App secret chỉ nằm trên backend.

Trước khi build, đặt biến môi trường PowerShell `TTTP_FACEBOOK_APP_ID` và `TTTP_FACEBOOK_CLIENT_TOKEN` theo Meta dashboard; build thêm `--dart-define=FACEBOOK_ENABLED=true`. Đây là client configuration; không dùng App Secret làm Client Token. Backend kiểm tra access token thuộc đúng app và còn hạn. Tài khoản Facebook dùng subject riêng, không tự ghép với tài khoản email chưa được xác minh. Xem [flutter_facebook_auth](https://facebook.meedu.app/docs/7.x.x/intro).

## Firebase Cloud Messaging

Tạo Firebase project, thêm Android app đúng package `com.example.hotel_booking`, bật Cloud Messaging HTTP v1. Tải service-account JSON của backend, lưu **ngoài thư mục chia sẻ code**, giới hạn quyền đọc; đặt đường dẫn tuyệt đối vào `FIREBASE_CREDENTIALS`, và `FIREBASE_PROJECT_ID` trong `.env`. Không đưa JSON này vào Android/assets hoặc Git.

Client dùng `firebase_core` 4.x và `firebase_messaging` 16.x đã khóa phiên bản trong `pubspec.lock`. Từ Firebase app settings, cung cấp bốn giá trị public khi build:

```powershell
flutter build apk --debug --target-platform android-arm `
  --dart-define=DEMO_MODE=false `
  --dart-define=API_BASE_URL=http://DIA_CHI_MAY_CHU:8000 `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_APP_ID=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_PROJECT_ID=...
```

Để Android khởi tạo Firebase khi app không chạy, cấu hình đồng thời các biến public `TTTP_FIREBASE_API_KEY`, `TTTP_FIREBASE_APP_ID`, `TTTP_FIREBASE_MESSAGING_SENDER_ID`, `TTTP_FIREBASE_PROJECT_ID` trước khi build. Gradle tạo resource Android tương ứng từ các biến này. Các giá trị phải cùng Firebase project với Dart và backend. Không cần tạo file cấu hình giả khi chưa có project.

Sau khi cài: đăng nhập → Cài đặt thông báo → bật Thông báo đẩy, cho phép quyền Android. `/devices` gắn đăng ký thiết bị với tài khoản và phiên hiện tại; đăng xuất hủy đăng ký. Backend gửi thông báo chung không chứa thông tin thanh toán/liên hệ, qua outbox mỗi 60 giây; chạm thông báo mở đúng phiếu sau xác thực. Lỗi dịch vụ được thử lại nên có thể nhận trùng; thông báo trong app và trạng thái phiếu từ API là nguồn đối chiếu.

**Chưa có Firebase nên chưa kiểm thử nhận thông báo thật**, đặc biệt các trạng thái foreground/background/đóng app, đổi tài khoản, đổi token, mất mạng và Android chặn quyền. Force-stop trong cài đặt Android có thể ngăn nhận đến khi mở app lại. Hướng dẫn gốc: [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api).

## Thanh toán online

Nút có trong hóa đơn khi khách đang ở hoặc yêu cầu trả phòng, hiện hiển thị **Chưa cấu hình** và bị vô hiệu hóa. Không tạo giao dịch hay đánh dấu đã thanh toán khi bấm. Chưa tích hợp gateway, chữ ký callback/webhook, môi trường sandbox hoặc đối soát ngân hàng. Sổ thu/hoàn tiền hiện tại do nhân viên ghi nhận sau giao dịch thực tế; đây là chức năng riêng.

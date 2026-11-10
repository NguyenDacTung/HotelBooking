# Cấu hình dịch vụ ngoài cho TETRA

## Bắt đầu ở đây: làm từng tính năng một

App đã có phần xử lý. Để một dịch vụ hoạt động, bạn cần **tạo tài khoản dịch vụ → lấy thông tin cấu hình → điền vào project → chạy lại → thử trên app**.

Nên làm theo thứ tự này:

| Thứ tự | Bạn muốn làm gì? | Cần chuẩn bị gì? | Điền vào đâu? |
| --- | --- | --- | --- |
| 1 | Gửi mã quên mật khẩu | Gmail có mật khẩu ứng dụng hoặc tài khoản SMTP khác | `backend/.env` |
| 2 | Đăng nhập Google | Dự án Google Cloud và mã OAuth | Cả hai file bên dưới |
| 3 | Đăng nhập Facebook | Ứng dụng Meta và thông tin Facebook Login | Cả hai file bên dưới |
| 4 | Gửi thông báo đẩy | Dự án Firebase và tài khoản gửi của backend | Cả hai file bên dưới |
| 5 | Thanh toán/hoàn tiền thử qua MoMo | Tài khoản merchant sandbox và địa chỉ backend HTTPS công khai | `backend/.env` |
| 6 | Thanh toán/hoàn tiền thử qua VNPAY | Tài khoản merchant sandbox và địa chỉ backend HTTPS công khai | `backend/.env` |

Bạn chỉ cần nhớ hai file:

- **`backend/.env`**: thông tin của máy chủ, gồm cả mật khẩu/khóa bí mật. Giữ tại máy, không chia sẻ.
- **`config/flutter.local.json`**: mã nhận diện public để build app Android. Tạo từ file mẫu ở phần bên dưới. Không điền mật khẩu hoặc secret vào đây.

### Làm thử tính năng đầu tiên: gửi mã quên mật khẩu bằng Gmail

1. Mở [tài khoản Google](https://myaccount.google.com/security), bật **Xác minh 2 bước**.
2. Mở [Mật khẩu ứng dụng](https://myaccount.google.com/apppasswords), tạo một mật khẩu cho backend TETRA. Chỉ nhập mật khẩu đó vào file tại máy. Nếu tài khoản không có mục này, xem [giải thích của Google](https://support.google.com/accounts/answer/185833?hl=vi) hoặc dùng nhà cung cấp SMTP khác.
3. Mở `backend/.env`. Tìm và sửa sáu dòng sau, thay các chữ giữ chỗ bằng thông tin của bạn:

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER='DIA_CHI_GMAIL_CUA_BAN'
SMTP_PASSWORD='MAT_KHAU_UNG_DUNG_VUA_TAO'
SMTP_FROM='DIA_CHI_GMAIL_CUA_BAN'
SMTP_STARTTLS=true
```

`SMTP_USER` và `SMTP_FROM` dùng cùng địa chỉ Gmail gửi thư. `SMTP_PASSWORD` là mật khẩu ứng dụng vừa tạo. Các giá trị máy chủ/cổng ở trên theo [hướng dẫn SMTP của Google](https://support.google.com/mail/answer/7104828).

4. Lưu file. Tại thư mục gốc có `pubspec.yaml`, restart backend:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Restart
```

5. Trên app, đăng ký tài khoản bằng email thật bạn nhận được thư. Sau đó đăng xuất → **Quên mật khẩu** → nhập email đó → kiểm tra hộp thư và thư rác → nhập mã để đặt mật khẩu mới. Email demo dạng `khach1@example.com` không dùng để thử nhận thư thật.

Với bước email này, chỉ cần restart backend; APK hiện tại vẫn dùng được qua USB. Khi thay file cấu hình Android cho Google/Facebook/Firebase, chạy lại app bằng:

```powershell
flutter run
```

### Cách biết đã điền đủ chưa

Từ thư mục gốc, chạy:

```powershell
.\backend\.venv\Scripts\python.exe .\backend\check_configuration.py --require recovery
```

Trong phần `recovery`, `ready: true` nghĩa là đã đủ cấu hình cục bộ. **Nhận được email trên app** mới xác nhận gửi thư thành công. Có thể để các dịch vụ khác chưa cấu hình trong lúc làm email.

Phần bên dưới là hướng dẫn tra cứu khi bạn tiếp tục Google, Facebook, Firebase và thanh toán. Thanh toán cần backend HTTPS công khai để nhà cung cấp gọi về; kết nối USB hiện tại chỉ phục vụ điện thoại kết nối máy tính.

---

Hiện chưa có tài khoản dịch vụ OAuth/SMTP/Firebase. Các nút đã được chuẩn bị và không báo thành công giả. Đăng nhập mật khẩu, đặt phòng và nghiệp vụ lễ tân vẫn dùng API/PostgreSQL thật.

## Chuẩn bị cấu hình cục bộ và kiểm tra

Không thể bật dịch vụ thật bằng giá trị mẫu. Chủ dự án cần tạo tài khoản Google Cloud, Meta, Firebase, nhà cung cấp SMTP và merchant sandbox MoMo/VNPAY. Chỉ nhập secret tại máy; không gửi chúng qua chat hoặc đưa vào APK.

Từ thư mục gốc, tạo file chứa **chỉ cấu hình public của client** nếu chưa có:

```powershell
if (-not (Test-Path config/flutter.local.json)) {
    Copy-Item config/flutter.example.json config/flutter.local.json
}
notepad config/flutter.local.json
```

File `config/*.local.json` được Git bỏ qua. Không thêm DB password, JWT secret, SMTP password, Meta App Secret, merchant secret hoặc Firebase service-account JSON vào file này. Công cụ kiểm tra từ chối tên trường không nằm trong mẫu để tránh nhúng nhầm khóa backend vào app.

Kiểm tra từ thư mục gốc, không gọi dịch vụ ngoài và không sửa database:

```powershell
.\backend\.venv\Scripts\python.exe .\backend\check_configuration.py
# Yêu cầu một hoặc nhiều dịch vụ phải sẵn sàng; exit code 1 nếu chưa đủ:
.\backend\.venv\Scripts\python.exe .\backend\check_configuration.py --require google facebook recovery push momo vnpay
```

Báo cáo chỉ hiển thị tên trường thiếu và mã vấn đề, không hiển thị giá trị. Công cụ đối chiếu cấu hình Google/Facebook/Firebase giữa client và backend, đọc kiểm tra cấu trúc service-account Firebase, phát hiện SMTP auth thiếu một nửa, URL callback nội bộ và endpoint thanh toán sai môi trường. `ready=true` là kiểm tra cục bộ, không chứng minh secret hợp lệ, DNS hoạt động hoặc nhà cung cấp đã duyệt.

Sau khi điền cấu hình, restart backend. Chạy Android bằng lệnh thống nhất:

```powershell
flutter run
```

Gradle tự đọc `config/flutter.local.json` (nếu chưa có thì dùng mẫu trống), kiểm tra tên trường/kiểu dữ liệu và nhúng **chỉ cấu hình public** cho cả Dart và Android resources. Giữ `API_BASE_URL` trống hoặc bỏ trường này: emulator tự dùng `http://10.0.2.2:8000`; điện thoại thật tự dùng `http://127.0.0.1:8000`. Build debug tự tạo ADB reverse cổng API cho điện thoại USB đã cấp quyền; giữ cáp khi dùng app. Nếu nhiều thiết bị, chọn thiết bị Android khi Flutter hỏi. Backend vẫn phải chạy riêng. Đổi cấu hình cần dừng và chạy lại lệnh, hot reload/restart không cập nhật native.

Muốn dùng LAN/hosting thì điền `API_BASE_URL` vào cùng file local. Giá trị phải là URL HTTP(S), không kèm thông tin đăng nhập, query hoặc fragment. `--dart-define` vẫn được ưu tiên khi ghi đè; các trường dịch vụ tương ứng cũng được áp dụng cho native SDK. Biến môi trường `TTTP_*` cũ vẫn hỗ trợ build qua script/CI, ưu tiên sau `--dart-define` và trước file local. Không đặt các biến này nếu muốn chỉ dùng file local.

Script cũ vẫn dùng được như phương án tùy chọn để kiểm tra kết nối trước khi chạy/build:

```powershell
# Thay LAN_IP bằng IPv4 hiện tại từ ipconfig. Backend phải chạy trước.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_android.ps1 -ApiBaseUrl http://LAN_IP:8000
# Build APK nội bộ; không cần điện thoại hoặc backend đang chạy:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_android.ps1 -ApiBaseUrl http://LAN_IP:8000 -BuildApk
# Hoặc qua USB, tự nhận một điện thoại đã được authorize:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_android.ps1 -Usb
```

Nếu dùng script và có nhiều thiết bị, truyền `-DeviceId` từ `adb devices`. Dùng `-DryRun` để kiểm tra file cấu hình và tham số mà không build/cài app hoặc thao tác thiết bị. Script mặc định dùng cấu hình trống từ file mẫu khi chưa có file local; không tự bật dịch vụ thiếu thông tin. F5 có cấu hình USB/Emulator dùng cùng cơ chế như `flutter run`.

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

Điền Web client ID vào `GOOGLE_SERVER_CLIENT_ID` của `config/flutter.local.json`; `flutter run` tự nạp giá trị đó cho Dart.

Backend xác minh chữ ký, audience và Google subject; không tin email do client tự khai. Không đặt Google client secret trong Flutter. Bản debug và release cần fingerprint đúng khóa ký. Tham khảo [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in), [xác minh ID token](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).

## Facebook

Tạo app Meta và Android platform đúng package, activity `com.example.hotel_booking.MainActivity`, key hashes của khóa ký. Cấu hình Facebook Login/test users trước khi đưa app ra live. Backend điền `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET`, phiên bản Graph API được app Meta hỗ trợ (`FACEBOOK_GRAPH_VERSION`). App secret chỉ nằm trên backend.

Trước khi build, đặt biến môi trường PowerShell `TTTP_FACEBOOK_APP_ID` và `TTTP_FACEBOOK_CLIENT_TOKEN` theo Meta dashboard; build thêm `--dart-define=FACEBOOK_ENABLED=true`. Đây là client configuration; không dùng App Secret làm Client Token. Backend kiểm tra access token thuộc đúng app và còn hạn. Tài khoản Facebook dùng subject riêng, không tự ghép với tài khoản email chưa được xác minh. Xem [flutter_facebook_auth](https://facebook.meedu.app/docs/7.x.x/intro).

Điền `TTTP_FACEBOOK_APP_ID`, `TTTP_FACEBOOK_CLIENT_TOKEN` và boolean `FACEBOOK_ENABLED: true` trong file public local, rồi chạy `flutter run`; không cần đặt biến môi trường bằng tay.

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

Với `flutter run`, chỉ cần điền đủ bốn trường `FIREBASE_*` public vào file local. Gradle tạo resource Android từ cùng cấu hình để Firebase khởi tạo được khi app không chạy; không cần đặt thêm biến môi trường `TTTP_FIREBASE_*`. Các biến cũ vẫn hỗ trợ script/CI. Các giá trị phải cùng Firebase project với Dart và backend. Không cần tạo file cấu hình giả khi chưa có project.

Script mới nhận bốn trường `FIREBASE_*` từ file public local, đồng thời chuyển chúng sang các biến Android `TTTP_FIREBASE_*`. Không điền một phần bộ bốn trường; công cụ sẽ dừng trước khi build nếu thiếu.

Sau khi cài: đăng nhập → Cài đặt thông báo → bật Thông báo đẩy, cho phép quyền Android. `/devices` gắn đăng ký thiết bị với tài khoản và phiên hiện tại; đăng xuất hủy đăng ký. Backend gửi thông báo chung không chứa thông tin thanh toán/liên hệ, qua outbox mỗi 60 giây; chạm thông báo mở đúng phiếu sau xác thực. Lỗi dịch vụ được thử lại nên có thể nhận trùng; thông báo trong app và trạng thái phiếu từ API là nguồn đối chiếu.

**Chưa có Firebase nên chưa kiểm thử nhận thông báo thật**, đặc biệt các trạng thái foreground/background/đóng app, đổi tài khoản, đổi token, mất mạng và Android chặn quyền. Force-stop trong cài đặt Android có thể ngăn nhận đến khi mở app lại. Hướng dẫn gốc: [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api).

## Thanh toán online

Đã có adapter MoMo/VNPAY, xác thực callback/IPN, truy vấn kết quả và cô lập sổ tiền sandbox/production. Khi chưa có merchant và public HTTPS, nút vẫn hiển thị **Chưa cấu hình** và không tạo giao dịch. Xem [external_configuration.md](external_configuration.md) để điền biến backend và khai báo callback.

Giữ `PAYMENT_ENVIRONMENT=sandbox` trong giai đoạn hiện tại. Dùng credentials sandbox do nhà cung cấp cấp, public HTTPS trỏ đúng backend và đăng ký IPN/return với merchant. `localhost` và IP LAN của máy không nhận được callback từ Internet. Kiểm tra thành công, thất bại, hủy, timeout, callback lặp, chữ ký sai và đối soát trước khi coi tích hợp hoạt động; fixture tự động không thay cho các phép thử trên nhà cung cấp.

Đã bổ sung hoàn **toàn phần sandbox** cho MoMo/VNPAY. Quản lý mở đơn → Sổ thu/hoàn tiền → Hoàn tiền online sandbox. Chỉ giao dịch sandbox đã được xác minh thành công và có khoản thu gốc mới được hoàn; server lấy số tiền từ giao dịch gốc. Với MoMo, luồng hiện hỗ trợ khoản hoàn 1.000–50.000.000 VND; giới hạn theo phương thức của merchant vẫn phải được nhà cung cấp chấp nhận.

Yêu cầu được lưu trước khi gọi mạng. Timeout/không xác minh được phản hồi giữ trạng thái `CREATED` hoặc `PENDING` và chặn tạo yêu cầu hoàn khác cho cùng khoản thu. Dùng nút Đối soát; không dùng thu/hoàn thủ công để giả lập kết quả. Yêu cầu trùng trả lại bản ghi cũ, không gọi hoàn lần nữa. Chỉ phản hồi HTTPS khớp giao dịch từ MoMo hoặc phản hồi VNPAY đúng chữ ký/số tiền/loại hoàn mới được xét kết quả; trạng thái tiếp nhận/đang xử lý không được coi là đã hoàn.

Khoản hoàn được ghi với `environment=sandbox`, không giảm/tăng công nợ hoặc báo cáo tiền thật. Hoàn production và hoàn từng phần qua cổng chưa được hỗ trợ trong luồng này. Cần merchant sandbox có quyền hoàn và kiểm thử nhà cung cấp thực tế trước khi nghiệm thu.

Schema mới ở migration `0009`; với dữ liệu hiện có, chạy script sao lưu và migration từ gốc trước khi restart backend:

```powershell
.\backend\.venv\Scripts\python.exe .\scripts\migrate_preserving_data.py
```

Giao thức tham khảo: [MoMo refund/query](https://developers.momo.vn/v3/docs/payment/api/payment-api/refund/), [VNPAY query/refund](https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr%26refund.html).

## Thông tin khách sạn và phát hành

Theo lựa chọn hiện tại, giữ trống điện thoại/email/website/video; không tự điền dữ liệu giả. Có thể cập nhật sau ở Quản lý → Cài đặt → Thông tin công khai khách sạn. Video cần URL HTTPS file media trực tiếp.

Các lệnh mới tạo APK debug nội bộ. Chưa cấu hình khóa ký release hoặc hosting HTTPS production; không dùng bản debug làm bản phát hành chính thức. Máy tính/backend/PostgreSQL cần tiếp tục chạy khi dùng API LAN.

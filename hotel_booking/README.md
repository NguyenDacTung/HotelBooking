# TETRA Hotel

Ứng dụng Android đặt phòng và quản lý hoạt động của một khách sạn, với giao diện tiếng Việt. Project gồm ứng dụng Flutter tại thư mục gốc và backend FastAPI chạy riêng, sử dụng PostgreSQL.

README được cập nhật theo mã nguồn trong workspace ngày **11/11/2026**. Các tính năng tích hợp bên ngoài cần tài khoản dịch vụ và cấu hình riêng; có mã tích hợp không đồng nghĩa dịch vụ đã được kiểm chứng thực tế.

## Chức năng chính

| Vai trò | Chức năng |
| --- | --- |
| Khách hàng | Đăng ký, đăng nhập; tìm phòng theo ngày và số khách; xem phòng, ảnh, tiện nghi; đặt và theo dõi đơn, hủy theo điều kiện; xem mã QR đặt phòng; yêu cầu trả phòng; thanh toán online khi được cấu hình; gửi đánh giá sau lưu trú. |
| Lễ tân (`LE_TAN`) | Xử lý yêu cầu đặt phòng; đặt hộ khách tại quầy; xem lịch và tình trạng phòng; quét QR tra cứu đơn; nhận/trả phòng, ghi nhận phụ thu, thu/hoàn tiền và đối chiếu công nợ theo quyền. |
| Quản lý (`QUAN_LY`) | Thực hiện nghiệp vụ nhân viên; quản lý phòng, loại phòng, tiện nghi, ảnh, lịch tạm ngừng và tài khoản; nhập phòng từ CSV; quản lý đánh giá, phản hồi và thông tin khách sạn; xem tổng quan, báo cáo doanh thu, xuất PDF; xử lý hoàn tiền online toàn phần trong sandbox. |

Các chức năng dùng chung gồm hồ sơ và ảnh đại diện, đổi mật khẩu, liên kết tài khoản Google/Facebook, đăng nhập sinh trắc học trên thiết bị hỗ trợ, thông báo và cài đặt nhắc lịch. Trang thông tin khách sạn có bản đồ và video khi được cấu hình. Người dùng đăng nhập có thể gửi góp ý/báo lỗi kèm ảnh.

Backend kiểm tra quyền, trạng thái đơn, lịch phòng và công nợ trước khi thực hiện nghiệp vụ. Đăng nhập sinh trắc học cần được bật sau khi đã đăng nhập tài khoản trên thiết bị.

## Công nghệ và cấu trúc

| Thành phần | Công nghệ |
| --- | --- |
| Ứng dụng | Flutter, Dart, Material 3, Provider |
| Giao tiếp và phiên | HTTP API, JWT, `flutter_secure_storage` |
| Backend | Python, FastAPI, Pydantic, SQLAlchemy 2, psycopg |
| Dữ liệu | PostgreSQL, migration bằng Alembic |
| Tích hợp | Google/Facebook OAuth, Firebase Cloud Messaging, SMTP, MoMo/VNPAY |
| Tiện ích | QR và camera, OpenStreetMap, xử lý ảnh, CSV, báo cáo PDF |

```text
hotel_booking/
├── android/                 # Android native, quyền, cấu hình build và SDK
├── assets/images/           # Ảnh và tài nguyên giao diện
├── backend/
│   ├── app/                 # API, model, schema, dịch vụ và CLI
│   ├── alembic/             # Migration PostgreSQL
│   ├── tests/               # Kiểm thử backend
│   ├── .env.example         # Mẫu cấu hình backend
│   ├── check_configuration.py
│   ├── manage_local.py      # Chuẩn bị seed/DB test và chạy test có bảo vệ
│   └── requirements.txt
├── config/
│   └── flutter.example.json # Mẫu cấu hình public cho Flutter/Android
├── data/                    # Dữ liệu và tài nguyên bổ sung
├── lib/
│   ├── app/                 # Khởi tạo, điều hướng, giao diện chung
│   ├── core/                # Cấu hình và chuỗi dùng chung
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   ├── screens/             # auth, customer, staff, admin, shared
│   ├── services/
│   └── widgets/
├── scripts/                 # Hỗ trợ chạy, mạng LAN, migration và seed
├── pubspec.yaml
└── README.md
```

Tên hiển thị Android là **TETRA Hotel**; application ID hiện là `com.example.hotel_booking`. Một số khóa cấu hình và tên kỹ thuật vẫn dùng tiền tố `TTTP` để giữ tương thích.

## Yêu cầu môi trường

Hướng dẫn dưới đây dùng **Windows và PowerShell**, chạy từ thư mục chứa `pubspec.yaml` trừ khi có ghi chú khác.

- Flutter SDK đi kèm Dart đáp ứng `^3.13.4` theo [pubspec.yaml](pubspec.yaml).
- Android SDK, platform-tools/ADB, JDK 17; emulator Android hoặc điện thoại bật USB debugging và đã cấp quyền cho máy tính.
- Python: hướng dẫn tạo môi trường dùng **3.13**; cài dependency theo [backend/requirements.txt](backend/requirements.txt). README không xác nhận khả năng tương thích của mọi phiên bản Python khác.
- PostgreSQL đang chạy; tài khoản migration có quyền tạo bảng/trigger và sử dụng extension `btree_gist`. Backend chỉ hỗ trợ PostgreSQL qua `postgresql+psycopg://`.

Kiểm tra Flutter và thiết bị:

```powershell
flutter --version
flutter doctor
flutter devices
```

## Cài đặt lần đầu

### 1. Chuẩn bị Flutter và cấu hình public

```powershell
flutter pub get
Copy-Item .\config\flutter.example.json .\config\flutter.local.json
```

Chỉ sao chép khi chưa có file local. Nếu đã cấu hình, giữ lại nội dung hiện có.

Mẫu tại [config/flutter.example.json](config/flutter.example.json). Giữ `API_BASE_URL` là chuỗi rỗng để Android tự chọn USB/emulator. Có thể để trống các dịch vụ chưa dùng và giữ `FACEBOOK_ENABLED=false`.

### 2. Tạo môi trường backend

```powershell
cd backend
py -3.13 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
```

Nếu `.venv` hoặc `.env` đã tồn tại, sử dụng môi trường phù hợp đang có và giữ nguyên cấu hình. Sao chép chuỗi ngẫu nhiên vừa tạo vào `JWT_SECRET` trong `.env`. Backend từ chối secret bắt đầu bằng `replace-` hoặc ngắn hơn 32 ký tự.

### 3. Tạo và cấu hình PostgreSQL

Với môi trường mới, dùng SQL Shell/pgAdmin bằng tài khoản quản trị PostgreSQL. Thay mật khẩu mẫu trước khi chạy; bỏ qua bước tạo nếu user/database đã tồn tại:

```sql
CREATE USER hotel_app WITH PASSWORD 'CHOOSE_A_LOCAL_PASSWORD';
CREATE DATABASE hotel_booking OWNER hotel_app;
```

Kết nối vào database `hotel_booking` và tạo extension nếu cần:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

Sửa các biến sau trong `backend/.env` theo [backend/.env.example](backend/.env.example):

| Biến | Ý nghĩa |
| --- | --- |
| `DB_HOST`, `DB_PORT` | Địa chỉ PostgreSQL; mặc định `127.0.0.1:5432` |
| `DB_USER`, `DB_PASSWORD` | Tài khoản database; dùng `hotel_app` nếu tạo theo ví dụ trên |
| `DB_NAME` | `hotel_booking` cho quy trình local trong README |
| `JWT_SECRET` | Chuỗi ngẫu nhiên ít nhất 32 ký tự |
| `DEMO_PASSWORD` | Tùy chọn: mật khẩu 8–128 ký tự cho tài khoản seed mới |
| `UPLOAD_DIR`, `PRIVATE_UPLOAD_DIR` | Thư mục media public và riêng tư |

Ứng dụng dựng URL từ các trường `DB_*`, nên mật khẩu trong `DB_PASSWORD` không cần percent-encode. Nếu đặt `DATABASE_URL`, biến này được ưu tiên và phải dùng dạng `postgresql+psycopg://USER:ENCODED_PASSWORD@HOST:5432/hotel_booking`; percent-encode ký tự đặc biệt trong phần mật khẩu URL.

Giữ secret trong `.env`; không đưa mật khẩu DB, JWT, khóa cổng thanh toán hoặc service-account JSON vào cấu hình Flutter. Các file `backend/.env` và `config/*.local.json` được Git bỏ qua.

### 4. Migration và dữ liệu mẫu

Từ thư mục `backend`:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m app.cli seed
```

Seed dùng `DEMO_PASSWORD` từ environment/`.env`, hoặc hỏi mật khẩu qua prompt khi chưa có. Seed tạo các tài khoản dưới đây, cùng danh mục phòng, tiện nghi và dữ liệu đặt phòng mẫu:

| Vai trò | Email |
| --- | --- |
| Khách hàng | `khach1@example.com`, `khach2@example.com`, `khach3@example.com` |
| Lễ tân | `letan@example.com` |
| Quản lý | `quanly@example.com` |

Chạy lại seed không đổi mật khẩu tài khoản đã tồn tại hoặc dời ngày các đơn đã seed; nếu gặp xung đột lịch thì báo lỗi thay vì ghi đè. Seed không tự chạy khi khởi động backend.

Tạo thêm nhân viên qua CLI tin cậy, mật khẩu nhập bằng prompt:

```powershell
.\.venv\Scripts\python.exe -m app.cli create-staff --email staff@example.com --name 'Nhân viên mới' --role LE_TAN
```

Dùng `--role QUAN_LY` để tạo quản lý. CLI không tự đổi quyền/mật khẩu của email đã có.

Với database có dữ liệu, sao lưu trước khi nâng cấp và chạy `alembic upgrade head` từ `backend`. Không dùng `create_all` thay migration hoặc downgrade/reset để cập nhật schema; `alembic downgrade base` xóa dữ liệu nghiệp vụ.

## Chạy ứng dụng với API thật

Sau khi hoàn tất cài đặt, mở **hai terminal tại thư mục gốc**.

**Terminal 1 — khởi động backend:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1
```

Script dùng `backend/.venv`, bind `127.0.0.1:8000`, kiểm tra kết nối PostgreSQL và ghi log vào `backend/server.stdout.log`, `backend/server.stderr.log`. Script không tự tạo `.env`, migration hoặc seed.

Có thể chạy trực tiếp để xem log ngay trong terminal, thay cho script:

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Các địa chỉ kiểm tra trên máy tính:

| Địa chỉ | Mục đích |
| --- | --- |
| `http://127.0.0.1:8000/docs` | Swagger UI, xem các API hiện có |
| `http://127.0.0.1:8000/health` | Liveness của server; không xác nhận DB |
| `http://127.0.0.1:8000/health/db` | Chạy `SELECT 1`; HTTP 200 khi kết nối được, 503 khi lỗi DB |

**Terminal 2 — chạy Flutter:**

```powershell
flutter run
# Nếu có nhiều thiết bị, thay DEVICE_ID bằng ID từ flutter devices:
flutter run -d DEVICE_ID
```

Chọn một trong hai lệnh trên. Backend phải chạy riêng; `flutter run` không khởi động Python hoặc PostgreSQL.

### Chọn địa chỉ API

| Môi trường | Địa chỉ app sử dụng | Điều kiện |
| --- | --- | --- |
| Android Emulator | `http://10.0.2.2:8000` | Để `API_BASE_URL` trống để tự chọn |
| Điện thoại qua USB | `http://127.0.0.1:8000` | Để `API_BASE_URL` trống, bật và cấp quyền USB debugging; build debug tự thiết lập ADB reverse |
| Điện thoại qua Wi-Fi | `http://<IP_LAN_MAY_TINH>:8000` | Chỉ định URL, backend bind LAN, cùng mạng và firewall cho phép cổng 8000 |
| Backend triển khai riêng | URL HTTPS của backend | Chỉ định URL truy cập được từ thiết bị |

Gradle đọc `config/flutter.local.json`, hoặc dùng file example khi chưa có local, rồi cung cấp cấu hình cho Dart và SDK Android. Cờ `--dart-define` tương ứng được ưu tiên hơn giá trị trong file; không cần `--dart-define-from-file` khi dùng quy trình Android mặc định.

Sau khi thay cấu hình public/native, dừng app và chạy lại `flutter run` để build lại. Hot reload/hot restart không cập nhật phần cấu hình native.

Giữ kết nối USB khi sử dụng ADB reverse. Sau khi rút/cắm cáp, chạy lại phiên debug; nếu cần thiết lập thủ công:

```powershell
adb -s DEVICE_ID reverse tcp:8000 tcp:8000
```

### Tùy chọn: chạy qua Wi-Fi LAN

Kiểm tra tên card mạng và IPv4 hiện tại, rồi chạy backend với mạng Private đáng tin cậy:

```powershell
Get-NetConnectionProfile
Get-NetIPAddress -AddressFamily IPv4
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Lan -InterfaceAlias 'WiFi'
flutter run --dart-define=API_BASE_URL=http://<IP_LAN_MAY_TINH>:8000
```

Thay `WiFi` bằng tên interface thực tế và `<IP_LAN_MAY_TINH>` bằng IPv4 máy chạy backend. Nếu backend do script khởi động trước đó chỉ đang nghe localhost, thêm `-Restart` để script khởi động lại đúng tiến trình project ở chế độ LAN. Với server chạy thủ công, dừng rồi chạy lại bằng `--host 0.0.0.0`.

Nếu cần mở firewall, chạy script sau một lần bằng PowerShell có quyền Administrator, với đúng interface mạng Private:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\configure_private_firewall.ps1 -InterfaceAlias 'WiFi'
```

Rule chỉ mở TCP 8000 cho subnet cục bộ trên interface đã chọn. Không cần mở cổng PostgreSQL cho điện thoại. Khi IP máy tính đổi, cập nhật `API_BASE_URL` và build lại app.

## Cấu hình dịch vụ tùy chọn

Cấu hình public đặt trong `config/flutter.local.json`; cấu hình backend và secret đặt trong `backend/.env`.

| Dịch vụ | Cấu hình public Flutter/Android | Cấu hình backend và điều kiện |
| --- | --- | --- |
| Google | `GOOGLE_SERVER_CLIENT_ID` | `GOOGLE_CLIENT_ID` phải khớp server client ID; cấu hình OAuth Android đúng package và chứng thư ký |
| Facebook | `FACEBOOK_ENABLED=true`, `TTTP_FACEBOOK_APP_ID`, `TTTP_FACEBOOK_CLIENT_TOKEN` | `FACEBOOK_APP_ID` khớp phía client, `FACEBOOK_APP_SECRET`; cấu hình Android/key hash trên ứng dụng Meta |
| Email khôi phục | Không cần khóa client | `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM`, `SMTP_STARTTLS`; `SMTP_USER` và `SMTP_PASSWORD` khi server yêu cầu xác thực |
| Firebase push | Đủ bốn biến `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` | `FIREBASE_PROJECT_ID` khớp client; `FIREBASE_CREDENTIALS` trỏ tới service-account JSON được giữ ngoài gói mã nguồn chia sẻ |
| MoMo | Không chứa merchant secret | `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY`, `MOMO_ENDPOINT`; cấu hình môi trường và callback bên dưới |
| VNPAY | Không chứa merchant secret | `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, `VNPAY_PAYMENT_URL`, `VNPAY_QUERY_URL`; cấu hình môi trường và callback bên dưới |
| PDF | Không cần khóa client | `REPORT_FONT_PATH` trỏ tới font hỗ trợ tiếng Việt; mặc định `C:/Windows/Fonts/arial.ttf` |
| Media | Không cần khóa client | `PERSISTENT_MEDIA_ENABLED`, `UPLOAD_DIR`, `PRIVATE_UPLOAD_DIR`; backend cần quyền ghi và lưu trữ bền vững |

Thanh toán mặc định dùng `PAYMENT_ENVIRONMENT=sandbox`. Đặt `PAYMENT_PUBLIC_BASE_URL` thành URL HTTPS công khai của backend, truy cập được từ cổng thanh toán; localhost, IP LAN và ADB reverse không thay thế callback công khai. Endpoint cổng thanh toán phải khớp môi trường merchant.

**Hoàn tiền online hiện chỉ hỗ trợ toàn phần trong sandbox**, do quản lý thực hiện trên khoản thanh toán sandbox đã xác minh thành công. Thanh toán/hoàn sandbox không tất toán hoặc thay đổi công nợ thật. Luồng production cần cấu hình và kiểm chứng riêng trước khi sử dụng.

### Kiểm tra cấu hình

Từ thư mục `backend`:

```powershell
# Kiểm tra cấu trúc cấu hình public, không cần tải settings backend:
.\.venv\Scripts\python.exe check_configuration.py --client-only
# Báo cáo cấu hình các tính năng:
.\.venv\Scripts\python.exe check_configuration.py
# Ví dụ: yêu cầu cấu hình Google và push phải sẵn sàng:
.\.venv\Scripts\python.exe check_configuration.py --require google push
```

Script kiểm tra cục bộ và báo tên trường thiếu/mã lỗi, không thực hiện giao dịch hay gọi thử nhà cung cấp. Kết quả `ready` chưa xác nhận OAuth, gửi email/push hoặc giao dịch thực tế thành công. Chỉ dùng `--require` cho dịch vụ bạn chủ động bật.

## Chế độ xem mẫu

```powershell
flutter run --dart-define=DEMO_MODE=true
```

Mặc định `DEMO_MODE=false` và ứng dụng dùng API thật. Demo mở giao diện xem mẫu, không thay thế luồng đặt phòng và lưu dữ liệu thực tế; không cần chuẩn bị database để xem màn hình này.

## Kiểm tra và build

### Flutter

Từ thư mục gốc:

```powershell
flutter analyze
flutter build apk --debug
```

APK debug nằm tại `build/app/outputs/flutter-apk/app-debug.apk`. Thư mục kiểm thử Flutter `test/` hiện không có trong workspace, nên chưa có bộ test Flutter để chạy; không xem việc thiếu test là kiểm thử đã đạt.

Build release với URL backend HTTPS thực tế:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://<TEN_MIEN_BACKEND>
```

Thay `<TEN_MIEN_BACKEND>` trước khi chạy. Cấu hình release hiện vẫn dùng **debug signing key** trong `android/app/build.gradle.kts`; cần cấu hình ký riêng trước khi phát hành. HTTP cleartext được bật cho debug, release cần HTTPS. APK không chứa Python/PostgreSQL và vẫn cần backend chạy riêng.

### Backend với PostgreSQL test riêng

Tạo database test **riêng biệt** bằng tài khoản quản trị nếu chưa có:

```sql
CREATE DATABASE hotel_booking_test OWNER hotel_app;
```

Owner phải khớp tài khoản `DB_USER` thực tế. Tạo extension `btree_gist` trong database test nếu tài khoản migration chưa đủ quyền tạo extension. Database test là dữ liệu dùng một lần; fixture thực hiện migration rồi **TRUNCATE trước mỗi bài tích hợp**.

Từ thư mục `backend`, sau khi đã cấu hình và migrate database phát triển:

```powershell
.\.venv\Scripts\python.exe manage_local.py test-postgres
# Hoặc chỉ chạy một nhóm test qua cùng cơ chế bảo vệ:
.\.venv\Scripts\python.exe manage_local.py test-postgres --only tests/test_configuration.py
```

Runner yêu cầu database phát triển tên `hotel_booking`, dựng URL test `hotel_booking_test` từ cùng thông tin kết nối và so sánh dấu vân tay dữ liệu phát triển trước/sau test. Fixture kiểm tra tên database thực trước khi xóa dữ liệu test. Nếu chạy pytest trực tiếp mà không cấp `TEST_DATABASE_URL`, các bài cần PostgreSQL bị skip và không được xem là đã đạt.

Có thể dùng `manage_local.py prepare` sau migration để bổ sung seed và chuẩn bị DB test. Lệnh này tạo/lưu `DEMO_PASSWORD` cục bộ nếu thiếu; cần quyền `CREATEDB` nếu database test chưa tồn tại. Quy trình tạo DB test thủ công ở trên tránh phải cấp quyền này cho tài khoản app.

Các lệnh trong README là hướng dẫn kiểm tra; README không khẳng định kết quả chạy test/build trên môi trường hiện tại.

## Xử lý lỗi thường gặp

| Hiện tượng | Kiểm tra / cách xử lý |
| --- | --- |
| App không kết nối API | Mở `/health/db` trên máy tính; xem log backend; kiểm tra `API_BASE_URL` theo USB, emulator hoặc LAN. `localhost` trên Android là chính thiết bị Android. |
| `/health` chạy nhưng API nghiệp vụ lỗi | Kiểm tra PostgreSQL, thông tin `DB_*`/`DATABASE_URL`, `/health/db` và migration `alembic upgrade head`. |
| Điện thoại USB mất kết nối | Cấp quyền USB debugging, kiểm tra `adb devices`, kết nối lại cáp rồi chạy lại `flutter run` hoặc lệnh ADB reverse. |
| LAN không truy cập được | Kiểm tra IPv4, cùng mạng có thể truy cập nhau, interface Private, bind `0.0.0.0`, firewall TCP 8000 và khả năng cô lập thiết bị của Wi-Fi. |
| Đổi cấu hình nhưng app vẫn dùng giá trị cũ | Dừng phiên app rồi build/chạy lại; kiểm tra cờ `--dart-define` đang ghi đè file local. |
| Nút OAuth, email, push hoặc thanh toán chưa dùng được | Chạy `check_configuration.py`; bổ sung đúng nhóm cấu hình và kiểm tra thiết lập ở nhà cung cấp. |
| Lỗi tạo extension hoặc bảng khi migration | Nhờ quản trị viên tạo `btree_gist` trong đúng database và kiểm tra quyền migration; không reset database. |
| PDF lỗi font hoặc thiếu dấu tiếng Việt | Kiểm tra `REPORT_FONT_PATH` tồn tại và font hỗ trợ tiếng Việt. |
| Phiên hết hạn / HTTP 401 | Đăng nhập lại; ứng dụng xóa phiên không còn hợp lệ. |
| Timeout sau khi gửi đặt phòng hoặc thanh toán | Kiểm tra đơn/trạng thái giao dịch trước khi gửi lại; tránh tạo đơn hoặc thu tiền trùng khi kết quả chưa rõ. |

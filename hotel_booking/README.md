# TETRA Hotel — cập nhật tích hợp 18/10/2026

Trong app dùng tên **TETRA**, nhãn Android **TETRA Hotel**; applicationId vẫn `com.example.hotel_booking`. PostgreSQL là database duy nhất của backend; không reset dữ liệu. Các khóa kỹ thuật/email demo có chữ TTTP được giữ để tương thích bản cũ.

- [Màn hình và điểm vào](docs/screens.md) · [Quyết định điều chỉnh đặc tả](docs/integration_decisions.md) · [Thư viện/phiên bản](docs/integration_inventory.md) · [Ánh xạ học phần](docs/course_mapping.md)
- [Cấu hình dịch vụ ngoài](docs/external_configuration.md) · [Nghiệm thu và phần chưa kiểm thử](docs/integration_acceptance.md)
- [Kịch bản quay tiến độ](docs/KICH_BAN_QUAY_TIEN_DO_TETRA.md) · [Kịch bản Word](artifacts/TETRA_KICH_BAN_QUAY_TIEN_DO.docx) · [Dữ liệu bổ sung và sao lưu](docs/recording_data.md) · [Nghiệm thu hồ sơ/vân tay mới](docs/profile_biometric_acceptance.md)
- Tất cả lý do là tùy chọn; nhận/trả phòng không còn hộp yêu cầu lý do. Quyền, trạng thái đơn, phụ thu và đối chiếu công nợ vẫn được kiểm tra.

Chạy từ thư mục chứa `pubspec.yaml`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Lan
```

PostgreSQL Windows tự chạy theo cấu hình hiện tại; không cần mở pgAdmin. Điện thoại và máy tính phải cùng mạng có thể truy cập nhau, máy tính/backend đang bật. API bản LAN là `http://192.168.31.112:8000`, không cần USB/adb reverse; nếu đổi IP, sửa `API_BASE_URL` lúc build.

```powershell
# Máy đã có .env: giữ nguyên mật khẩu cục bộ, không đưa vào chat hoặc gói code.
# Sao lưu rồi migrate có kiểm tra các cột/dòng cũ, tuyệt đối không reset:
.\backend\.venv\Scripts\python.exe .\scripts\migrate_preserving_data.py
# Chỉ khi muốn bổ sung seed không ghi đè tài khoản/dữ liệu đã có:
Push-Location backend
.\.venv\Scripts\python.exe manage_local.py prepare
# Test tự trỏ hotel_booking_test và đối chiếu hotel_booking không đổi:
.\.venv\Scripts\python.exe manage_local.py test-postgres
Pop-Location
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://192.168.31.112:8000
```

Lệnh ARM32 dành cho SM A135F đang kiểm tra; khi phát hành cho máy khác dùng build/split ABI phù hợp và cấu hình ký release riêng. `--debug` chưa phải bản phát hành lên kho ứng dụng. MoMo/VNPAY, OAuth, email và push cần cấu hình của chủ dự án; không suy diễn nút/cấu hình hoặc fixture thành giao dịch/dịch vụ thật đã hoạt động.

## Ghi chép các phiên bản trước

Các hướng dẫn USB và tên TTTP dưới đây thuộc lịch sử/cấu hình thay thế. Ưu tiên bản Wi-Fi cùng tài liệu cập nhật ở trên.

> **Hiện tại dùng Wi-Fi:** APK trên SM A135F gọi `http://192.168.31.112:8000`, không cần adb reverse. Xem [khởi động mỗi ngày, kiểm chứng phiên và điều kiện mạng](docs/wifi_running.md). Chạy `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Lan` từ thư mục gốc; PostgreSQL tự khởi động, không cần pgAdmin. Cấu hình VS Code mới: **TTTP - WiFi LAN - API PostgreSQL**.

> **Bản nâng cấp TTTP 17/10/2026:** xem [hướng dẫn chạy và API mới](docs/upgrade_notes.md), [trạng thái nghiệm thu](docs/acceptance_checklist.md), [màn hình](docs/screens.md), [quyền](docs/permission_matrix.md), [OAuth](docs/social_login_setup.md), [ảnh/icon](docs/assets.md). Backend dùng cổng **8000**; ADB `reverse tcp:8000 tcp:8000`. Chọn cấu hình VS Code **TTTP - SM A135F - API PostgreSQL** để tự kiểm tra API và khôi phục ánh xạ USB trước khi chạy. Các mục baseline bên dưới mô tả phiên bản trước nâng cấp.

﻿# Hotel Booking • 

Ứng dụng Android một khách sạn: Flutter Material 3 + Provider, FastAPI, SQLAlchemy và **PostgreSQL**. Flutter hiện có được giữ tại gốc; `backend/` và `docs/` đặt cạnh `lib/`, không tạo app lồng nhau. Ngôn ngữ giao diện tiếng Việt.

Đặc tả: [docs/DAC_TA_CODEX_HOTEL_BOOKING.md](docs/DAC_TA_CODEX_HOTEL_BOOKING.md). Tiến độ và giới hạn kiểm chứng: [docs/STATUS.md](docs/STATUS.md).

APK demo debug đã build: `artifacts/hotel-booking-demo-debug.apk` (khoảng 175 MiB). Chỉ xem mẫu ngoại tuyến, chưa chạy trên thiết bị; bản mặc định từ mã nguồn dùng API thật.

Bản **API thật đã chạy trên SM A135F**: `artifacts/hotel-booking-api-SM-A135F-debug.apk` (ARM 32 bit), DEMO_MODE=false; cần backend cổng 8000 và USB reverse như bên dưới. Kết quả backend: **31 test đạt trên PostgreSQL 18.6**, không skip; dữ liệu hotel_booking giữ nguyên sau test.

## Chạy API thật trên SM A135F qua USB

PostgreSQL hiện dùng **18.6**. Cấu hình tại `backend/.env`: `DB_PASSWORD` là mật khẩu PostgreSQL, `DB_USER` hiện là `postgres`, `DB_NAME=hotel_booking`. Mã dựng URL từ từng trường nên không phải encode ký tự `@`, `#`, `/` trong mật khẩu. Nếu dùng DATABASE_URL thay thế, URL đó được ưu tiên và password cần percent-encode. Không đưa `.env` hoặc mật khẩu vào repo/chat.

File dump database nằm trong thư mục data

Từ thư mục `backend`, chạy server nếu chưa chạy:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Kiểm tra http://127.0.0.1:8000/health/db và http://127.0.0.1:8000/docs. `/health/db` thực hiện SELECT 1, trả 200 khi kết nối được và 503 khi không kết nối được; `/health` chỉ là liveness.

Tại gốc Flutter, giữ điện thoại kết nối USB và cho phép USB debugging:

```powershell
adb -s R58T801R8BD reverse tcp:8000 tcp:8000
flutter run -d R58T801R8BD --debug --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

USB reverse chuyển cổng 8000 của điện thoại về máy backend, không cần mở PostgreSQL/firewall. Chạy lại lệnh reverse sau khi rút/cắm USB. Nếu adb chưa trong PATH, dùng `& 'C:\Users\dactu\AppData\Local\Android\Sdk\platform-tools\adb.exe'` thay cho `adb`.

Tài khoản mẫu: `khach1@example.com`…`khach3@example.com`, `letan@example.com`, `quanly@example.com`. Mật khẩu chung cho các tài khoản seed mới nằm ở dòng `DEMO_PASSWORD` trong `backend/.env`, khác mật khẩu PostgreSQL. Xem trực tiếp tại máy; không gửi qua chat. Seed không thay mật khẩu tài khoản đã tồn tại.

Kiểm thử PostgreSQL từ `backend`:

```powershell
.\.venv\Scripts\python.exe manage_local.py test-postgres
```

Runner chỉ cấp cấu hình **hotel_booking_test** cho subprocess test. Fixture kiểm tra tên URL và `current_database()` trước TRUNCATE. Runner so sánh dấu vân tay dữ liệu `hotel_booking` trước/sau để kiểm chứng không đổi. Trên Windows cần quyền truy cập thư mục tạm của pytest. `manage_local.py prepare` tạo DB test nếu thiếu và seed không nhân đôi; schema được quản lý bằng `alembic upgrade head`, không reset/downgrade database phát triển.

## Chạy giao diện demo khi chưa có database

Từ thư mục gốc đang chứa `pubspec.yaml`:

```powershell
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

Lệnh `run` cần emulator hoặc thiết bị. Khi chưa có thiết bị vẫn chạy được `flutter analyze`, `flutter test` và thử `flutter build apk --debug --dart-define=DEMO_MODE=true`. Demo là màn hình xem mẫu có nhãn rõ ràng, không mô phỏng đặt phòng thành công, không gửi request hay dùng PostgreSQL/SQLite.

## Chuẩn bị backend trên Windows

Mục tiêu Python theo đặc tả là 3.13; PostgreSQL dùng 18 theo cập nhật của người dùng. Máy hiện dùng Python 3.15 để kiểm tra, chưa chứng nhận môi trường Python 3.13. Không thay PostgreSQL bằng SQLite.

Từ gốc dự án:

```powershell
cd backend
py -3.13 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
```

Nếu `.venv` hiện tại dùng Python 3.15, có thể tiếp tục dùng để kiểm tra tại máy; muốn môi trường đúng đặc tả, tạo `.venv313` bằng `py -3.13 -m venv .venv313` sau khi đã có 3.13 và thay `.venv` bằng `.venv313` trong các lệnh. Không cần xóa môi trường hiện có. Không đổi ExecutionPolicy.

Sao chép chuỗi ngẫu nhiên vừa tạo vào `JWT_SECRET` trong `.env`, không đưa secret vào repo. Sửa `DATABASE_URL` theo user/password thật. App từ chối secret mẫu/rỗng và URL khác `postgresql+psycopg://`.

Sau khi PostgreSQL đã cài, mở SQL Shell/pgAdmin bằng tài khoản quản trị và tạo riêng user/database (đổi các giá trị mẫu trước khi chạy):

```sql
CREATE USER hotel_app WITH PASSWORD 'CHOOSE_A_LOCAL_PASSWORD';
CREATE DATABASE hotel_booking OWNER hotel_app;
```

Trong database `hotel_booking`, quản trị viên chạy `CREATE EXTENSION IF NOT EXISTS btree_gist;` nếu tài khoản migration không đủ quyền. Dùng tài khoản migration đủ quyền tạo bảng/trigger; khi triển khai thật tách tài khoản runtime chỉ có quyền nghiệp vụ cần thiết. Không cấp tài khoản app quyền superuser. Không chạy lệnh tạo lại DB nếu DB đã tồn tại.

URL mẫu: `postgresql+psycopg://hotel_app:ENCODED_PASSWORD@localhost:5432/hotel_booking`. Password có ký tự đặc biệt phải percent-encode, có thể dùng `urllib.parse.quote(password, safe='')`; không ghi URL/password vào log hoặc lịch sử chat.

Tiếp theo, từ `backend`:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m app.cli seed
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Seed đọc DEMO_PASSWORD từ environment/.env hoặc hỏi qua prompt nếu chưa có; tạo 3 khách (`khach1@example.com`…`khach3@example.com`), `letan@example.com`, `quanly@example.com`, 3 loại, 12 phòng, 6 tiện nghi, ảnh placeholder tự tạo, 6 phiếu có lịch sử và 2 kỳ ngừng. Seed không tự chạy lúc startup, không nhân đôi marker, không đổi dữ liệu cũ. Xem [backend/README.md](backend/README.md) cho CLI nhân viên và chính sách seed.

Máy tính: http://127.0.0.1:8000/docs và `/health`. Health chỉ xác nhận server sống; không chứng minh DB đã kết nối. API nghiệp vụ cần migration và PostgreSQL thật. Không gọi `create_all` thay migration. **Downgrade về base xóa bảng/dữ liệu**; không thực hiện nếu chưa chủ động chấp nhận mất dữ liệu.

## Flutter dùng API thật

Mở PowerShell khác tại gốc dự án:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Mặc định `DEMO_MODE=false`. Emulator Android dùng `10.0.2.2`; điện thoại thật dùng IPv4 LAN máy backend, cùng Wi-Fi, chỉ cho cổng 8000 qua firewall mạng riêng khi cần. `localhost` trên Android là chính Android. Không mở cổng PostgreSQL cho điện thoại. Chỉ debug cho HTTP cleartext; release cần backend HTTPS:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_BACKEND_HOST
```

Cấu hình ký release hiện vẫn là debug key của template, cần thiết lập signing riêng trước phát hành. APK không chứa Python/PostgreSQL; backend chạy riêng. Không có thao tác phát hành công khai trong công việc này.

`image_picker` phục vụ chọn ảnh gallery cho quản lý; JWT lưu bằng `flutter_secure_storage`. Gặp 401 xóa phiên và về đăng nhập. Timeout sau gửi phiếu không retry tự động: mở Đơn của tôi để kiểm tra trước khi gửi lại.

## Kiểm tra

Từ `backend`: `.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider`.
Từ gốc Flutter: `flutter analyze`, `flutter test`.

Kiểm thử tích hợp chỉ chạy trên DB test riêng. Dùng `manage_local.py test-postgres` như hướng dẫn bên trên để cấp URL an toàn từ .env. Fixture chỉ chấp nhận chính xác `hotel_booking_test`, kiểm tra tên DB thực, migrate rồi **TRUNCATE DB test** trước mỗi bài; không reset hotel_booking. Nếu chạy pytest trực tiếp mà không có TEST_DATABASE_URL thì các bài PostgreSQL bị skip, không được coi là đã đạt.

Xem [docs/test_cases.md](docs/test_cases.md), [docs/business_rules.md](docs/business_rules.md), [docs/api.md](docs/api.md). Những test chưa chạy không được xem là đã đạt.
# Nâng cấp nghiệp vụ 18/10/2026

Hướng dẫn cấu hình Google/Facebook, SMTP và Firebase: [docs/service_configuration.md](docs/service_configuration.md). Chính sách lưu trú/phụ thu và bảo toàn dữ liệu: [docs/business_rules.md](docs/business_rules.md). Sau khi cập nhật source, chạy `backend/.venv/Scripts/python.exe -m alembic upgrade head` từ thư mục backend trước khi khởi động server mới. Seed danh mục bổ sung: `python -m app.seed_operations`; chỉ thêm `--replace-room-images` khi muốn thay toàn bộ ảnh danh mục và lưu bản cũ. Không reset database.


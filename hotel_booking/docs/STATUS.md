# TETRA Hotel — đợt tích hợp 18/10/2026

- Đã thêm đánh giá sau trả phòng thực tế, quản trị ẩn/hiện, Drawer dùng chung theo vai trò, cài đặt cá nhân/hệ thống và capabilities công khai an toàn.
- Thêm chuỗi ảnh crop/preview/avatar, CSV preview/confirm, PDF preview, lịch phòng/timeline, bản đồ, QR tra cứu, khóa phiên thiết bị, góp ý có ảnh riêng và video cấu hình.
- Chuẩn bị adapter MoMo/VNPAY server, đối soát chữ ký/idempotency/cạnh tranh và cách ly sandbox. Dịch vụ ngoài chưa có credentials nên không khẳng định đã thanh toán/gửi email/push thật.
- Tất cả lý do tùy chọn; nhận/trả phòng không hỏi lý do. Nhãn Android TETRA Hotel, applicationId và dữ liệu giữ nguyên.
- PostgreSQL đã migrate 0007, có dump và đối chiếu dữ liệu cũ; không reset hotel_booking. Kiểm thử tiền/đánh giá/CSV có cạnh tranh trên hotel_booking_test; 89 ca backend khác nhau và lượt đầy đủ 34 test Flutter đạt. Analyze không lỗi.
- Đã xử lý tương thích KGP/AGP9 của file_picker/OSM; pin OSM 1.4.6 để giữ minSdk 24. APK build/cài thành công SM A135F. QA điện thoại đã thử đánh giá sau trả phòng, gửi góp ý, lịch/tra cứu mã nhân viên; sửa và kiểm tra lại bản đồ lỗi 403. Bằng chứng và giới hạn xem báo cáo chi tiết.
- Đã thử quản trị ẩn đánh giá với lý do trống, cập nhật góp ý, render PDF và mở/hủy hộp chọn CSV Android. Backend đã khôi phục hotel_booking, đối chiếu dữ liệu không đổi; health/db và tải phòng trên điện thoại HTTP 200 qua Wi-Fi, DEMO_MODE=false, không adb reverse.
- Điểm vào: [screens.md](screens.md); quyết định: [integration_decisions.md](integration_decisions.md); cấu hình: [external_configuration.md](external_configuration.md); bằng chứng/giới hạn: [integration_acceptance.md](integration_acceptance.md).

---

## Nhật ký các phiên bản trước

# Hoàn thiện nâng cấp QA01–QA11 — 18/10/2026

- Đã sửa các mục đã duyệt, thêm nhận/trả phòng, phụ thu, hủy/no-show/giữ chỗ, đặt hộ/đổi lịch, khôi phục mật khẩu có SMTP, chuẩn bị OAuth/FCM và nút online chưa cấu hình.
- Ảnh thuộc từng phòng; loại phòng chỉ còn thông tin/tiện nghi. Danh mục chính có 13 loại, 22 phòng, 39 ảnh chụp thật có nguồn. Gỡ giải thích đồ án khỏi UI khách.
- Migration 0002→0004 đã chạy, có bản dump/uploads/source trước thay đổi và kiểm tra nguyên vẹn cột/dòng cũ. Không reset hotel_booking; không đổi mật khẩu tài khoản cũ.
- **73 bài backend đạt (unit/API/PostgreSQL/cạnh tranh), 25 bài Flutter đạt, analyze không có lỗi.** Kiểm thử DB riêng và kiểm thử điện thoại đều đối chiếu database chính không đổi.
- SM A135F đã chạy qua đăng ký/đăng nhập, xác nhận cùng ngày, nhận phòng, thêm phụ thu, yêu cầu trả, thu thử và hoàn tất trả trên hotel_booking_test. Đã sửa thêm lỗi đóng dialog gây màn hình đỏ, có test hồi quy và kiểm tra lại trên điện thoại.
- Backend đã trở về hotel_booking, API Wi-Fi 192.168.31.112:8000, DEMO_MODE=false, không adb reverse. Các dịch vụ ngoài chưa có credentials nên chưa E2E thật.
- Xem chi tiết bằng chứng và phần chưa kiểm thử: [upgrade_verification.md](upgrade_verification.md). Cấu hình dịch vụ: [service_configuration.md](service_configuration.md). Chính sách: [business_rules.md](business_rules.md).

---

## Nhật ký phiên bản trước (các giới hạn cũ đã được thay thế bởi bản cập nhật trên)

# Tiến độ triển khai — 17/10/2026

## Cập nhật mới nhất: trang chủ và phòng đề xuất

- Bố cục tìm kiếm mới: kính lúp trong ô Chào mừng mở/ẩn form, tự cuộn đến form nằm giữa banner và lưới đề xuất. Mặc định thu gọn; giữ nội dung đã nhập khi ẩn. Đã analyze không lỗi, build/cài APK Android thành công và kiểm tra mở → cuộn tới form → bấm lại ẩn trên SM A135F. Ảnh: `artifacts/SM-A135F-home-search.png`.
- Đổi nhãn điều hướng khách thành **Lịch sử**. Thanh điều hướng nền xanh `#123A52`, điểm nhấn vàng; tương phản chữ thường 9,83:1, chữ chọn 8,02:1, biểu tượng chọn 4,95:1.
- Thêm đề xuất công khai dạng lưới 2 cột: ảnh, số phòng, loại và giá/đêm; ẩn khi API lỗi/mất mạng. Dùng API thật, không đưa dữ liệu demo vào luồng này.
- Backend tính trạng thái **Đang sử dụng** từ phiếu đang giữ chỗ chưa đến ngày trả; loại khỏi đề xuất, không sửa trạng thái vệ sinh. Chi tiết quy tắc trong `business_rules.md`.
- Kiểm tra: **50 bài backend đạt** trên PostgreSQL `hotel_booking_test`, **20 bài Flutter đạt**, analyze không có lỗi, build Android ARM thành công. Có test phiếu chờ/xác nhận/hủy/từ chối/hết ngày trả, lịch ngừng, sức chứa; widget test hai cột, cỡ chữ lớn, loại phòng đang sử dụng và ẩn khi lỗi kết nối.
- `hotel_booking` giữ nguyên dữ liệu sau kiểm thử; không migration/reset. API thật `/rooms/recommended` trả 200, trả 6 phòng trống; danh mục hiện có 4 phòng được tính Đang sử dụng.
- Đã cài APK mới lên SM A135F, xác nhận trang chủ khách vãng lai có lưới 2 cột, nhãn Lịch sử, màu thanh điều hướng và request đề xuất HTTP 200 qua Wi-Fi `192.168.31.112:8000`, không có adb reverse. Ảnh chụp: `artifacts/SM-A135F-home-recommendations.png`; APK: `artifacts/tttp-wifi-SM-A135F-debug.apk`.
- Ảnh trên thẻ lấy từ danh mục backend; dữ liệu seed hiện vẫn chứa ảnh placeholder, chưa phải ảnh phòng thật. Chưa thao tác lại toàn bộ luồng khách đã đăng nhập trên điện thoại cho riêng lần nâng cấp này; widget đề xuất không phụ thuộc phiên đăng nhập.

## Mã đã triển khai

- Giữ Flutter hiện có tại gốc, thêm backend app theo router/schema/service/model, migration Alembic và docs; không tạo dự án lồng nhau.
- PostgreSQL/psycopg, 12 model và snapshot migration có FK/index/check, exclusion phòng/ngừng, deferred profile trigger; không SQLite, không create_all khi khởi động.
- FastAPI health/OpenAPI, register/login Argon2/JWT, hồ sơ, phân quyền khách/lễ tân/quản lý và quyền sở hữu phiếu.
- Danh mục công khai, tìm phòng theo ngày/sức chứa/giá/loại, phân trang, quote; đặt/hủy/xác nhận/từ chối và lịch sử chung transaction, khóa phòng trước để bảo vệ giao lịch chéo hai bảng.
- Quản lý loại/phòng/tiện nghi/ảnh, giới hạn giảm sức chứa/đổi loại, ảnh bìa nguyên tử, xác thực file, lịch tạm ngừng và kiểm tra xung đột.
- CLI tạo nhân viên và seed lặp lại không nhân đôi: 3 loại, 12 phòng, 6 tiện nghi, 6 ảnh placeholder, 5 tài khoản, 6 phiếu và 2 kỳ ngừng.
- Flutter Provider/HTTP/secure token/intl, đăng nhập/đăng ký/hồ sơ, tìm/chi tiết/gallery/báo giá/đặt, đơn/lịch sử/hủy, nhân viên xử lý phiếu, quản lý danh mục/tiện nghi/ảnh/ngừng. Có loading/lỗi/thử lại/phân trang, không retry POST khi timeout.
- Demo ngoại tuyến có nhãn rõ, chỉ xem mẫu. Mặc định app dùng API thật. HTTP cleartext chỉ mở trong Android debug; release cần HTTPS.

Mã đã nối API không đồng nghĩa luồng đã được chạy thành công với database/Android thật.

## Đã kiểm tra — cập nhật PostgreSQL 18 và điện thoại thật

- Backend pytest: **31 passed, không skip**, trên PostgreSQL **18.6**, database riêng `hotel_booking_test`. Gồm 16 unit test và 15 bài PostgreSQL: transaction/rollback, trigger/exclusion, phân quyền, ảnh và cạnh tranh bằng kết nối độc lập. Có một cảnh báo deprecation từ cặp Starlette/TestClient–httpx, không ảnh hưởng kết quả.
- Luồng HTTP thật với PostgreSQL test: đăng nhập → tìm phòng → quote → tạo phiếu → nhân viên xác nhận → khách refresh thấy trạng thái/lịch sử → hủy và kiểm tra phòng được giải phóng.
- Migration **0001** đã áp dụng lên `hotel_booking`; database ban đầu không có bảng. Không drop/reset/truncate database này. Tạo riêng `hotel_booking_test`; fixture chỉ được phép TRUNCATE database có tên chính xác đó, có kiểm tra `current_database()`.
- Seed thành công: 5 tài khoản, 3 loại, 12 phòng, 6 tiện nghi, 6 ảnh placeholder, 6 phiếu, 10 dòng lịch sử và 2 kỳ ngừng. Chạy seed lần nữa: dấu vân tay dữ liệu không đổi. So sánh dấu vân tay toàn bộ 12 bảng hotel_booking trước/sau test cũng không đổi.
- Server đang chạy tại `127.0.0.1:8000`: `/health` **200**, `/health/db` **200** với `database=connected`; `/rooms` **200**, total=12.
- Đã build/cài/chạy app debug trên **SM A135F** (`R58T801R8BD`, Android ARM 32 bit), **DEMO_MODE=false**, API `http://127.0.0.1:8000` qua `adb reverse tcp:8000 tcp:8000`. Log server xác nhận điện thoại tải danh mục/phòng trống/ảnh với HTTP 200. Đã xem ảnh chụp giao diện thật trong `artifacts/SM-A135F-api.png`: 12 phòng phù hợp, không có lỗi kết nối.
- APK API thật đã lưu riêng: `artifacts/hotel-booking-api-SM-A135F-debug.apk` (160.333.872 byte). Bản demo trước đó được giữ riêng, không bị ghi đè.
- Flutter analyze: **No issues found**.
- Flutter test: **8 passed**, gồm timeout POST báo kết quả chưa xác định/không retry và request hoàn tất sau khi Provider đã dispose.
- Migration đã được thực thi cả trên database phát triển và database test PostgreSQL thật; không còn chỉ kiểm tra SQL offline.
- Python compileall và CLI `--help` chạy được. Môi trường kiểm tra hiện có Python 3.15; mục tiêu vẫn Python 3.13 theo đặc tả, chưa kiểm tra bằng 3.13.
- APK demo debug: **build thành công**, đã build tăng dần lại với mã cuối. Artifact: `artifacts/hotel-booking-demo-debug.apk` (183.481.401 byte, khoảng 175 MiB), chỉ xem mẫu, không gọi API. Chưa cài/chạy trên Android. Lần build đầu bổ sung SDK Platform 34/35 và CMake 3.22.1; có cảnh báo Java/native access từ dependency nhưng build hoàn tất.

## Phạm vi còn chưa kiểm chứng

- Trên điện thoại đã kiểm tra khởi chạy và tải dữ liệu/ảnh thật. Chưa thao tác đầy đủ luồng hai tài khoản khách/nhân viên bằng UI điện thoại; luồng này đã đạt qua HTTP TestClient với PostgreSQL thật. Chưa kiểm tra đủ secure storage khi đóng/mở, mất USB/mạng giữa lúc gửi, chọn ảnh/permission và mọi màn hình quản lý trên Android.
- Chưa phát hành APK production, chưa cấu hình release signing riêng hoặc backend HTTPS triển khai thật.

## Bước tiếp theo

1. Giữ backend chạy, điện thoại nối USB; nếu cắm lại USB, chạy lại `adb reverse`. Lệnh chạy API thật nằm trong README.
2. Đăng nhập bằng tài khoản seed; mật khẩu mẫu ở `DEMO_PASSWORD` trong backend/.env (khác DB_PASSWORD). Không đưa secret vào repo/chat.
3. Hoàn tất checklist UI Android còn lại trong test_cases.md. Khi cần kiểm thử lại, chạy `python manage_local.py test-postgres` từ backend; không chạy reset hotel_booking.

Các mục chưa kiểm chứng cần được hoàn tất để đạt tiêu chí nghiệm thu toàn bộ đặc tả; không dùng demo hoặc test mock làm bằng chứng thay thế.

## Sửa kết nối đăng nhập — 17/10/2026

Đã tái hiện trên SM A135F: mất ánh xạ USB làm POST /auth/login lỗi transport, không có HTTP status và chưa gọi /users/me. Backend cũng đã dừng ở thời điểm kiểm tra ban đầu. PostgreSQL18 và database hotel_booking vẫn kết nối được; không reset DB.

Đã chạy backend cổng8000, khôi phục reverse8000→8000, cài đè APK mới. Điện thoại đăng nhập admin thành công; /auth/login, /users/me, dashboard và inbox đều200. App hiện ở Tổng quan TTTP. 17 Flutter tests passed; analyze sạch; build APK thành công. Lỗi HTTP/JSON giữ status/code/path và không bị đổi thành lỗi mạng. Debug trace không ghi payload, mật khẩu, token.

VS Code có cấu hình TTTP - SM A135F - API PostgreSQL với pre-launch script kiểm tra backend/database và ánh xạ USB; đã chạy kiểm tra thành công. Chi tiết và bằng chứng: [login_connection_fix.md](login_connection_fix.md). APK: artifacts/tttp-login-fix-SM-A135F-debug.apk; ảnh: artifacts/tttp-login-fixed.png.

## Chuyển sang Wi-Fi và kiểm tra phiên — 17/10/2026

Bản APK mới dùng API_BASE_URL=http://192.168.31.112:8000, DEMO_MODE=false, đã cài đè lên SM A135F. Backend nghe0.0.0.0:8000; rule Firewall đã xác minh Private/WiFi/LocalSubnet/local192.168.31.112/TCP8000. Không mở rule PostgreSQL. Điện thoại đã đổi cùng mạng, IP192.168.31.50. Đã gỡ adb reverse8000 và vẫn đăng nhập/hồ sơ/dashboard/inbox/tải phòng200, backend nhận đúng IP Wi-Fi điện thoại.

Đã thao tác đăng xuất/đăng nhập lại nhiều lần và force-stop/mở lại: token secure storage khôi phục, GET/users/me200 không cần POSTlogin. Token hết hạn thử trên API thật trả401; Flutter test kiểm tra xóa phiên khi401. Restart backend thật giữ token còn hạn hoạt động200; fingerprint DB trước/sau không đổi. Flutter19 tests passed, analyze sạch; test HTTP đặt phòng chọn lọc trên PostgreSQL test riêng1passed/42deselected, hotel_booking không đổi.

PostgreSQL service Running/Auto; không cần pgAdmin. Backend cần chạy sau bật máy bằng scripts/start_backend.ps1 -Lan; chưa cài backend thành Windows service. Cấu hình VS Code WiFi LAN có kiểm tra IP khớp APK. Người dùng đã xác nhận rút cáp vật lý vẫn mở được health, đăng nhập và tải phòng. Không tạo thêm đơn thật trong DB phát triển. Chi tiết lệnh và giới hạn: [wifi_running.md](wifi_running.md). APK: artifacts/tttp-wifi-SM-A135F-debug.apk.

# Nghiệm thu TETRA — tích hợp mới

Trạng thái mới nhất, phân biệt test PostgreSQL/widget/điện thoại/fixture và dịch vụ chưa cấu hình: [integration_acceptance.md](integration_acceptance.md). Các kết quả TTTP phía dưới là lịch sử trước đợt tích hợp mới.

---

# Kiểm chứng nâng cấp TTTP

Cập nhật 17/10/2026. Các mốc baseline cũ trong STATUS/test_cases không đại diện cho toàn bộ bản nâng cấp.

## Đã thực hiện

- [x] Đọc đặc tả nâng cấp và giữ dự án Flutter/FastAPI/PostgreSQL hiện hữu.
- [x] Migration cộng thêm 0002_tttp, giữ dữ liệu và migration 0001.
- [x] Theme/ảnh TTTP, tab theo vai trò, màn hình tách riêng, SearchCriteria xuyên đăng nhập, quote/PRICE_CHANGED và trang kết quả sau commit.
- [x] Admin quản lý tài khoản, audit, token_version, bảo vệ tự khóa/hạ quyền và thay đổi admin cạnh tranh.
- [x] Trạng thái vệ sinh và bảo trì có khoảng ngày, không thay lịch đặt.
- [x] Sổ thu/hoàn, idempotent request ID và khóa hạn mức trong PostgreSQL.
- [x] Báo cáo thực thu, công nợ, khoản cần hoàn, zero-fill, CSV BOM và PDF Unicode/cùng tổng.
- [x] Inbox sở hữu theo tài khoản, event cùng transaction; polling foreground và nhắc cục bộ có opt-in.
- [x] Backend Google/Meta kiểm tra credential; liên kết không dựa vào email trùng; không unlink cuối. Provider thiếu cấu hình không giả đăng nhập.
- [x] Admin/staff demo dùng mật khẩu cục bộ mới đủ 8 ký tự theo người dùng, kiểm tra riêng không lộ secret.
- [x] Launcher icon tất cả mật độ/adaptive với inset16%, nền #103B54, nhãn TTTP, applicationId không đổi.

## Kết quả kiểm thử

- PostgreSQL test riêng `hotel_booking_test`: **41 test đã qua**, gồm cạnh tranh thu/hoàn tiền, hai admin khóa lẫn nhau và kiểm tra verifier Google. Runner so sánh fingerprint từng bảng `hotel_booking` trước/sau, dữ liệu phát triển không đổi.
- Flutter 8 tests đã qua sau refactor đăng nhập và Provider. Analyze và APK đang kiểm tra lại sau các chỉnh sửa cuối; chỉ ghi nhận hoàn tất khi có kết quả.
- `/health/db` của backend mới ở cổng8001: **200 OK, database connected**; login admin/staff và quyền quản lý qua HTTP thật thành công. Điện thoại đã được ADB nhận sau khi người dùng cho phép USB.

## Cần kiểm tra thủ công / cấu hình ngoài

- [ ] Google/Facebook E2E thật: chưa có OAuth project/client/key hash/test users; mock không thay thế kiểm tra thật.
- [ ] FCM/push khi app tắt: chưa có cấu hình dịch vụ, chưa triển khai transport/outbox thiết bị.
- [ ] Nhắc cục bộ đủ 18:00 hôm trước, khởi động lại máy, từ chối/cấp lại permission và thay đổi đơn từ thiết bị khác.
- [ ] Tất cả thao tác admin/staff/khách trên điện thoại, text scaling, xoay máy, ảnh gallery/upload, chia sẻ PDF/CSV qua ứng dụng ngoài.
- [ ] Bản phát hành ký riêng/HTTPS; kiểm tra Python3.13 (máy hiện chạy3.15).

Không reset/uninstall app để né lỗi; không truncate database phát triển. Có thể chạy lại test qua manage_local.py test-postgres, fixture chỉ nhận đúng PostgreSQL hotel_booking_test.

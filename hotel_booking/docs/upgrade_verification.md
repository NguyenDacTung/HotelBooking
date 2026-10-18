# Kiểm chứng nâng cấp QA01–QA11 — 18/10/2026

## Mã và dữ liệu

- PostgreSQL giữ nguyên, migration 0002→0004. Có pg_dump trước nâng cấp, sao lưu uploads và source tại .local-backups/upgrade-20261018 (không đưa vào gói chia sẻ vì có dữ liệu cục bộ).
- Đã so sánh hash của toàn bộ cột/dòng cũ trước/sau migration; không reset database. Seed danh mục riêng giữ nguyên tài khoản, khách, nhân viên, phiếu, lịch sử và giao dịch tài chính. Ảnh cũ lưu metadata và file, chạy lại không nhân bản.
- Database chính sau seed: 13 loại, 22 phòng, 39 ảnh; 10 loại bổ sung, 10 phòng mới. Không tự đổi mật khẩu tài khoản cũ.
- APK dùng DEMO_MODE=false, API Wi-Fi http://192.168.31.112:8000, không adb reverse. Cài bằng install -r để giữ dữ liệu ứng dụng.

## Đối chiếu đề xuất đã duyệt

| Mã | Đã sửa | Bằng chứng / giới hạn |
| --- | --- | --- |
| QA01 | Xác nhận/từ chối/hủy cùng ngày trước nhận | PostgreSQL và thao tác xác nhận trên SM A135F trả 200 |
| QA02 | Không dùng tổng cũ khi tải lỗi; lưu nguyên UUID/nội dung thu hoàn chưa rõ kết quả | Test mở lại màn hình, HTTP 200 JSON lỗi rồi thử lại đúng UUID; test PostgreSQL cạnh tranh hạn mức/idempotency |
| QA03 | Controller tìm kiếm đồng bộ SearchProvider | Widget test đổi số khách trên form đang tồn tại |
| QA04 | Kiểm tra điện thoại client và server | Số Việt Nam/quốc tế hợp lệ, từ chối abc/123; giữ dữ liệu cũ |
| QA05 | Material cho SwitchListTile, chữ dài xuống dòng | Widget test màn hình cài đặt 360×800, cỡ chữ 2.0 |
| QA06 | Nhận → hóa đơn/phụ thu → thu/hoàn → trả → cần dọn | Test PostgreSQL đầy đủ; nhận đồng thời một 200/một 409; kết quả điện thoại ghi bên dưới |
| QA07 | Tạo hộ, hủy hộ, đổi phòng/ngày/giá có audit | Test API PostgreSQL. Đơn đã thu tiền cần hoàn/đơn thay thế, không viết lại sổ tiền |
| QA08 | Đã đặt trước khác đang có khách ở | Đề xuất loại cả hai nhóm; kể cả khách quá ngày dự kiến chưa trả |
| QA09 | Giữ chỗ mới hết hạn, phí hủy sát ngày/no-show theo snapshot | Test deadline, bảo vệ legacy; no-show cần nhân viên xác nhận sau ngày đến; không bắt buộc cọc |
| QA10 | Khôi phục mật khẩu SMTP, mã băm, hết hạn/dùng một lần/giới hạn thử; throttle login | Test SMTP giả lập + PostgreSQL; chưa gửi mail thật |
| QA11 | OAuth và FCM sẵn luồng cấu hình, server xác minh, thiết bị gắn tài khoản/phiên | Chưa có tài khoản dịch vụ nên chưa E2E Google/Facebook/FCM thật; xem service_configuration.md |

## Bổ sung theo yêu cầu

- Nút online có ở hóa đơn khách đang lưu trú/yêu cầu trả, chưa có gateway nên bị vô hiệu hóa; không tạo thanh toán giả.
- Phụ thu sớm/muộn theo mốc giờ, giường phụ/minibar/giặt là/hư hỏng/khác; hóa đơn và báo cáo gồm phụ thu. Quản lý miễn/hủy khoản phí phải nhập lý do, không khôi phục phí đã miễn khi tính lại.
- Ảnh thuộc phòng, chọn sau lưu khi thêm phòng hoặc quản lý trực tiếp khi sửa; loại phòng chỉ giữ tiện nghi. Ảnh chụp thật có giấy phép/nguồn trong assets.md; đã gỡ giải thích đồ án/ảnh minh họa khỏi UI khách.

## Kiểm thử điện thoại

Dùng riêng hotel_booking_test với tài khoản/phiếu QA, không tạo giao dịch giả vào database chính.

- Đã đăng ký khách mới thật bằng UI, đăng nhập, lấy hồ sơ/tải trang chủ; các request 201/200.
- Đã xác nhận phiếu cùng ngày bằng UI; kiểm tra backend trả 200.
- Nhận phòng trên UI đã lưu DANG_O, phụ thu nhận sớm 300.000đ trên giá 600.000đ/đêm. Lần đầu phát hiện lỗi controller bị dispose trước khi dialog đóng xong, dù request backend đã 200. Đã tái hiện bằng widget test thất bại, sửa formDialog chờ route.completed, test đạt và build lại.
- Đã cài bản sửa và nhận phòng lại trên phiếu mới: UI ổn định, không màn hình đỏ. Thêm 2 khoản minibar ×20.000đ, tổng hóa đơn 940.000đ; yêu cầu trả chuyển CHO_THANH_TOAN.
- Đã ghi thu 940.000đ qua UI nhân viên trên database test; sổ tiền tải lại đúng đã thu 940.000đ, còn phải thu 0đ. GET sổ tiền xác nhận duy nhất 1 giao dịch.
- Đăng xuất nhân viên, đăng nhập khách qua UI, mở đúng phiếu; nút Thanh toán online · Chưa cấu hình có và enabled=false. Ảnh: artifacts/QA-upgrade-customer-checkout.png.
- Đăng xuất khách, đăng nhập nhân viên, hoàn tất trả phòng qua UI. API xác nhận DA_HOAN_TAT, số dư/hoàn bằng 0, phòng CON_TRONG và CAN_DON_DEP. Ảnh: artifacts/QA-upgrade-completed-stay.png.
- Đã khôi phục backend về hotel_booking và đối chiếu toàn bộ fingerprint không thay đổi qua QA điện thoại. API LAN thực trả 200, cả 39 ảnh phòng trả HTTP 200, 13 loại không có hinh_anh.
- Lượt cuối: **73 bài backend đạt (unit/API/PostgreSQL/cạnh tranh)**, **25 bài Flutter đạt**, analyze không có lỗi. Log trong artifacts/upgrade-postgres-tests.log, upgrade-flutter-tests.log, upgrade-analyze.log; log trước sửa dialog được giữ riêng ở upgrade-dialog-regression-before-fix.log, không phải lỗi còn tồn tại.
- APK debug ARM đã build/cài bằng install -r, giữ applicationId/nhãn TTTP. Không chạy gateway/mail/OAuth/FCM thật khi chưa có cấu hình.
- Các luồng front desk đổi ngày/phòng, no-show, miễn phí, gửi email và cạnh tranh đồng thời được kiểm bằng API/PostgreSQL tự động; không coi chúng là đã thao tác hết trên UI điện thoại. Native gallery upload chưa kiểm thử toàn bộ trên điện thoại cho lần nâng cấp này; upload/đổi bìa/giới hạn file được kiểm trên PostgreSQL/API.

## Dịch vụ chưa kiểm thử thật

Không có cấu hình OAuth/SMTP/Firebase theo xác nhận của chủ dự án. Chức năng đã chuẩn bị và có hướng dẫn; các nút/endpoint báo rõ khi chưa cấu hình. Không có cổng thanh toán online. Không thử gửi tiền thật.

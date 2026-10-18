# Nghiệm thu tích hợp TETRA — 18/10/2026

## Đã kiểm thử tự động

- 88 kiểm thử backend trong lượt đầy đủ sau thêm media guard; thêm 1 kiểm thử outbox retry/backoff riêng đạt: tổng 89 ca khác nhau. Bao gồm PostgreSQL thật, không thay bằng SQLite.
- Đã kiểm tra đánh giá: sở hữu/quyền/hoàn tất thật/giới hạn sao/nhận xét, cạnh tranh cùng đơn, ẩn/hiện và tổng điểm công khai, không lộ email/điện thoại/mã đơn trong DTO công khai.
- CSV: BOM/quoted, lỗi từng dòng, không nhập một phần, replay, cạnh tranh hai batch.
- Feedback: metadata whitelist, ảnh private chỉ chủ sở hữu/admin, không phục vụ qua uploads; media chưa bền vững chặn ảnh nhưng vẫn cho gửi text.
- Thanh toán fixture: chưa cấu hình không tạo attempt; timeout giữ yêu cầu chờ và khóa thu tay; callback chữ ký/số tiền sai; lặp/cạnh tranh; trả về từ trình duyệt không ghi tiền; production đến sau hủy tạo khoản cần hoàn; sandbox không giảm nợ/không vào báo cáo thực thu.
- Outbox FCM bằng transport fixture: lỗi HTTP tạo retry có backoff trong PostgreSQL, không gọi lại trước thời điểm; không giữ transaction DB khi gọi HTTP; tag Android ổn định để retry không tạo thông báo trùng.
- Lượt đầy đủ cuối cùng: 34 test Flutter đạt. Bao gồm không mặc định 5 sao, capability unavailable khác chưa cấu hình, dispose an toàn, Drawer 4 vai trò ở 360px/chữ gấp đôi, route admin bị chặn trước khi gọi mạng, reminder ID ổn định và công cụ chụp góp ý tiếng Việt.

## Database chính

- Migration 0004 → 0006: đã dump và đối chiếu toàn bộ cột/dòng cũ của 22 bảng.
- Migration 0006 → 0007: đã dump và đối chiếu toàn bộ cột/dòng cũ của 27 bảng.
- File dump và xác nhận nằm trong `.local-backups/tetra-v3-*`; không chia sẻ công khai vì có dữ liệu thật. Không reset/drop/truncate hotel_booking, không đổi mật khẩu tài khoản đã có.
- Mỗi lượt test dùng hotel_booking_test, kiểm tra dấu vân tay hotel_booking trước/sau.
- Sau QA điện thoại đã đăng xuất tài khoản thử và khôi phục backend về hotel_booking; đối chiếu dấu vân tay đạt, dữ liệu chính không đổi. `/health/db` HTTP 200. PostgreSQL service Running/Auto, không cần mở pgAdmin.

## Native Android và điện thoại

- `dart analyze lib test`: No issues found. APK Android ARM debug đã build và cài thành công trên SM A135F. File: `artifacts/tetra-wifi-SM-A135F-debug.apk`.
- Đã sửa tương thích Kotlin của file_picker/OSM với cấu hình AGP hiện tại; pin OSM 1.4.6 để giữ minSdk 24. Nhãn launcher TETRA Hotel, applicationId giữ nguyên.
- App dùng API thật `http://192.168.31.112:8000`, `DEMO_MODE=false`, không adb reverse. Trang chủ tải phòng HTTP 200 qua Wi-Fi.
- Khách QA đăng nhập trên điện thoại, mở lịch sử/chi tiết đơn đã trả, chọn 4 sao và gửi nhận xét; chi tiết hiển thị lại đúng đánh giá. Ảnh: `artifacts/QA-TETRA-review-sent.png`. Các thao tác QA dùng database test riêng.
- Gửi góp ý text từ điện thoại thành công; nhân viên đăng nhập, chọn V3-02 trong lịch và xem đúng đơn đang xác nhận, rồi tra cứu được đơn bằng mã tham chiếu từ màn quét mã. Ảnh: `artifacts/QA-TETRA-staff-calendar-booked.png`, `artifacts/QA-TETRA-staff-lookup.png`.
- QA phát hiện tile bản đồ trả ảnh lỗi 403; đã sửa User-Agent nhận diện TETRA, URL HTTPS canonical và cache riêng. Cài lại kiểm tra bằng ảnh thực tế: bản đồ/đường và ghim khách sạn hiển thị đúng, không còn ảnh lỗi. Ảnh: `artifacts/QA-TETRA-map-fixed.png`.
- Quản trị QA ẩn đánh giá khi để trống lý do; API công khai không còn trả đánh giá, chủ đánh giá vẫn xem được bản đang ẩn. Ảnh: `artifacts/QA-TETRA-admin-review-hidden.png`.
- Xuất và mở PDF báo cáo từ API thật bằng pdfrx trên Android: render được chữ tiếng Việt, biểu đồ và bảng số liệu QA. Ảnh: `artifacts/QA-TETRA-report-pdf.png`.
- Hộp chọn CSV Android đã mở thành công, sau đó hủy, không đọc/chọn tệp cá nhân. Luồng preview/confirm CSV được kiểm thử ở API PostgreSQL, chưa chọn file và nhập trọn luồng trên điện thoại.
- Quản trị mở được góp ý gửi từ điện thoại và đổi sang Đang xử lý. Ảnh: `artifacts/QA-TETRA-admin-feedback.png`.
- Kết thúc: mở lại app ở phiên khách vãng lai, trang chủ hiển thị phòng 103/104 của database chính, request `/rooms/recommended` HTTP 200 qua Wi-Fi; không adb reverse. Ảnh: `artifacts/QA-TETRA-final-development.png`. Đã trả lại thiết lập giữ sáng màn hình USB ban đầu.

## Còn phụ thuộc cấu hình/thao tác thực tế

- Chưa có merchant MoMo/VNPAY, public HTTPS/IPN và credentials hợp lệ: chưa thực hiện thanh toán hoặc đối soát trên sandbox/live của nhà cung cấp. Adapter và ca fixture không thay cho nghiệm thu merchant.
- Hoàn tiền tự động qua gateway chưa bật; không có thao tác nào giả lập hoàn tiền thật. Hoàn thủ công chỉ ghi nhận sau khi nhân viên/admin đã hoàn thực tế.
- Google/Facebook, SMTP và Firebase: đã có mã/config nhưng chưa kiểm thử đăng nhập ngoài, gửi email hoặc nhận push từ dịch vụ thật khi chưa có cấu hình.
- Video: chưa có URL giới thiệu khách sạn thật; phần khách ẩn video khi chưa cấu hình. Chưa nghiệm thu stream thật của khách sạn.
- Xác thực sinh trắc học/PIN, quyền camera/vị trí/thông báo và giao nhắc đúng giờ khi Doze/reboot phụ thuộc thiết bị/quyền/thao tác chủ máy; không tự thay PIN hoặc đăng ký vân tay người dùng.
- Chưa nghiệm thu toàn luồng camera quét QR, chọn/chụp/crop ảnh và gửi ảnh góp ý trên thiết bị. Màn tra cứu QR đã thử nhập mã thủ công; quyền/ảnh/API có các kiểm thử riêng, không coi đó là quét camera hoặc chọn ảnh thật.
- UI/CRUD/biên mạng có kiểm thử tiêu biểu; không khẳng định đã thao tác thủ công mọi tổ hợp, mọi điện thoại hoặc mọi phiên bản Android.
- Mạng LAN vẫn cần cùng mạng truy cập được nhau, backend/PostgreSQL/máy tính đang chạy và IP/firewall đúng. PostgreSQL không mở cho điện thoại. Hosting free có ngủ/giới hạn worker/storage cần cấu hình riêng; không hứa hoạt động nền 24/7 nếu hosting không đáp ứng.

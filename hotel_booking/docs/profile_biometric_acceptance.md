# Hồ sơ, căn ảnh và đăng nhập vân tay — 18/10/2026

## Thay đổi hiện tại

- Hồ sơ dùng một avatar trong thẻ có họ tên/email/vai trò; nút Đổi ảnh đại diện nằm cùng thẻ, bỏ icon người thứ hai.
- Avatar dùng khung tròn cố định: kéo ảnh, chụm/mở hai ngón; có hướng dẫn, Đặt lại vị trí ảnh, preview tròn, Căn lại và Dùng ảnh này. Ảnh phòng vẫn đổi được vùng cắt.
- Bỏ LocalSessionGate, không hỏi sinh trắc học sau khi vừa đăng nhập bằng mật khẩu và không khóa lại sau 30 giây nền.
- Nút Đăng nhập bằng vân tay ở màn đăng nhập không kiểm tra ô email/mật khẩu. Bật trước trong Cài đặt khi đang đăng nhập; xác nhận mật khẩu tài khoản một lần và xác thực sinh trắc để đăng ký điện thoại.
- Android Keystore tạo khóa EC P-256 không xuất ra ngoài, mỗi lần ký cần BIOMETRIC_STRONG với CryptoObject. Chỉ public key được gửi lên server; không lưu mật khẩu, ảnh vân tay hoặc token dài hạn để mở bằng một biến bool.
- Server phát challenge ngẫu nhiên 2 phút, một lần dùng; xác minh ECDSA/SHA-256 rồi cấp access token mới. Khóa/đổi mật khẩu/quyền, credential hết hạn hoặc thu hồi đều được kiểm tra. Credential tối đa 90 ngày; thay vân tay làm khóa thiết bị mất hiệu lực, cần dùng mật khẩu rồi bật lại.
- Mỗi điện thoại lưu một tài khoản vân tay. Đăng xuất vẫn giữ lựa chọn đã bật (ghi rõ ở Cài đặt); tắt trong Cài đặt để thu hồi/xóa khóa khi dùng máy chung. Khi khởi động mới trên máy đã bật, không tự khôi phục JWT cũ trước khi người dùng bấm đăng nhập.
- Chỉ mới có native signer Android; nền tảng không hỗ trợ vẫn dùng mật khẩu. Không thay PIN/đăng ký vân tay OS hộ người dùng.

Thiết kế đối chiếu tài liệu Android: https://developer.android.com/identity/sign-in/biometric-auth . Không dùng kết quả boolean của local_auth làm bằng chứng gửi server.

## Kiểm thử tự động

- Lượt Flutter cuối sau sửa tọa độ crop: 42/42 đạt. Gồm nhập vân tay với email/mật khẩu rỗng, không silent restore JWT khi đã bật, thu hồi server, hủy đăng ký, một avatar trên màn hẹp/chữ lớn, crop/reset/preview và kiểm tra pixel ảnh xuất ra đúng vùng đang hiển thị.
- Lượt backend đầy đủ: 97 đạt, 1 lỗi kiểm tra số bảng cũ; sửa kỳ vọng metadata từ 25 lên 27 và chạy lại bộ unit 16/16 đạt. Tổng 98 ca khác nhau đã đạt qua các lượt này, không nói rằng lượt đầy đủ ban đầu không có lỗi.
- 9 ca sinh trắc PostgreSQL bao gồm chữ ký thật P-256, owner, xác nhận mật khẩu đăng ký, credential chưa kích hoạt, sai khóa, nonce hết hạn/đã dùng, sai purpose, đổi token_version/khóa tài khoản, hết hạn/thu hồi, chống boolean giả và cạnh tranh cùng challenge chỉ một lần thành công.
- Analyze: No issues found. APK debug ARM build/cài thành công; API LAN thật, DEMO_MODE=false, applicationId giữ nguyên.
- Migration 0008: dump `.local-backups/tetra-v3-20261018-134912/hotel_booking.dump`; đối chiếu toàn bộ cột/dòng cũ 27 bảng không đổi. Không reset hotel_booking.

## Nghiệm thu thiết bị

- SM A135F đã cài bản APK mới; màn hồ sơ chỉ có một avatar, có ảnh chụp `artifacts/QA-profile-single-avatar.png`.
- Đăng nhập bằng mật khẩu đã vào hồ sơ trực tiếp, không yêu cầu quét thêm để vào phiên.
- Chủ máy đã chạm cảm biến thật khi đăng ký và khi đăng nhập lại; xác nhận “Đã chạm vân tay, vào app được”. Lượt đăng nhập vân tay không nhập email/mật khẩu: log chỉ có `/auth/biometric/challenge` 200, `/auth/biometric/login` 200, `/users/me` 200 và tải phòng/thông báo 200, không có POST `/auth/login` trong lượt đó. Ảnh `artifacts/QA-fingerprint-login-success.png`.
- Đã tắt đăng ký vân tay của tài khoản QA và đăng xuất trước khi khôi phục backend chính. Đã kiểm chứng toàn bộ `hotel_booking` không đổi trong giai đoạn QA riêng; sau đó mới thực hiện yêu cầu bổ sung dữ liệu chính ở `recording_data.md`.
- Đã chọn duy nhất tệp tự tạo `TETRA_AVATAR_MINHANH.png` qua Android PhotoPicker → Duyệt qua… → DocumentsUI; thử kéo, reset, xem trước, căn lại và upload. Backend lưu avatar, ảnh trả HTTP 200.
- Kiểm tra hình ảnh phát hiện lượt đầu bị lệch dù upload 200: vùng hiển thị và tọa độ pixel do editor tính sau reset không khớp. Đã thêm `VisibleImageCropper` quy đổi từ hình chữ nhật ảnh/vùng chọn đang hiển thị sang pixel nguồn, áp dụng cả ảnh phòng; không sửa thư viện trong Pub Cache. Test mới so sánh pixel thật sau decode, không chỉ giả callback thành công.
- APK mới đã build/cài đè thành công. Đã thử lại chọn đúng ảnh MA, kéo/reset, xem trước, căn lại và lưu trên SM A135F. Kiểm tra bằng mắt và pixel: trước sửa ảnh 345×345 bị cắt chữ; sau sửa ảnh 468×468, cả MA nằm giữa, URL ảnh 200. Bằng chứng cuối: `artifacts/QA-avatar-MA-fixed-preview.png`, `artifacts/QA-avatar-MA-fixed-saved.png`. Avatar nằm ở tài khoản Minh Anh mới trong dữ liệu chính theo yêu cầu bổ sung, không sửa avatar tài khoản cũ.
- Đã thử bổ sung góp ý có ảnh trên điện thoại: chụp riêng màn góp ý, vẽ nét đỏ, xem trước và gửi. Đã kiểm tra file private có nét vẽ, không đăng nhập nhận 401/chủ nhận 200. Chưa thử mọi tổ hợp bỏ/chụp lại/xoay máy/hủy tiến trình.

Không dùng widget test hoặc kiểm thử chữ ký server thay cho việc chủ máy chạm cảm biến. Dữ liệu ảnh/CSV/đơn QA chỉ dùng trên hotel_booking_test, không chọn ảnh cá nhân trên điện thoại.

## Dịch vụ vẫn cần cấu hình

OAuth, SMTP, Firebase, merchant MoMo/VNPAY và video thật vẫn chưa có cấu hình/nội dung hợp lệ. Chỉ kiểm tra trạng thái chưa cấu hình, không coi là đã đăng nhập/gửi mail/nhận push/thanh toán ngoài thật. Giao nhắc khi Doze/reboot cần thử thời gian và thiết bị thực tế, không tự sửa đồng hồ để giả kết quả.

Các ca native chưa được nghiệm thu trọn vẹn: camera chụp avatar/ảnh phòng và khôi phục khi Android hủy tiến trình; quét QR bằng camera; chọn CSV đến xác nhận nhập trên điện thoại; GPS/chỉ đường với đủ trường hợp quyền/vị trí tắt; nhắc lịch trong Doze/reboot. Đây là giới hạn kiểm thử, không phải cam kết các ca này đã đạt. Kịch bản tiến độ chủ động dùng các luồng đã chạy thật, không phụ thuộc chúng.

# Cấu hình ngoài — TETRA

Không gửi mật khẩu, JWT, khóa merchant hoặc JSON tài khoản dịch vụ vào chat/log. Sao chép các tên biến từ `backend/.env.example`, điền giá trị thật ở `.env` cục bộ; file này không nằm trong gói code chia sẻ. Hướng dẫn OAuth, SMTP, Firebase chi tiết vẫn ở `service_configuration.md`.

## Trạng thái tính năng

`GET /app/capabilities` là nguồn trạng thái máy chủ, chỉ có enabled/configured/environment/reason_code. Flutter phân biệt đang tải, lỗi tải và chưa cấu hình, đồng thời yêu cầu cấu hình SDK phía client cho social/push. Cấu hình xong phải restart backend; cấu hình build client cần build/cài lại. Trạng thái configured chỉ cho biết đủ trường cấu hình, không khẳng định đã thông mạng hoặc được merchant duyệt.

## MoMo

- Tạo tài khoản merchant và nhận partner code/access key/secret key đúng môi trường.
- `PAYMENT_ENVIRONMENT=sandbox`; `MOMO_ENDPOINT=https://test-payment.momo.vn/v2/gateway/api`.
- Điền `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY` ở backend.
- `PAYMENT_PUBLIC_BASE_URL` phải là HTTPS công khai trỏ tới backend; IP LAN:8000 không nhận được callback từ Internet. Không mở PostgreSQL cho điện thoại/Internet.
- Khai báo IPN `POST /payments/momo/ipn`, redirect `/payments/return`; server sử dụng `payWithMethod`, không ghi nhận tiền từ redirect.
- Production cần credentials production và `https://payment.momo.vn/v2/gateway/api`.

## VNPAY

- Điền `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, cùng `PAYMENT_PUBLIC_BASE_URL` HTTPS thật.
- Sandbox payment URL `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`; query URL `https://sandbox.vnpayment.vn/merchant_webapi/api/transaction`.
- Khai báo IPN `GET /payments/vnpay/ipn`, return `/payments/return`. Dùng phiên bản 2.1.0, VND nhân 100 ở biên giao thức, không nhân 100 trong ledger.
- Production: xác nhận URL và hợp đồng với VNPAY; cấu hình payment host `pay.vnpay.vn`, query host `merchant.vnpay.vn`, không dùng lẫn khóa sandbox.

## Đối soát và trường hợp chưa xác định

Khách vào hóa đơn → Thanh toán online → chọn cổng. Số tiền do server tính. Lưu request_id theo tài khoản/đơn/cổng để timeout vẫn dùng lại cùng yêu cầu. Kiểm tra kết quả gọi query server; không tin màn hình trình duyệt hoặc lời khai client. Attempt CREATED/PENDING khóa thu/hoàn thủ công, đổi phòng/ngày và hoàn tất trả phòng. Hết hạn đường dẫn không tự chứng minh giao dịch thất bại; cần kết quả xác minh. Không xóa attempt để thu lại.

Sandbox ghi dữ liệu thử có nhãn riêng và không thanh toán hóa đơn thật. Chỉ production đã xác minh chữ ký/IPN/query mới tính thực thu. Hoàn online tự động chưa cấu hình; hoàn thủ công dành cho khoản đã hoàn thật, không bấm để giả lập chuyển tiền.

## Ảnh và triển khai máy chủ

`UPLOAD_DIR` chứa ảnh phòng/avatar công khai; `PRIVATE_UPLOAD_DIR` chứa ảnh phản hồi riêng và không mount StaticFiles. Sao lưu cả hai cùng database theo quyền truy cập thích hợp. Dùng volume bền vững khi hosting; nếu chưa có thì `PERSISTENT_MEDIA_ENABLED=false`, không để người dùng tưởng ảnh đã lưu lâu dài. Không đưa thư mục riêng lên web public.

## Thông tin khách sạn, video và quyền điện thoại

Admin → Cài đặt → Thông tin công khai khách sạn: chỉ nhập điện thoại/email/website/video thật. Video cần URL HTTPS media trực tiếp, có chú thích; để trống nếu chưa có, không dùng trang YouTube. Bản đồ cố định tại tọa độ đặc tả. Camera chỉ mở khi chụp/quét; vị trí chỉ khi tính khoảng cách; thông báo xin khi bật nhắc; khóa thiết bị phải được chủ máy cho phép. Không cần cấp mọi quyền để tìm/đặt phòng.

## Nguồn giao thức

- [MoMo Collection Link](https://developers.momo.vn/v3/docs/payment/api/collection-link/)
- [MoMo IPN](https://developers.momo.vn/v3/docs/payment/api/result-handling/notification/)
- [MoMo Query](https://developers.momo.vn/v3/docs/payment/api/payment-api/query/)
- [VNPAY thanh toán 2.1.0](https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html)
- [VNPAY truy vấn và hoàn](https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr&refund.html)

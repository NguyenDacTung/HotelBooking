# Dữ liệu bổ sung để quay báo cáo — 18/10/2026

Đã thêm trực tiếp vào PostgreSQL `hotel_booking`, không bật DEMO_MODE. Đây là dữ liệu giả lập phục vụ trình diễn của chủ dự án, không phải hồ sơ khách hàng hoặc chứng từ thu tiền thực. Không gửi email, SMS hay gọi cổng thanh toán khi thêm dữ liệu.

## Đã thêm

- 12 phòng 401–412, gồm Standard Single/Double/Twin, Superior Double/Twin, Deluxe King/Twin, Family Quad, Junior Suite và Executive Suite. Giá/sức chứa lấy từ danh mục hiện có.
- 23 ảnh gắn với từng phòng, có ảnh bìa và thứ tự; sử dụng ảnh Pexels đã có trong dự án. Nguồn/quyền sử dụng xem `docs/assets.md`. Không gắn ảnh vào loại phòng.
- 6 khách hàng có họ tên và số liên hệ giả lập; 1 lễ tân Thu Trang. Tài khoản dễ dùng: `minhanh@tetra.test`, `thutrang@tetra.test`; mật khẩu mới lưu ở `backend/.env` khóa `TETRA_RECORDING_PASSWORD`, không đổi mật khẩu tài khoản cũ.
- 22 đơn ở nhiều trạng thái: 9 hoàn tất, 2 chờ xác nhận, 4 đã xác nhận, 1 đang ở, 1 chờ thanh toán, 2 hủy, 1 từ chối, 1 không đến, 1 hết hạn.
- 9 đánh giá sau lưu trú, thông báo cho khách, lịch sử xử lý và các khoản thu/phụ thu tương ứng. Đơn hoàn tất đã đối chiếu đủ tiền; không lấy dữ liệu cá nhân ngoài dự án.
- Phòng 411/412 để trống ban đầu cho lượt quay. Lượt chạy thử đã tạo thêm đơn/thu/đánh giá tự nhiên, được ghi nhận riêng, không xóa để che kết quả.
- Lượt thử đã hoàn tất: giữ thêm 1 đơn phòng 411, minibar Aquafina 40.000 đồng, khoản thu mô phỏng 990.000 đồng và đánh giá 5 sao. Phòng đã qua dọn và sẵn sàng; hiện có 30 đơn/10 đánh giá. Minh Anh có avatar chữ MA tự tạo và một góp ý đề xuất bộ lọc ban công kèm ảnh chú thích riêng, không dùng ảnh cá nhân.

## An toàn và tái sử dụng

- Script `scripts/seed_recording_data.py` mặc định chỉ kiểm tra trên `hotel_booking_test`, trong giao dịch rollback. Có kiểm tra ràng buộc và chạy lặp không trùng.
- `--apply` chỉ chấp nhận cấu hình `hotel_booking`, sao lưu bằng pg_dump trước, rồi thêm trong một giao dịch. Không reset/truncate/xóa hoặc cập nhật bản ghi cũ.
- Sau thêm, so sánh hash từng bản ghi cũ ở tất cả bảng để xác nhận vẫn còn nguyên. Không chỉ so sánh tổng số dòng.
- Bản sao lưu trước lần thêm: `.local-backups/recording-20261018-172239/hotel_booking.dump`; kết quả số lượng ở `manifest.json` cùng thư mục. Các ảnh cũ không bị ghi đè.
- Ngày lịch mẫu được neo theo ngày chạy lần đầu (18/10/2026). Chạy lại sẽ bỏ qua bộ đã có, không đẩy ngày đơn cũ sang ngày mới. Khi quay ngày khác, hãy tạo đơn mới theo ngày quay; phòng sẵn sàng phải do lễ tân xác nhận đã dọn.
- Khi chuyển máy cần chuyển cả database và thư mục `backend/uploads`; chỉ sao chép mã nguồn sẽ không mang theo ảnh đã gắn trong database. Giữ file `.env` riêng tư.

Kịch bản thao tác: `docs/KICH_BAN_QUAY_TIEN_DO_TETRA.md`.

# TETRA Hotel — Kịch bản quay báo cáo tiến độ

Ngày chuẩn bị: 18/10/2026. Chỉ quay thao tác, không cần lời thoại. Dự kiến 8–12 phút; có thể cắt các đoạn nhập tài khoản và chờ tải.

## Chuẩn bị

- Máy tính bật PostgreSQL và backend; điện thoại cùng Wi-Fi. Kiểm tra `/health/db` trước khi quay.
- Khách hàng: `minhanh@tetra.test`. Lễ tân: `thutrang@tetra.test`. Quản lý: `admin@tttp.test` hiện có.
- Mật khẩu hai tài khoản mới nằm trong `backend/.env`, mục `TETRA_RECORDING_PASSWORD`. Không quay file `.env`, bàn phím lúc nhập mật khẩu hoặc mã truy cập.
- Chọn ngày đến là ngày quay, ngày đi là hôm sau, 2 khách. Ưu tiên phòng 411; nếu phòng đã được giữ thì chọn 412 hoặc phòng còn trống khác.
- Dữ liệu bổ sung là hồ sơ giả lập phục vụ trình diễn, không đại diện khách lưu trú hay doanh thu thực tế. Nội dung trong app sử dụng cách diễn đạt tự nhiên; các khoản thu mẫu không gọi cổng thanh toán.

## Thao tác chính

| Đoạn | Tài khoản | Thao tác |
| --- | --- | --- |
| 1. Khám phá | Chưa đăng nhập | Mở trang chủ → lướt ảnh chuyển tự động và lưới phòng → bấm kính lúp cạnh lời chào → chọn ngày, 2 khách → tìm phòng → mở chi tiết một phòng → xem ảnh, tiện nghi, giá và đánh giá. |
| 2. Đặt phòng | Khách hàng | Tài khoản → Đăng nhập / Đăng ký → đăng nhập Minh Anh → Tìm phòng → Loại phòng: Deluxe King → Tìm phòng → cuộn đến phòng 411 → Tiếp tục đặt phòng → kiểm tra thông tin liên hệ và chính sách → Xác nhận đặt phòng → Xem chi tiết. |
| 3. Xác nhận và nhận phòng | Lễ tân | Đăng xuất khách → đăng nhập Thu Trang → Yêu cầu đặt phòng → mở đúng đơn của Minh Anh, phòng 411 → Xác nhận đặt phòng → Nhận phòng. Hai bước này xử lý trực tiếp, không bắt nhập lý do. |
| 4. Phát sinh và thanh toán | Lễ tân | Trong chi tiết đơn → Thêm phụ thu → chọn Minibar, nhập nội dung “Aquafina 500 ml”, số lượng 2, đơn giá 20.000 → Ghi nhận → Yêu cầu trả phòng → Thu / hoàn tiền → Ghi nhận thu tiền → nhập đúng số còn phải thu trên hóa đơn, chọn Tiền mặt → trong lượt mô phỏng tích xác nhận đã nhận tiền → Xác nhận ghi nhận → quay lại → Hoàn tất trả phòng. |
| 5. Dọn phòng | Lễ tân | Quay về → Tình trạng phòng → lọc Cần dọn dẹp → tìm đúng phòng 411 → Cập nhật tình trạng → Đang dọn dẹp → Xác nhận → lọc Đang dọn dẹp → phòng 411 → Cập nhật tình trạng → Sẵn sàng → Xác nhận. Mô phỏng đã dọn xong trước khi chuyển Sẵn sàng. |
| 6. Đánh giá | Khách hàng | Đăng xuất lễ tân → đăng nhập Minh Anh → Lịch sử → mở đơn vừa hoàn tất → Đánh giá phòng → 5 sao, nhận xét ngắn → Gửi đánh giá → Trang chủ → kính lúp → Tìm phòng để cập nhật kết quả → mở phòng 411 → bấm ngôi sao “Đánh giá phòng” để xem công khai. |
| 7. Tổng quan quản lý | Quản lý | Đăng xuất → đăng nhập quản lý → xem Tổng quan → Báo cáo → Tháng này → cuộn xuống cuối bảng số liệu → Xuất PDF → xem hai trang báo cáo → Quay lại. Có thể mở thêm danh mục Phòng trong menu. |

Không sửa đồng hồ điện thoại. Nếu nhận phòng trước giờ quy định, hóa đơn có thể phát sinh phụ thu nhận sớm; luôn thu theo số đang hiển thị thay vì ghi cứng tổng tiền vào kịch bản. Trả phòng sớm vẫn tính số đêm đã đặt theo chính sách hiện tại.

## Đoạn ngắn tùy chọn

- Hồ sơ: mở Tài khoản, xem ảnh đại diện duy nhất → Đổi ảnh đại diện → chọn ảnh riêng → kéo ảnh trong khung tròn → xem trước → dùng ảnh.
- Vân tay: bật trước trong Cài đặt bằng tài khoản muốn quay → đăng xuất → ở màn đăng nhập bấm nút vân tay → chạm cảm biến. Chỉ cần một lượt, không cần quay quá trình thiết lập.
- Thông báo: mở chuông → mở một thông báo cập nhật đơn → quay lại.
- Bản đồ: mở bản đồ khách sạn, xem vị trí và tiện ích chỉ đường.

Không đưa Google/Facebook, email khôi phục, push từ máy chủ hoặc thanh toán MoMo/VNPAY thật vào luồng chính khi chưa cấu hình dịch vụ.

## Kết quả chạy thử

Đã chạy các đoạn chính trên SM A135F ngày 18/10/2026 bằng giao diện, API thật qua Wi-Fi, database `hotel_booking`:

- Tìm phòng và xem ảnh/đánh giá khi chưa đăng nhập; đặt phòng 411 bằng Minh Anh thành công.
- Thu Trang xác nhận và nhận phòng; nhập 2 chai Aquafina × 20.000 đồng; yêu cầu trả; ghi nhận thu 990.000 đồng và hoàn tất trả phòng. Đối chiếu PostgreSQL: đủ 5 trạng thái, dư nợ 0, khoản cần hoàn 0.
- Chuyển phòng 411 qua Cần dọn dẹp → Đang dọn dẹp → Sẵn sàng.
- Minh Anh gửi đánh giá 5 sao; kiểm tra được cả trong đơn và công khai với tên rút gọn “Anh T.”.
- Quản lý đăng nhập, xem Tổng quan, chọn Tháng này và xuất PDF; Android hiển thị được cả hai trang. Chưa thực hiện chia sẻ PDF ra ứng dụng bên ngoài.
- Đã sửa kịch bản theo nút thực tế: “Xác nhận đặt phòng”, “Tình trạng phòng”, bước xác nhận thu tiền, và tìm lại sau khi đổi vai trò để tránh kết quả cũ. Đưa dọn phòng lên trước đánh giá để giảm một lượt đổi tài khoản.

Lượt diễn thử tạo thêm 1 đơn, 1 khoản minibar, 1 khoản thu và 1 đánh giá, giữ lại trong dữ liệu chính. Sau lượt thử: 34 phòng, 62 ảnh phòng, 15 tài khoản, 30 đơn và 10 đánh giá. Phòng 411 đã sẵn sàng cho lượt quay tiếp theo.

Vân tay đã được chủ máy thử thành công ở phiên kiểm tra riêng; không yêu cầu lặp lại cho kịch bản tiến độ. Ảnh đại diện được kiểm tra bổ sung; xem `docs/profile_biometric_acceptance.md` để biết bản sửa và kết quả cuối.

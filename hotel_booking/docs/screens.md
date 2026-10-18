# Điểm vào chức năng TETRA

| Vai trò | Điểm vào | Chức năng |
|---|---|---|
| Khách vãng lai | Trang chủ / tìm phòng | Carousel, tìm kiếm thu gọn, lưới đề xuất, chi tiết và đánh giá công khai |
| Mọi vai trò | Menu ba gạch → Thông tin khách sạn | Video khi có URL, bản đồ, khoảng cách theo yêu cầu, liên hệ thật khi đã cấu hình |
| Khách đã đăng nhập | Lịch sử → đơn đã trả phòng | Hiện đánh giá đã gửi hoặc nút đánh giá; chọn sao trước khi gửi |
| Khách đã đăng nhập | Menu → Đánh giá của tôi | Các đánh giá của riêng mình, gồm đánh giá đang ẩn và lý do nếu có |
| Khách đã đăng nhập | Đơn xác nhận/đang ở/chờ trả → Thanh toán online | Chọn cổng theo capabilities, xem attempt và kiểm tra kết quả |
| Khách đã đăng nhập | Chi tiết đơn → Mã đặt phòng | QR và mã tham chiếu không chứa thông tin cá nhân |
| Nhân viên/admin | Menu → Lịch phòng | Chọn phòng, lịch tháng và timeline cùng ngày, mở chi tiết đơn; tạm ngừng theo khoảng |
| Nhân viên/admin | Menu → Quét mã đặt phòng | Camera/nhập tay, tra cứu backend, không tự thực hiện nghiệp vụ |
| Admin | Menu → Quản lý đánh giá | Bộ lọc phòng/loại/sao/hiện ẩn/ngày, phân trang, ẩn/hiện với lý do tùy chọn |
| Admin | Menu → Nhập phòng từ CSV | Chọn file, xem lỗi từng dòng, xem trước, xác nhận toàn bộ và chống nhập trùng |
| Admin | Báo cáo → Xuất PDF | Xem trong app, lưu/chia sẻ qua hệ điều hành; CSV giữ luồng chia sẻ |
| Mọi tài khoản | Tài khoản → Đổi ảnh đại diện | Chọn/chụp, căn ảnh, xem lại, upload |
| Admin | Phòng → Ảnh phòng | Ảnh thuộc từng phòng, chọn/chụp và crop/preview trước upload |
| Mọi tài khoản | Menu → Góp ý và báo lỗi | Nội dung, ảnh chú thích tại màn riêng, xem/bỏ ảnh, thông tin thiết bị opt-in |
| Admin | Menu → Phản hồi khách hàng | Xem phản hồi, ảnh có xác thực, cập nhật tiến độ xử lý |
| Mọi tài khoản | Menu → Cài đặt | Mật khẩu, liên kết, thông báo/giờ nhắc, bật/tắt Đăng nhập bằng vân tay; trạng thái dịch vụ |
| Thiết bị đã bật vân tay | Màn đăng nhập → Đăng nhập bằng vân tay | Không nhập email/mật khẩu; ký challenge bằng khóa Keystore để server cấp phiên mới, không khóa phiên sau đăng nhập mật khẩu |
| Admin | Cài đặt → Thông tin công khai khách sạn | Nội dung liên hệ/video công khai; không chỉnh khóa bí mật qua giao diện |

Menu lọc theo vai trò và route guard kiểm tra lại; backend tiếp tục là nguồn kiểm tra quyền. Nhận/trả phòng không yêu cầu lý do. Các kiểm tra khác như còn nợ, quyền, phòng sạch và trạng thái đơn vẫn giữ nguyên.

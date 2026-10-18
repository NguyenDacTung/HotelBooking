# Quy tắc nghiệp vụ TTTP — cập nhật 18/10/2026

Yêu cầu nâng cấp trực tiếp của người dùng thay thế các giới hạn cũ trong đặc tả gốc. PostgreSQL được giữ nguyên; không reset hotel_booking. Kiểm thử cạnh tranh và giao dịch thử dùng riêng hotel_booking_test.

## Đặt phòng và lưu trú

- Mỗi phiếu giữ một phòng vật lý, khoảng [ngày nhận, ngày trả), 1–30 đêm, ngày theo Việt Nam. Ngay ngày nhận vẫn được xác nhận/từ chối/hủy trước khi nhận phòng.
- CHO_XAC_NHAN → DA_XAC_NHAN → DANG_O → CHO_THANH_TOAN → DA_HOAN_TAT. Nhánh kết thúc khác: DA_HUY, DA_TU_CHOI, HET_HAN, KHONG_DEN.
- Bốn trạng thái đầu giữ lịch. Khóa hàng phòng trước phiếu, kết hợp PostgreSQL exclusion constraint chống giao lịch. Đổi phòng khóa hai phòng theo ID tăng dần.
- Lễ tân tạo đơn hộ khách bằng email/tên/điện thoại, đổi phòng/ngày trước nhận và hủy hộ có lý do. Email mới có hồ sơ chưa có mật khẩu; khách đặt mật khẩu qua email khôi phục khi SMTP hoạt động. Không cấp mật khẩu mặc định.
- Đổi phòng/ngày hiển thị giá mới, kiểm tra giá dự kiến, tính lại giá và ghi audit. Phiếu có giao dịch thu/hoàn không được đổi trực tiếp: cần đối chiếu/hoàn và tạo đơn thay thế để giữ sổ tiền.
- Nhận phòng chỉ đúng ngày đến, sau xác nhận; phòng phải sẵn sàng và khách trước đã trả. Phiếu đã nhận không được hủy theo luồng hủy đặt chỗ.
- Khách/nhân viên yêu cầu trả phòng để lập hóa đơn. Nhân viên thu/hoàn theo tiền thực tế rồi hoàn tất trả. Phụ thu tính lại theo lúc bàn giao; còn khoản cần thu/hoàn thì chặn hoàn tất, giữ hóa đơn mới để đối chiếu.
- Trả thành công lưu thời điểm thực tế, kết thúc phiếu và chuyển phòng sang CAN_DON_DEP. Không chuyển phòng đang có khách sang dọn/bảo trì. Vệ sinh theo CAN_DON_DEP → DANG_DON_DEP → SAN_SANG.

## Chính sách phụ thu TTTP

Đây là chính sách của ứng dụng, tham khảo vận hành khách sạn; không phải mức phí chung bắt buộc. Khách xem trước đặt. Giá và chính sách được chốt vào từng phiếu mới, không đổi theo cấu hình về sau.

| Trường hợp | Mức mặc định |
| --- | --- |
| Nhận từ 14:00, trả đến 12:00 | Giá phòng đã chốt |
| Nhận trước 06:00 / từ 06:00 đến trước 14:00 | 100% / 50% giá một đêm |
| Trả sau 12:00 đến 15:00 / sau 15:00 đến 18:00 / sau 18:00 | 30% / 50% / 100% giá một đêm |
| Trả quá ngày dự kiến | Thêm 100% mỗi ngày quá hạn, cộng phần theo giờ ngày bàn giao |
| Giường phụ | Gợi ý 250.000đ/đêm, tối đa một giường/phiếu; lễ tân xác nhận khả năng kê và tổng phí trước ghi nhận |
| Minibar, giặt là, hư hỏng, khác | Ghi phát sinh thực tế, căn cứ/nội dung, đơn giá và số lượng |
| Hủy đơn chờ / hủy đơn xác nhận cách giờ nhận từ 24 giờ | Không phí |
| Hủy xác nhận dưới 24 giờ / không đến | Một đêm, không vượt tổng tiền phòng |

Mốc giờ theo Asia/Ho_Chi_Minh. Đúng 12:00 chưa có phụ thu; đúng 15:00 là 30%, đúng 18:00 là 50%. Phụ thu tự động có mã cố định theo phiếu/loại, gọi lại không cộng trùng. Quản lý hủy phụ thu trước hoàn tất phải nhập lý do, giữ lịch sử thay vì xóa.

Không bắt buộc cọc; có thể ghi thu một phần trên phiếu xác nhận. Tiền thu trừ hoàn đối chiếu với tiền phòng + phụ thu chưa hủy. Hủy không xóa giao dịch, không tự chuyển tiền ngân hàng. Quản lý chỉ ghi hoàn sau khi đã hoàn tiền thực tế.

Phiếu mới chờ giữ tối đa 24 giờ, không quá cuối ngày đến. Worker giải phóng mỗi 60 giây; thao tác xác nhận/hủy kiểm tra hạn ngay lúc xử lý. No-show do nhân viên đánh dấu sau ngày đến, có lý do. Phiếu cũ trước migration không tự hết hạn, không bị tính phụ thu tự động hồi tố; giá/liên hệ/sổ tiền giữ nguyên.

Tham khảo: [Vinpearl – quy định đặt phòng](https://vinpearl.com/en/reservations-regulations), [điều khoản](https://vinpearl.com/en/terms-of-use). Khung 14:00/12:00 và mức tiền TTTP là lựa chọn triển khai, không khẳng định mọi khách sạn dùng giống nhau.

## Phòng, ảnh và đề xuất

- DANG_O/CHO_THANH_TOAN là DANG_SU_DUNG, kể cả quá ngày trả dự kiến. Phiếu giữ tương lai là DA_DAT_TRUOC. Tách khỏi vệ sinh/vận hành.
- Đề xuất không chứa cả hai nhóm; còn lọc kinh doanh/sức chứa/lịch ngừng. Tìm thông thường vẫn xét giao ngày với các phiếu giữ lịch, nhưng luôn loại phòng còn khách DANG_O/CHO_THANH_TOAN, kể cả ngày trả dự kiến đã qua hoặc đang tìm ngày tương lai. Báo giá/tạo đơn/đặt hộ/đổi phòng/xác nhận cũng chặn phòng chưa hoàn tất trả; không đợi đến nhận phòng mới báo lỗi. Đây là chính sách bảo thủ hiện tại: chỉ mở lại khả năng đặt sau khi khách cũ hoàn tất trả. Nhận thực tế vẫn phải chờ dọn xong.
- Ảnh thuộc anh_phong.ma_phong, loại không có ảnh; tiện nghi theo loại. Thêm phòng: lưu rồi chọn ảnh ngay trong luồng; sửa phòng có nút quản lý ảnh. JPEG/PNG/WebP ≤5 MiB, một bìa/phòng, khóa phòng khi đổi bìa.
- Migration giữ bảng ảnh cũ ở anh_loai_phong_legacy, chép liên kết cho từng phòng. Seed thay ảnh lưu metadata anh_phong_archive, giữ file cũ; chạy lại không nhân bản danh mục/ảnh.
- Loại mới: Standard Single/Double/Twin, Superior Double/Twin, Deluxe King/Twin, Family Quad, Junior/Executive Suite; không đổi loại các phòng cũ. Giá TTTP tự thiết lập.
- Ảnh chụp thật có nguồn/giấy phép trong assets.md; không dùng AI và không khẳng định là ảnh một cơ sở TTTP đã khảo sát. Không đưa giải thích kỹ thuật vào UI khách.

## Tài khoản, tiền và dịch vụ ngoài

- Argon2; JWT có hạn/phiên bản thu hồi; kiểm tra vai trò/quyền sở hữu mỗi request. Khách xem/sửa phiếu khác nhận 404.
- Điện thoại kiểm tra cả Flutter/backend. Email chuẩn hóa, mật khẩu không tự cắt khoảng trắng. Login tối đa 8 lần/email và 60 lần/IP/15 phút; thành công xóa đếm email.
- Thu/hoàn dùng UUID chống trùng và kiểm tra số dư dưới khóa. App lưu nguyên yêu cầu chưa rõ kết quả theo tài khoản/phiếu để thử lại khi mở lại, không tạo mã mới sau timeout/JSON lỗi. Khi tải hóa đơn lỗi, tổng cũ bị vô hiệu hóa.
- Khôi phục/OAuth/push chỉ chạy khi cấu hình hợp lệ. Thanh toán online chưa có gateway: nút bị vô hiệu hóa, không ghi thu giả. Xem service_configuration.md.

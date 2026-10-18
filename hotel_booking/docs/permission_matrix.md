# Ma trận quyền TTTP

| Tác vụ | Khách | Lễ tân | Admin (QUAN_LY) |
| --- | --- | --- | --- |
| Xem/tìm/quote phòng | Có, kể cả chưa đăng nhập | Có | Có |
| Tạo/hủy đơn của mình | Có, theo hạn | Không | Không |
| Xem đơn | Của mình | Tất cả | Tất cả |
| Xác nhận/từ chối | Không | Có, theo trạng thái/hạn | Có |
| Vệ sinh/bảo trì theo lịch | Không | Có | Có |
| Thu tiền thực tế | Không | Có, theo số dư/trạng thái | Có |
| Hoàn tiền | Không | Không | Có, có giao dịch gốc/lý do |
| Giá, phòng, loại, tiện nghi, ảnh, kỳ ngừng | Không | Không | Có |
| Quản lý tài khoản/quyền/audit | Không | Không | Có, có ràng buộc admin cuối/tự sửa quyền |
| Báo cáo JSON/CSV/PDF | Không | Không | Có |
| Hồ sơ, đổi mật khẩu, liên kết và inbox | Của mình | Của mình | Của mình |

Backend kiểm tra quyền hiện hành và token_version ở mỗi request. Các API mới dùng `core/permissions.py`; API cũ có dependency tương đương. 401 xóa phiên Flutter, 403 báo thiếu quyền. Bảo vệ không phụ thuộc vào ẩn nút trên UI.

## Quyền bổ sung — 18/10/2026

| Tác vụ | Khách | Lễ tân | Quản lý |
| --- | --- | --- | --- |
| Đặt/hủy hộ, đổi phòng/ngày trước nhận | Không | Có | Có |
| Nhận phòng, hoàn tất trả, xác nhận no-show | Không | Có | Có |
| Yêu cầu hóa đơn trả phòng | Chỉ đơn mình | Có | Có |
| Ghi phụ thu phát sinh | Không | Có, đang ở/chờ trả | Có |
| Miễn/hủy phụ thu | Không | Không | Có lý do, trước hoàn tất |
| Thu thực tế gồm phụ thu/phí hủy | Không | Theo số dư và trạng thái | Có |
| Đăng ký/hủy thiết bị push | Chỉ phiên của mình | Chỉ phiên của mình | Chỉ phiên của mình |

Ảnh quản lý theo phòng, không theo loại. Các quyền đọc/tạo ảnh vẫn chỉ quản lý. Nút online chưa cấu hình không cấp quyền thu tiền hay thay trạng thái thanh toán.

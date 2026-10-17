# Ma trận quyền TTTP

| Tác vụ | Khách | Lễ tân | Admin (QUAN_LY) |
| --- | --- | --- | --- |
| Xem/tìm/quote phòng | Có, kể cả chưa đăng nhập | Có | Có |
| Tạo/hủy đơn của mình | Có, theo hạn | Không | Không |
| Xem đơn | Của mình | Tất cả | Tất cả |
| Xác nhận/từ chối | Không | Có, theo trạng thái/hạn | Có |
| Vệ sinh/bảo trì theo lịch | Không | Có | Có |
| Thu tiền thực tế | Không | Có, chỉ đơn xác nhận | Có |
| Hoàn tiền | Không | Không | Có, có giao dịch gốc/lý do |
| Giá, phòng, loại, tiện nghi, ảnh, kỳ ngừng | Không | Không | Có |
| Quản lý tài khoản/quyền/audit | Không | Không | Có, có ràng buộc admin cuối/tự sửa quyền |
| Báo cáo JSON/CSV/PDF | Không | Không | Có |
| Hồ sơ, đổi mật khẩu, liên kết và inbox | Của mình | Của mình | Của mình |

Backend kiểm tra quyền hiện hành và token_version ở mỗi request. Các API mới dùng `core/permissions.py`; API cũ có dependency tương đương. 401 xóa phiên Flutter, 403 báo thiếu quyền. Bảo vệ không phụ thuộc vào ẩn nút trên UI.

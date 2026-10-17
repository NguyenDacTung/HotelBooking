# Hợp đồng API

Chạy backend và mở `/docs` hoặc `/openapi.json` để xem đầy đủ request/response.

| Method | Path | Operation |
| --- | --- | --- |
| POST | `/auth/register` | Register |
| POST | `/auth/login` | Login |
| GET | `/users/me` | Me |
| PATCH | `/users/me` | Update Me |
| GET | `/room-types` | Types |
| GET | `/rooms` | Rooms |
| GET | `/rooms/available` | Available |
| GET | `/rooms/{room_id}` | Detail |
| POST | `/rooms/{room_id}/quote` | Quote |
| POST | `/bookings` | Create |
| GET | `/bookings/my` | Mine |
| GET | `/staff/bookings` | All Bookings |
| GET | `/bookings/{booking_id}` | Detail |
| PATCH | `/bookings/{booking_id}/cancel` | Cancel |
| PATCH | `/staff/bookings/{booking_id}/confirm` | Confirm |
| PATCH | `/staff/bookings/{booking_id}/reject` | Reject |
| GET | `/staff/room-types` | Types |
| POST | `/staff/room-types` | Create Type |
| PATCH | `/staff/room-types/{key}` | Patch Type |
| GET | `/staff/rooms` | Rooms |
| POST | `/staff/rooms` | Create Room |
| PATCH | `/staff/rooms/{key}` | Patch Room |
| GET | `/staff/amenities` | Amenities |
| POST | `/staff/amenities` | Create Amenity |
| PATCH | `/staff/amenities/{key}` | Patch Amenity |
| PUT | `/staff/room-types/{key}/amenities` | Set Amenities |
| GET | `/staff/room-closures` | Closures |
| POST | `/staff/room-closures` | Create Closure |
| PATCH | `/staff/room-closures/{key}` | Patch Closure |
| POST | `/staff/room-types/{key}/images` | Upload |
| PATCH | `/staff/images/{key}` | Patch Image |
| DELETE | `/staff/images/{key}` | Delete Image |
| GET | `/health` | Health |
| GET | `/health/db` | Health Db |

Danh sách trả `{items, page, page_size, total}`; page ≥ 1, page_size 1–100. Tìm phòng theo ngày, sức chứa, loại và đơn giá mỗi đêm; sắp xếp giá tăng rồi mã phòng. Phiếu có filter trạng thái/ngày nhận, sắp xếp ngày tạo giảm và UUID ổn định.

Ngày lưu trú YYYY-MM-DD, khoảng `[ngày nhận, ngày trả)`; timestamp có múi giờ; tiền là số nguyên VND. Mã phòng là PK, khác số phòng hiển thị. Phiếu/tài khoản dùng UUID.

Login JSON: `{email, mat_khau}`. Register thêm `ho_ten`, `so_dien_thoai` tùy chọn. Đặt: `{ma_phong, ngay_nhan, ngay_tra, so_khach, ten_lien_he, sdt_lien_he, ghi_chu?}`. Giá, ma_kh, trạng thái và nhân viên xử lý do server quyết định. Request ghi từ chối trường ngoài hợp đồng.

Lỗi: `{error: {code, message, details?}}`. 400 nghiệp vụ, 401 phiên, 403 quyền, 404 không có/không sở hữu, 409 xung đột, 422 validation, 500 lỗi chung. Không trả hash, raw SQL, stack trace hoặc giá trị password/token trong lỗi validation.

Tạo/hủy và /bookings/my: KHACH_HANG. Chi tiết phiếu: chủ sở hữu hoặc nhân viên. /staff/bookings: LE_TAN hoặc QUAN_LY. Danh mục, ảnh và lịch ngừng: chỉ QUAN_LY. Không có đăng ký nhân viên hoặc đổi quyền qua API.

Upload multipart field `file`, thêm `thu_tu` và `la_anh_bia` tùy chọn; giới hạn 5 MiB, kiểm tra nội dung JPEG/PNG/WebP. PUT tập tiện nghi nhận `{ma_tn: [1,2]}` không trùng. PATCH kỳ ngừng không nhận ma_phong; dừng kỳ bằng dang_hieu_luc=false.

Nguồn quy tắc: [business_rules.md](business_rules.md). Đặc tả đầy đủ: [DAC_TA_CODEX_HOTEL_BOOKING.md](DAC_TA_CODEX_HOTEL_BOOKING.md).

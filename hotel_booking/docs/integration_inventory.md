# Kiểm kê tích hợp TETRA — 18/10/2026

Flutter 3.47.5 / Dart 3.13.4; Android SM A135F, build ARM32; PostgreSQL 18, psycopg/SQLAlchemy/Alembic. Không thay database hoặc applicationId. `pubspec.lock` lưu toàn bộ phiên bản chính xác và phụ thuộc gián tiếp.

| Package | Phiên bản đã resolve | Nhóm | Vai trò | Thay đổi | License gói |
|---|---|---|---|---|---|
| flutter_easyloading | 3.0.5 | 1 | Overlay nhập CSV | Mới | MIT |
| shimmer | 3.0.0 | 1 | Skeleton phòng hiện có | Giữ | BSD (xem LICENSE) |
| flutter_animate | 4.5.2 | 1 | Chuyển động nhẹ trang chủ, tôn trọng giảm chuyển động | Giữ | BSD (xem LICENSE) |
| carousel_slider | 5.1.2 | 2 | Banner trang chủ | Giữ | MIT |
| table_calendar | 3.3.0 | 2 | Lịch phòng nhân viên | Mới | Apache-2.0 |
| easy_date_timeline | 2.0.9 | 2 | Timeline đồng bộ ngày với lịch tháng | Mới | MIT |
| cached_network_image | 3.4.1 | 3 | Ảnh phòng/avatar, cache và fallback | Giữ/mở rộng | MIT |
| image_picker | 1.2.4 | 3 | Chụp/chọn, khôi phục lost data Android | Mở rộng | Apache-2.0 |
| crop_your_image | 2.0.1 | 3 | Căn ảnh và preview xác nhận | Mới | Apache-2.0 |
| easy_image_viewer | 1.5.1 | 3 | Zoom ảnh phòng | Giữ | MIT |
| path_provider | 2.1.6 | 4 | Thư mục tạm riêng cho export | Mở rộng | BSD (xem LICENSE) |
| file_picker | 11.0.3 | 4 | Chọn CSV nhập phòng | Mới | MIT |
| pdfrx | 2.6.5 | 4 bổ trợ | Preview báo cáo PDF server | Mới | MIT |
| share_plus | 11.1.0 | 4 bổ trợ | Lưu/chia sẻ qua hệ điều hành | Giữ | BSD (xem LICENSE) |
| url_launcher | 6.3.3 | 5 | Liên hệ, chỉ đường, cổng thanh toán HTTPS | Mở rộng | BSD (xem LICENSE) |
| connectivity_plus | 6.1.5 | 5 | Tín hiệu mạng; request thật quyết định kết nối | Giữ | BSD (xem LICENSE) |
| device_info_plus | 12.4.0 | 5 | Metadata tự chọn gửi cùng góp ý | Mới | BSD (xem LICENSE) |
| package_info_plus | 9.0.1 | 5 bổ trợ | Phiên bản app cho góp ý | Mới | BSD (xem LICENSE) |
| video_player | 2.14.1 | 6 | Video khách sạn có cấu hình, pause nền, fullscreen | Mới | BSD (xem LICENSE) |
| flutter_local_notifications | 19.5.0 | 7 | Nhắc lịch theo giờ chọn, ID cố định theo đơn | Mở rộng | BSD (xem LICENSE) |
| firebase_messaging | 16.7.0 | 8 | Push có cấu hình client và server | Giữ/chuẩn bị dịch vụ | BSD (xem LICENSE) |
| geolocator | 14.0.2 | 9 | Vị trí một lần theo yêu cầu, khoảng cách thẳng | Mới | MIT |
| flutter_osm_plugin | 1.4.6 | 9 | Bản đồ OSM và marker khách sạn | Mới | MIT |
| mobile_scanner | 7.4.2 | 10 | Quét QR/nhập mã staff, debounce và lifecycle | Mới | BSD (xem LICENSE) |
| qr_flutter | 4.1.0 | 10 bổ trợ | QR mã tham chiếu khách hàng | Mới | BSD (xem LICENSE) |
| flutter_secure_storage | 9.2.4 | 11 | JWT phiên đăng nhập | Giữ | BSD (xem LICENSE) |
| local_auth | 3.0.2 | 11 | Khóa thiết bị cho phiên đã có, kiểm tra JWT lại | Mới | BSD (xem LICENSE) |
| feedback | 3.2.0 | 11 | Ảnh chú thích chỉ tại màn góp ý an toàn | Mới | Apache-2.0 |
| fl_chart | 1.2.0 | 4 bổ trợ | Biểu đồ thực thu hiện có | Giữ | MIT |

Không thêm nhóm 12 AI/Tools. Không đồng thời cài nhiều map/scanner/notifier. Lý do thay toast, badge và các mục có điều kiện xem `integration_decisions.md`. Không sử dụng SDK merchant trên Flutter; chữ ký ở backend. PDF engine có các notice PDFium kèm theo phân phối; khi đóng gói sản phẩm giữ thông báo bản quyền thư viện.

Mã mới backend: reviews.py, integration.py, online_payments.py, gateways.py; schema 0005/0006/0007 thêm 5 bảng, avatar, environment ledger và ràng buộc. Mã mới Flutter được liệt kê theo điểm vào trong `screens.md`.

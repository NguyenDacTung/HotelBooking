# Ánh xạ nhóm học phần — tích hợp TETRA

Bảng không gán package bổ trợ vào slide nếu không có căn cứ. Phiên bản cụ thể: `integration_inventory.md`/`pubspec.lock`.

| Nhóm | Gói/cách làm | Luồng dùng và tình huống sâu | Bằng chứng kiểm tra |
|---|---|---|---|
| 1 | flutter_easyloading, shimmer, flutter_animate; ScaffoldMessenger thay toast_notification | Khóa nút nhập CSV, finally dismiss; ảnh/skeleton/lỗi; giảm animation theo thiết bị; giữ bottom bar hiện có | Widget màn nhỏ/chữ lớn, kiểm tra lifecycle, build/native QA |
| 2 | carousel_slider, table_calendar, easy_date_timeline | Banner trang chủ; chọn ngày tháng/timeline đồng bộ, đổi phòng/tháng tải API mới và bỏ response cũ; ngày trả không giữ đêm | test_calendar_staff_access_and_bounded_range, QA lịch |
| 3 | cached_network_image, image_picker, crop_your_image, easy_image_viewer | Camera/gallery/lost-data → crop → preview → upload; avatar/ảnh phòng mới UUID; zoom; hủy không lưu | API quyền/giới hạn tệp, QA chọn ảnh/preview theo quyền thiết bị |
| 4 | path_provider, file_picker; pdfrx/share_plus/reportlab/fl_chart bổ trợ | CSV UTF-8 BOM/quoted, xem lỗi từng dòng, xác nhận all-or-nothing, batch idempotent; PDF từ server xem/chia sẻ, dọn tệp riêng khi logout | test_csv_validate_atomic_confirm_replay, test_csv_competing_batches_only_one_commits; QA export |
| 5 | url_launcher, connectivity_plus, device_info_plus; package_info_plus bổ trợ | Không dùng trạng thái Wi-Fi thay HTTP; deep route có guard; liên hệ chỉ thông tin thật; model/OS/version opt-in và whitelist | Bộ login_diagnostics; test_private_feedback_image_and_device_whitelist; QA Wi-Fi |
| 6 | video_player | URL trực tiếp có cấu hình, play/pause/scrub/fullscreen; pause khi nền, dispose khi rời | Analyze/build; E2E video thật cần URL media do admin nhập |
| 7 | Material Badge thay badges, flutter_local_notifications | Unread từ server; giờ nhắc theo account, ID booking ổn định, hủy và logout dọn nhắc | Flutter test notification settings, stable reminder ID; cấp quyền/giờ giao thông báo cần thiết bị |
| 8 | firebase_messaging; adapters HTTP MoMo/VNPAY | Push opt-in, outbox hiện có; attempt durable/one-active, IPN signed, query, callback duplicate, pending khóa thu thủ công, sandbox không thanh toán nợ thật | Test PostgreSQL IPN giả mạo/lặp/đến muộn/thu đồng thời; E2E merchant/FCM cần credentials |
| 9 | geolocator, flutter_osm_plugin | Điểm cố định, attribution, xin vị trí một lần theo nút, khoảng cách thẳng và mở chỉ đường ngoài | Build và QA native; định vị phụ thuộc quyền/GPS/mạng thiết bị |
| 10 | mobile_scanner; qr_flutter bổ trợ | Mã opaque không PII/JWT, nhân viên lookup, nhập tay khi camera bị từ chối, debounce/stop/dispose | Test phân quyền lookup; QA camera/nhập mã |
| 11 | flutter_secure_storage, local_auth, feedback | JWT secure storage; mở khóa thiết bị không phát JWT; feedback không bao auth/payment, preview và ảnh private auth | Test phiên/401, review route guard, private feedback; QA khóa thiết bị cần thao tác chủ máy |

Không thêm nhóm AI/Tools, payment IAP hay backend Firebase thay PostgreSQL. Đánh giá, Drawer và audit là nghiệp vụ của ứng dụng, không được mô tả thành tính năng tự có của một package.

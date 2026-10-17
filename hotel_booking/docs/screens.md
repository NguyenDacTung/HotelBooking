# Các trang TTTP

Các tab đi qua HomeShell, giữ widget trong IndexedStack và nạp khi lần đầu chọn. Các trang con nhận tham số bằng MaterialPageRoute; route có tên nằm trong app/app_router.dart. File compatibility account.dart/home.dart/bookings.dart/management.dart chỉ export các trang đã tách.

| Class | File | Quyền |
| --- | --- | --- |
| AccountDetailScreen | `lib/screens/admin/account_detail_screen.dart` | Admin |
| AccountsScreen | `lib/screens/admin/accounts_screen.dart` | Admin |
| AmenitiesScreen | `lib/screens/admin/amenities_screen.dart` | Admin |
| DashboardScreen | `lib/screens/admin/dashboard_screen.dart` | Admin |
| RevenueReportScreen | `lib/screens/admin/revenue_report_screen.dart` | Admin |
| RoomClosuresScreen | `lib/screens/admin/room_closures_screen.dart` | Admin |
| RoomImagesScreen | `lib/screens/admin/room_images_screen.dart` | Admin |
| RoomTypesScreen | `lib/screens/admin/room_types_screen.dart` | Admin |
| RoomsScreen | `lib/screens/admin/rooms_screen.dart` | Admin |
| LoginScreen | `lib/screens/auth/login_screen.dart` | Công khai |
| RegisterScreen | `lib/screens/auth/register_screen.dart` | Công khai |
| BookingDetailScreen | `lib/screens/customer/booking_detail_screen.dart` | Khách (chi tiết/tìm: công khai) |
| BookingReviewScreen | `lib/screens/customer/booking_review_screen.dart` | Khách (chi tiết/tìm: công khai) |
| BookingSuccessScreen | `lib/screens/customer/booking_success_screen.dart` | Khách (chi tiết/tìm: công khai) |
| HomeScreen | `lib/screens/customer/home_screen.dart` | Khách (chi tiết/tìm: công khai) |
| MyBookingsScreen | `lib/screens/customer/my_bookings_screen.dart` | Khách (chi tiết/tìm: công khai) |
| RoomDetailScreen | `lib/screens/customer/room_detail_screen.dart` | Khách (chi tiết/tìm: công khai) |
| SearchScreen | `lib/screens/customer/search_screen.dart` | Khách (chi tiết/tìm: công khai) |
| ChangePasswordScreen | `lib/screens/shared/change_password_screen.dart` | Đã đăng nhập; hồ sơ có trạng thái khách |
| LinkedAccountsScreen | `lib/screens/shared/linked_accounts_screen.dart` | Đã đăng nhập; hồ sơ có trạng thái khách |
| NotificationSettingsScreen | `lib/screens/shared/notification_settings_screen.dart` | Đã đăng nhập; hồ sơ có trạng thái khách |
| NotificationsScreen | `lib/screens/shared/notifications_screen.dart` | Đã đăng nhập; hồ sơ có trạng thái khách |
| ProfileScreen | `lib/screens/shared/profile_screen.dart` | Đã đăng nhập; hồ sơ có trạng thái khách |
| StaffBookingListScreen | `lib/screens/staff/booking_list_screen.dart` | Lễ tân/Admin |
| PaymentsScreen | `lib/screens/staff/payments_screen.dart` | Lễ tân/Admin |
| RoomStatusScreen | `lib/screens/staff/room_status_screen.dart` | Lễ tân/Admin |

| Điểm vào | Trang / API |
| --- | --- |
| /login, /register | LoginScreen/RegisterScreen — POST /auth/login, /auth/register, /auth/google, /auth/facebook |
| Tab khách Trang chủ/Tìm phòng | HomeScreen/SearchScreen — GET /room-types, /rooms/available |
| Kết quả → phòng | RoomDetailScreen(room,start,end,guests) — GET /rooms/{id} |
| Tiếp tục → xem lại | BookingReviewScreen(room,start,end,guests) — POST /rooms/{id}/quote, /bookings |
| Commit tạo → thành công | BookingSuccessScreen(booking) — dùng kết quả commit |
| Tab đặt phòng → chi tiết | MyBookingsScreen/StaffBookingListScreen → BookingDetailScreen(id) — /bookings/my hoặc /staff/bookings, /bookings/{id}, cancel/confirm/reject |
| Chi tiết → thu/hoàn | PaymentsScreen(bookingId) — /staff/bookings/{id}/payments, /admin/payments/{id}/refunds |
| Tab staff tình trạng; drawer admin tình trạng | RoomStatusScreen — /staff/rooms/status, /staff/rooms/{id}/operational-status |
| Tab admin Tổng quan/Báo cáo | DashboardScreen/RevenueReportScreen — /admin/reports/revenue, export |
| Drawer /admin/accounts → thêm/chi tiết | AccountsScreen → AccountDetailScreen(id nullable) — /admin/accounts, role/status |
| Drawer /admin/room-types | RoomTypesScreen — /staff/room-types |
| Drawer /admin/rooms | RoomsScreen — /staff/rooms |
| Drawer /admin/amenities | AmenitiesScreen — /staff/amenities |
| Drawer /admin/closures | RoomClosuresScreen — /staff/room-closures |
| Loại phòng → ảnh/tiện nghi | RoomImagesScreen(typeId) — /staff/room-types/{id}/images và amenities |
| Tab /profile | ProfileScreen — GET/PATCH /users/me |
| Hồ sơ → đổi mật khẩu/liên kết | ChangePasswordScreen/LinkedAccountsScreen — /users/me/change-password, /users/me/identities |
| Chuông /notifications | NotificationsScreen — /notifications, unread-count, read/read-all; chọn bản ghi → BookingDetailScreen |
| Hồ sơ /notification-settings | NotificationSettingsScreen — cài đặt thiết bị và đồng bộ nhắc từ /bookings/my |

Quyền thực thi tại backend; route không phải biện pháp phân quyền. Khách chưa đăng nhập được tìm; đăng nhập trong chi tiết giữ nguyên phòng/ngày. SearchCriteria Provider toàn ứng dụng giữ ngày/khách/loại/giá qua đăng nhập. Form CRUD lớn được tái sử dụng ở widgets/catalog_*; mỗi trang quản lý vẫn có wrapper Screen riêng.

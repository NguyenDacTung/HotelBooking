# Đặc tả nâng cấp ứng dụng khách sạn TTTP dành cho Codex

Phiên bản bổ sung ngày 17/10/2026. Ngôn ngữ giao diện và trao đổi: tiếng Việt.

## 1. Yêu cầu thực hiện và thứ tự ưu tiên

Hãy trực tiếp nâng cấp dự án đặt phòng Flutter và backend Python/FastAPI hiện có thành ứng dụng khách sạn TTTP theo tài liệu này. Không tạo một dự án khác, không thay bằng ứng dụng web, không chỉ trả kế hoạch hoặc mockup. Trước khi sửa, đọc AGENTS.md có áp dụng, README, đặc tả gốc DAC_TA_CODEX_HOTEL_BOOKING.md nếu có và kiểm tra code/migration thực tế.

Tài liệu này bổ sung và thay thế các phần xung đột của đặc tả gốc, cụ thể cho phép thêm: giao diện chuyên nghiệp, tách màn hình, admin quản lý tài khoản/quyền, thu tiền thủ công để có báo cáo thực thu, đăng nhập Google/Facebook, thông báo và thư viện phù hợp. Những quy tắc chống trùng, giá chốt và bảo vệ dữ liệu không bị loại bỏ. Chỉ dẫn mới hơn của người dùng có ưu tiên cao nhất.

Các quyết định đã chốt:

- Tên hiển thị khách sạn và ứng dụng: TTTP; tiêu đề trang có thể dùng Khách sạn TTTP.
- Công nghệ giữ Flutter/Dart, Provider, http, FastAPI, SQLAlchemy, Alembic và PostgreSQL. Máy người dùng đang dùng PostgreSQL 18, không ép cài lại 17.
- Database phát triển hotel_booking; test riêng hotel_booking_test. Không reset/drop/truncate database phát triển hoặc tự đổi tên DB.
- Workspace có thể đang đặt Flutter ngay ở thư mục gốc, backend/ nằm bên trong. Giữ cách bố trí thực tế; không chuyển tất cả vào mobile/ chỉ để giống sơ đồ trong tài liệu cũ.
- Dự án có thể đang có lib/screens/auth/account.dart, customer/home.dart, room_detail.dart, bookings.dart, staff/management.dart và demo.dart. Kiểm tra thực tế rồi refactor có bảo toàn hành vi.
- Mã nguồn hiện có, DB đã migration và tài khoản đã tạo phải được giữ. Migration bổ sung, không sửa lịch sử migration đã áp dụng để né xung đột.
- Không tự mua dịch vụ, tạo ứng dụng Google/Meta bên ngoài hoặc công bố app. Chuẩn bị code và tài liệu cấu hình, yêu cầu người dùng cung cấp phần cấu hình ngoài còn thiếu khi thật sự cần.

Có thể tự quyết định chi tiết kỹ thuật nhỏ trong phạm vi. Không liên tục xin xác nhận lại yêu cầu đã chốt. Tạo kết quả chạy được, kiểm tra theo từng mốc. Khi thiếu OAuth credentials, vẫn hoàn thành UI/backend và các phần khác; không giả đăng nhập thành công.

## 2. Mục tiêu nâng cấp

1. Tách mỗi trang điều hướng chính thành file riêng, widget/service tái sử dụng nằm riêng.
2. Làm lại trải nghiệm TTTP có theme, hình nền, ảnh phòng, AppBar, điều hướng, bộ lọc, thông báo và bố cục nhất quán.
3. Luồng đặt phòng bắt đầu bằng chọn ngày nhận, ngày trả và số khách; giữ bộ lọc xuyên suốt các trang.
4. Tạo sẵn tài khoản admin và nhân viên trong môi trường phát triển bằng seed an toàn.
5. Admin có dashboard, báo cáo doanh thu có biểu đồ và xuất CSV/PDF, quản lý tài khoản và phân quyền.
6. Nhân viên theo dõi/yêu cầu đặt phòng, đổi tình trạng vận hành của phòng trong quyền cho phép, ghi nhận thu tiền thủ công.
7. Đăng nhập email/mật khẩu vẫn hoạt động; bổ sung Google và Facebook qua backend xác minh thật.
8. Tích hợp các thư viện có mục đích cụ thể theo các nhóm học phần người dùng liệt kê; không cài tất cả để tăng số lượng package.

Đây là ứng dụng một khách sạn, một phiếu một phòng. Chưa thêm đặt nhiều khách sạn, OTA, thanh toán trực tuyến, quản lý thuế/hóa đơn pháp lý, giá theo mùa, AI, camera quét giấy tờ hoặc gọi điện/voice trong app.

## 3. Tách màn hình và tổ chức mã

Mỗi route/page chính có một class Screen và một file snake_case riêng. File có thể chứa State tương ứng và widget nhỏ cục bộ; widget lớn dùng chung phải tách. Không chia màn hình theo số dòng tùy tiện. Dialog/form tái sử dụng không bắt buộc biến thành route. Không gom đăng nhập, hồ sơ và đăng ký vào một file account.dart lớn.

Cấu trúc gợi ý, điều chỉnh theo dự án hiện hữu:

```text
lib/
  app/                  # app.dart, app_router.dart, app_theme.dart
  core/                 # configuration, formatters, errors, constants
  models/               # response model và request DTO
  providers/            # session, search, bookings, notifications, admin
  services/             # API, token, social login, notifications, export
  repositories/
  screens/
    auth/               # login_screen.dart, register_screen.dart
    customer/           # home, search, room_detail, booking_review,
                        # booking_success, my_bookings, booking_detail
    shared/             # profile, notifications, notification_settings
    staff/              # booking_list, room_status
    admin/              # dashboard, room_types, rooms, amenities,
                        # room_images, room_closures, accounts, account_detail,
                        # revenue_report
  widgets/              # app_scaffold, room_card, price, state_view,
                        # date_range_field, filter_bar, status_chip
assets/
  images/               # ảnh nền/auth, banner TTTP, placeholder
  fonts/                # font có license phù hợp
```

Chi tiết đặt phòng dùng chung theo quyền; không sao chép hai màn hình gần giống rồi để logic khác nhau. Form thêm/sửa loại/phòng/tài khoản có thể là dialog hoặc trang riêng tùy kích thước. Màn hình thông báo dùng chung theo tài khoản. Cập nhật tất cả import/route/test khi di chuyển file.

Sau refactor tạo docs/screens.md liệt kê đúng route, class, file, quyền, dữ liệu/API và trạng thái triển khai. Đếm màn hình theo route độc lập, không đếm số file, tab, dialog hoặc class widget. Số màn hình không phải chỉ tiêu; không ép giữ con số 15–16 từng ước lượng trước đây.

## 4. Thương hiệu và hệ thống thiết kế TTTP

### 4.1. Theme thống nhất

Phong cách khách sạn hiện đại, trang nhã. Theme sáng là mặc định:

| Token | Giá trị thiết kế |
| --- | --- |
| Primary | #123A52, xanh đậm |
| Secondary | #B58A45, màu vàng đồng |
| Background | #F5F7FA |
| Surface | #FFFFFF |
| Text chính | #152536 |
| Text phụ | #5C6875 |
| Success | #237A57 |
| Error | #B42318 |

Kiểm tra tương phản thực tế, không dùng chữ trắng nhỏ trên nền vàng nếu khó đọc. Định nghĩa ColorScheme/ThemeData tập trung; không rải mã màu, bo góc và TextStyle khắp màn hình. Khoảng cách theo nhịp 4/8/12/16/24/32, padding trang khoảng 16, card bo 12–16. Nút chạm tối thiểu khoảng 48 logical pixels. Font tiếng Việt rõ nét, ưu tiên font hệ thống hoặc font bundle có license. Không phụ thuộc tải font từ mạng để app mới mở không mất kiểu chữ.

### 4.2. Hình nền và ảnh

- Đăng nhập/đăng ký: ảnh khách sạn toàn khung, overlay tối vừa đủ, logo chữ TTTP và form trên surface dễ đọc.
- Trang chủ: banner khách sạn/phòng bằng carousel, ảnh đúng tỷ lệ và BoxFit.cover; chữ không bị cắt hoặc lẫn nền.
- Các trang danh sách/biểu mẫu: nền nhẹ, không đặt ảnh toàn trang gây khó đọc bảng và input.
- Sử dụng ảnh asset hoặc nguồn có quyền sử dụng, ghi nguồn/license ở docs/assets.md; không phụ thuộc URL tạm hết hạn.
- Ảnh phòng từ API dùng cache, placeholder và error state. Hình ảnh không thay thế dữ liệu giá hoặc tiện nghi thật.
- Địa chỉ, hotline và vị trí TTTP chưa được người dùng cung cấp: để cấu hình và ẩn action chưa cấu hình, không bịa thông tin khách sạn.

### 4.3. Thanh công cụ và điều hướng

- Khách: NavigationBar gồm Trang chủ, Tìm phòng, Đặt phòng của tôi, Tài khoản. Icon chuông trên AppBar có badge số chưa đọc; tránh thêm tab thứ năm nếu chật.
- Nhân viên: Yêu cầu đặt phòng, Tình trạng phòng, Tài khoản; chuông trên AppBar.
- Admin: Tổng quan, Đặt phòng, Báo cáo, Tài khoản; mục Quản trị trên drawer hoặc menu dẫn tới phòng, loại phòng, tiện nghi, ảnh, lịch tạm ngừng và quản lý tài khoản. Phân biệt tab Tài khoản cá nhân với mục Quản lý tài khoản.
- AppBar: tiêu đề đúng ngữ cảnh, back ở trang con, action tìm/lọc/làm mới khi có ích. Drawer dùng cho mục quản trị ít truy cập, không nhét tất cả vào bottom navigation.
- Chip trạng thái kèm chữ, không chỉ màu. Bộ lọc hiện lựa chọn và có Xóa bộ lọc. Danh sách hỗ trợ refresh và phân trang.
- Chỉ hiển thị FAB khi có tác vụ thêm mới phù hợp quyền. SnackBar hoặc toast cho phản hồi ngắn; dialog cho xác nhận thao tác quan trọng.
- Responsive: điện thoại trước, không tràn ở màn 360px hoặc khi tăng cỡ chữ; bảng rộng admin đổi thành card hoặc cuộn ngang rõ ràng. Giữ trạng thái tab khi chuyển.

Dùng Scaffold, AppBar, NavigationBar/BottomNavigationBar, Drawer, TabBar khi cần, Form, TextFormField, ListView/GridView, Card, Dialog, BottomSheet và Provider để thể hiện kiến thức học phần có mục đích. Không thêm một thanh công cụ chỉ để đủ tên widget.

## 5. Ngôn ngữ giao diện chuyên nghiệp

Tách nội dung UI thành constants/localization tập trung. Các mã như CHO_XAC_NHAN vẫn giữ ở dữ liệu, không hiện nguyên mã cho khách.

| Nội dung cũ hoặc kỹ thuật | Nội dung khách nhìn thấy |
| --- | --- |
| Xác nhận gửi phiếu | Xác nhận đặt phòng |
| Gửi phiếu | Đặt phòng |
| Phiếu của tôi | Đặt phòng của tôi |
| CHO_XAC_NHAN | Chờ xác nhận |
| DA_XAC_NHAN | Đã xác nhận |
| DA_TU_CHOI | Đã từ chối |
| DA_HUY | Đã hủy |
| Không có data | Chưa có đặt phòng nào |
| API error | Không thể tải dữ liệu. Vui lòng thử lại. |
| Hủy phiếu | Hủy đặt phòng |
| Mã PDP | Mã đặt phòng |
| CRUD phòng | Quản lý phòng |

Tạo thành công: “Yêu cầu đặt phòng đã được gửi. TTTP sẽ kiểm tra và xác nhận.” Không ghi “Phòng của bạn đã được xác nhận” khi server mới trả CHO_XAC_NHAN. Trùng lịch: “Phòng không còn trống trong thời gian đã chọn. Vui lòng chọn phòng hoặc ngày khác.”

Admin/nhân viên dùng “Xác nhận đặt phòng”, “Từ chối yêu cầu”, “Lý do từ chối”, “Ghi nhận thanh toán”, “Tạm ngừng kinh doanh”. Không gọi ghi nhận thu tiền là thanh toán online. Hiển thị VND hoặc đ nhất quán, đơn vị /đêm, tổng số đêm, ngày dd/MM/yyyy và các khoản thực tế có trong hệ thống. Không tạo giảm giá/thuế/phụ thu giả.

## 6. Luồng đặt phòng phải sửa hoàn chỉnh

### 6.1. Chọn ngày trước khi tìm

Trang chủ có thẻ tìm phòng nổi bật với Ngày nhận phòng, Ngày trả phòng, Số khách và nút Tìm phòng. Dùng date-range picker hoặc package lịch phù hợp, mặc định hôm nay → ngày mai theo giờ Việt Nam. Khách phải nhìn thấy và có thể đổi ngày; không âm thầm dùng ngày hardcode.

Kiểm tra ngày nhận >= hôm nay, ngày trả > ngày nhận, 1–30 đêm, số khách >= 1. Tìm kiếm chỉ gọi API sau khi đầu vào hợp lệ. Giữ SearchCriteria trong Provider với ngày/khách/loại/giá; serialize DATE dạng YYYY-MM-DD, không đổi múi giờ gây lệch ngày.

### 6.2. Kết quả và chi tiết

Kết quả hiển thị khoảng ngày đang chọn, số đêm và số khách trong thanh tóm tắt có nút Chỉnh sửa. Card phòng gồm ảnh, loại, số phòng vật lý, sức chứa, vài tiện nghi, đơn giá mỗi đêm và tổng dự kiến theo kỳ. Không hiển thị phòng thiếu sức chứa hoặc không khả dụng như phòng đặt được.

Chi tiết phòng nhận nguyên SearchCriteria từ kết quả. Có gallery/phóng ảnh, tiện nghi, sức chứa, chính sách, date summary và bottom action tổng giá + Tiếp tục đặt phòng. Nếu vào chi tiết trực tiếp từ banner mà chưa có ngày hợp lệ, yêu cầu chọn ngày và kiểm tra khả dụng trước khi tiếp tục.

### 6.3. Đăng nhập, xem lại và tạo đơn

Khách chưa đăng nhập được xem/tìm, nhưng khi đặt phải đăng nhập; sau đăng nhập quay về đúng phòng/ngày đã chọn. Nhân viên/admin không đặt như khách trong bản này; không tự tạo hồ sơ khách thứ hai cho cùng tài khoản.

Trang Xác nhận đặt phòng gồm phòng và ảnh nhỏ; ngày nhận/trả; số đêm; số khách; tên/điện thoại liên hệ; ghi chú tùy chọn; giá mỗi đêm và tổng; chính sách hủy; nút Xác nhận đặt phòng. Báo giá lại bằng API khi vào trang và sau thay đổi ngày. Ngày/khách thay đổi phải kiểm tra khả dụng lại; không giữ nguyên quote cũ.

Server vẫn kiểm tra toàn bộ và chốt giá trong transaction. Nếu giá quote đã thay đổi, API trả 409 PRICE_CHANGED kèm báo giá mới trước khi tạo đơn; client hiển thị giá mới và yêu cầu khách xác nhận lại. Có thể thêm expected_don_gia_moi_dem vào request như điều kiện so sánh, KHÔNG coi đó là giá tin cậy. Backend lấy giá thật và từ chối khi không bằng điều kiện người dùng đã xác nhận.

Với ứng dụng đang có endpoint tạo đơn không có expected price, cập nhật cả frontend/backend/tests và docs cùng lúc; không làm hỏng request cũ âm thầm. Đây là bổ sung hợp đồng so với đặc tả cũ.

Nút gửi loading, chống bấm lặp; không tự retry POST khi timeout. Nếu kết quả chưa rõ, cho kiểm tra Đặt phòng của tôi. Nếu triển khai idempotency, dùng khóa mỗi ý định đặt, lưu server và kiểm tra payload; không chỉ disable button rồi tuyên bố idempotent.

### 6.4. Kết quả và lịch sử

Trang kết quả hiển thị mã đặt phòng, trạng thái Chờ xác nhận, phòng/ngày/giá chốt; action Xem chi tiết và Về trang chủ. Chỉ hiện sau commit thành công.

Đặt phòng của tôi có tab/chip Tất cả, Chờ xác nhận, Đã xác nhận, Đã hủy, Đã từ chối. Chi tiết có timeline lịch sử, lý do từ chối/hủy và nút hủy khi được phép. Hạn hủy hiện tại giữ trước 00:00 ngày nhận giờ Việt Nam. Giữ exclusion constraint và transaction khóa phòng chống trùng.

## 7. Admin, nhân viên và tài khoản tạo sẵn

### 7.1. Ánh xạ quyền không phá dữ liệu cũ

UI gọi vai trò cao nhất là Admin hoặc Quản trị viên. Nếu DB hiện dùng NHAN_VIEN + CHUC_VU.ma_quyen=QUAN_LY, giữ ánh xạ đó làm ADMIN, không thêm loại hồ sơ mới gây phá constraint. STAFF tương ứng LE_TAN. CUSTOMER tương ứng KHACH_HANG. Một tài khoản vẫn có đúng một nhóm hồ sơ.

Bổ sung permission cụ thể tại backend thay vì chỉ so chuỗi trên UI. Phải có ma trận quyền/test; không cho client tự gửi role để nâng quyền.

### 7.2. Tạo tài khoản demo thật

Tạo CLI/seed idempotent cho môi trường phát triển:

| Tài khoản đề xuất | Email đăng nhập | Quyền |
| --- | --- | --- |
| Quản trị TTTP | admin@tttp.test | ADMIN, ánh xạ QUAN_LY |
| Nhân viên TTTP | staff@tttp.test | STAFF, ánh xạ LE_TAN |
| Khách demo nếu cần | customer@tttp.test | CUSTOMER |

Mật khẩu lấy từ env TTTP_ADMIN_PASSWORD, TTTP_STAFF_PASSWORD và TTTP_CUSTOMER_PASSWORD hoặc nhập an toàn ở terminal; không hardcode vào app/repo, không in mật khẩu ra log/chat. Sinh hash Argon2 bằng service hiện có. Có thể sinh ngẫu nhiên và ghi file credentials cục bộ bị gitignore, chỉ khi người dùng chọn cách đó; mặc định dùng env.

Nếu tài khoản đã tồn tại, seed không tự reset mật khẩu hay nâng quyền tài khoản lạ. Kiểm tra đúng email/loại hồ sơ, báo xung đột rõ ràng. Email .test chỉ dùng demo, không coi là email nhận thư thật. Không tự tạo tài khoản mặc định khi app production khởi động.

### 7.3. Quản lý tài khoản dành cho admin

Trang danh sách: tìm theo tên/email, lọc vai trò/trạng thái, phân trang. Thông tin gồm tên, email nếu có, vai trò, hoạt động, cách đăng nhập, ngày tạo. Không trả hash hoặc token provider.

Trang chi tiết/form: sửa tên/điện thoại, tạo tài khoản nhân viên/admin, khóa/mở khóa, đổi quyền STAFF ↔ ADMIN, xem lịch sử phân quyền. Không tự chuyển CUSTOMER ↔ NHAN_VIEN trong bản này vì có FK lịch sử/hồ sơ; UI nêu đúng phạm vi. Tài khoản khách có thể khóa/mở và sửa thông tin được phép, không có chọn nâng thành admin trực tiếp. Nếu cần nhân viên từ một khách, dùng tài khoản nội bộ khác thay vì xóa hồ sơ khách cũ.

Không cho admin tự khóa hoặc tự hạ quyền; không cho hạ/khóa admin hoạt động cuối cùng. Các thao tác cạnh tranh thay đổi admin phải tuần tự hóa trong transaction để không hai request cùng loại bỏ hai admin cuối. Ghi audit ai làm, trước/sau, lý do và thời điểm.

Không có xem mật khẩu. Reset mật khẩu nội bộ nếu triển khai: admin nhập mật khẩu tạm, tài khoản bị đánh dấu cần đổi mật khẩu lần đầu; endpoint đổi mật khẩu an toàn, không trả mật khẩu cũ. Không giả vờ gửi email khôi phục khi chưa có dịch vụ gửi thư.

Kiểm tra trạng thái/quyền hiện hành mỗi request; thêm token_version hoặc cơ chế tương đương để đổi mật khẩu/khóa/đổi quyền vô hiệu phiên cũ theo chính sách. Cập nhật JWT/Flutter xử lý 401 và 403 đúng.

## 8. Nhân viên thay đổi tình trạng phòng

Phân biệt ba khái niệm rõ ràng:

1. Trạng thái đặt phòng: Chờ xác nhận/Đã xác nhận/Đã hủy/Đã từ chối.
2. Khả dụng theo khoảng ngày: tính từ lịch đặt, kỳ tạm ngừng và điều kiện kinh doanh.
3. Tình trạng vận hành phòng: SAN_SANG, CAN_DON_DEP, DANG_DON_DEP, BAO_TRI.

Bổ sung tinh_trang_van_hanh vào PHONG, mặc định SAN_SANG. Không gọi Đã đặt/Trống là trạng thái có thể sửa tay để bỏ qua lịch. Không tự thêm trạng thái Đang có khách vì bản này chưa có check-in/out.

Nhân viên được chuyển SAN_SANG → CAN_DON_DEP, CAN_DON_DEP → DANG_DON_DEP, DANG_DON_DEP → SAN_SANG và đánh dấu BAO_TRI có lý do. Admin được sửa theo cùng service. Không cho STAFF đổi giá, số phòng, loại phòng, quyền hoặc cờ kinh doanh tùy ý.

CAN_DON_DEP/DANG_DON_DEP chỉ phản ánh vệ sinh, không tự chiếm mọi ngày tương lai; cảnh báo trên màn nhân viên, không tự hủy đơn. BAO_TRI bắt buộc có khoảng ngày cụ thể, tạo PHONG_TAM_NGUNG trong cùng transaction và kiểm tra xung đột phiếu. Nếu có đơn giao kỳ, từ chối lịch bảo trì và thông báo cần admin xử lý đơn theo chính sách, không lặng lẽ bỏ qua đặt phòng.

Kết thúc bảo trì: dừng hiệu lực kỳ ngừng tương ứng và cập nhật tình trạng có log. Nếu còn kỳ ngừng khác hiệu lực thì vẫn áp dụng chúng khi tìm phòng. Tình trạng BAO_TRI hiện tại không làm phòng bị ẩn vĩnh viễn ngoài khoảng ngừng; lịch ngày vẫn là nguồn tính khả dụng. Có thể tính trạng thái bảo trì hiện tại từ kỳ ngừng đang bao phủ hôm nay để tránh cột bị lệch.

Trang Tình trạng phòng: lọc tầng/loại/tình trạng, thẻ số phòng có chip, action đổi trạng thái có xác nhận/lý do; hiển thị lịch sắp tới và kỳ ngừng. Ghi PHONG_LICH_SU hoặc audit thống nhất, không nhầm với LICH_SU_DAT_PHONG.

## 9. Báo cáo doanh thu có ý nghĩa và xuất file

### 9.1. Phân biệt giá trị đặt và tiền đã thu

Không gọi tổng tiền phiếu đã xác nhận là doanh thu thực thu. Chưa có cổng thanh toán online, nên bổ sung sổ ghi nhận thu tiền thủ công để báo cáo có dữ liệu thật trong phạm vi đồ án.

Trang admin có các chỉ số riêng:

- Giá trị đặt phòng: tổng giá chốt của đơn theo tiêu chí/trạng thái ghi rõ.
- Thực thu trong kỳ: tổng khoản thu hợp lệ trừ hoàn tiền theo ngày giao dịch.
- Số đặt phòng: theo ngày tạo đơn, có phân chia trạng thái.
- Số tiền còn phải thu: các đơn đã xác nhận được chọn, max(tổng giá - thu ròng, 0); không trộn kỳ tạo đơn và kỳ giao dịch mà không giải thích.

“Doanh thu” trong tiêu đề được mô tả là báo cáo thực thu, không tuyên bố chuẩn kế toán hoặc doanh thu đã ghi nhận theo kỳ lưu trú. Bản này không tích hợp Momo/VNPAY và không phát hành hóa đơn pháp lý.

### 9.2. Sổ thu tiền

Thêm bảng giao_dich_thanh_toan: id UUID, ma_pdp FK, loai THU/HOAN, so_tien NUMERIC(14,0)>0, phuong_thuc TIEN_MAT/CHUYEN_KHOAN, thoi_diem_giao_dich TIMESTAMPTZ, nguoi_ghi_nhan FK tài khoản nhân viên, ghi_chu, ma_tham_chieu tùy chọn, ngay_tao; giao dịch hoàn tham chiếu giao dịch thu gốc. Lưu người thao tác và căn cứ, không tin id người thực hiện từ client.

Nhân viên/admin ghi nhận thu trên đơn DA_XAC_NHAN, có form số tiền/phương thức/tham chiếu và xác nhận đã nhận tiền. Đơn chờ hoặc bị từ chối không được thu. Không thu vượt tổng phiếu; tổng hoàn không vượt số đã thu. Khóa phiếu và các dòng cần thiết trong transaction để chống hai lần thu cùng vượt mức. Chỉ admin được hoàn, có lý do. Không sửa/xóa cứng giao dịch đã ghi; sửa sai bằng bút toán hoàn/điều chỉnh có liên kết rõ.

Nếu khách hủy đơn có tiền đã thu, trạng thái đơn vẫn được xử lý theo hạn hủy, đồng thời hiện Cần hoàn tiền; không tự giả đã hoàn. Admin ghi nhận hoàn sau khi thực sự xử lý bên ngoài. Báo cáo vẫn giữ tiền thu đến khi có giao dịch hoàn, hiển thị khoản cần hoàn riêng.

Thêm request_id UNIQUE cho lệnh ghi nhận thu/hoàn để gửi lại cùng request không tạo giao dịch hai lần. Kiểm tra cùng request_id nhưng payload khác trả 409.

### 9.3. Dashboard và biểu đồ

Trang báo cáo riêng chỉ ADMIN:

- Bộ chọn khoảng ngày, preset 7 ngày/30 ngày/tháng này, chế độ ngày/tháng.
- Biểu đồ đường hoặc cột Thu, Hoàn, Thu ròng theo kỳ; trục và tooltip VND rõ ràng.
- Biểu đồ số đặt theo trạng thái; biểu đồ giá trị hoặc thực thu theo loại phòng nếu có dữ liệu phù hợp.
- KPI card, bảng chi tiết có phân trang, số tổng; empty/loading/error rõ ràng.
- Thời gian lọc theo giờ Việt Nam. Người dùng chọn từ-ngày/đến-ngày bao gồm hai ngày; backend đổi thành [00:00 ngày đầu, 00:00 ngày sau ngày cuối) rồi chuyển UTC. Không dùng <=23:59:59 gây mất mili giây.
- Series phải có cả ngày không có giao dịch với giá trị 0. Backend tổng hợp, không tải toàn DB về Flutter rồi tính.
- Không làm công suất phòng theo check-in khi chưa có dữ liệu; nếu thêm tỷ lệ đêm phòng đã đặt phải ghi đúng tên và mẫu số có loại kỳ ngừng.

### 9.4. Xuất báo cáo

Bắt buộc CSV và PDF. Có thể bổ sung XLSX sau khi hai định dạng này chạy đúng, không giả file .xlsx bằng CSV đổi đuôi.

Backend cung cấp report JSON và endpoint export cùng filter, quyền ADMIN. Báo cáo export có tên TTTP, thời điểm xuất, kỳ báo cáo/múi giờ, định nghĩa chỉ số, tổng, bảng và biểu đồ trong PDF. PDF có font hỗ trợ tiếng Việt; kiểm tra dấu và ngắt trang. CSV UTF-8 có BOM để Excel mở tiếng Việt, tên cột rõ, phòng chống formula injection cho trường văn bản bắt đầu bằng =,+,-,@.

Chỉ xuất trường cần cho báo cáo, không kèm hash/token/email hàng loạt không cần thiết. PDF và CSV phải đối chiếu cùng tổng trên dashboard. Backend trả Content-Type/Content-Disposition đúng, giới hạn kỳ xuất hợp lý (ví dụ tối đa 366 ngày) và có lỗi rõ ràng. Flutter tải rồi lưu/chia sẻ qua cơ chế hệ thống; không yêu cầu quyền quản lý toàn bộ bộ nhớ Android.

Có thể dùng reportlab/matplotlib backend cho PDF và csv của Python. Đây là lựa chọn triển khai được phép, pin dependency tương thích và kiểm thử xuất thật.

## 10. Đăng nhập Google và Facebook

### 10.1. Nguyên tắc

“Đăng nhập bằng Gmail” hiển thị chính xác là Tiếp tục với Google. Gmail không phải một giao thức đăng nhập riêng. Bổ sung Tiếp tục với Facebook. Email/mật khẩu vẫn là đường đăng nhập sẵn sàng dùng.

Dùng google_sign_in và flutter_facebook_auth hoặc SDK hiện được tài liệu chính thức hỗ trợ, kết nối backend FastAPI riêng; không chuyển database/auth sang Firebase chỉ vì thêm Google login. Đọc API hiện tại của package tại thời điểm code, không chép API cũ từ trí nhớ.

Flutter lấy credential từ provider rồi gửi backend. Backend xác minh token với Google/Meta bằng phương thức được provider hướng dẫn, kiểm tra issuer/audience/app ID, thời hạn và subject; không tin email/user_id do Flutter tự gửi. Với Google ưu tiên ID token có audience cấu hình cho backend; server auth code nếu SDK/luồng cần, trao đổi ở backend. Với Facebook dùng xác minh access token/app binding phù hợp. Không trộn token của provider với JWT TTTP.

Sau xác minh, backend cấp JWT TTTP và GET /users/me như đăng nhập thường. Tài khoản social tạo mới chỉ là CUSTOMER. Không tự tạo admin bằng email trùng tên.

### 10.2. Dữ liệu và liên kết tài khoản

Thêm danh_tinh_dang_nhap: id, tai_khoan_id FK, provider GOOGLE/FACEBOOK, provider_subject, ngay_tao; UNIQUE(provider, provider_subject). Không dùng email làm khóa định danh social duy nhất. Không lưu access token provider lâu dài nếu không cần chức năng khác.

Social-only không có mật khẩu: migration cho mat_khau_bam nullable, password login từ chối đúng cách khi không có hash. Email provider có thể thiếu/chưa xác minh; cho email nullable qua migration có kiểm tra nhất quán và dùng provider_subject làm định danh; không tạo email giả, không đăng nhập bằng email chưa xác minh. Nếu nghiệp vụ cần email liên hệ, cho bổ sung sau bằng luồng có xác minh, không chặn giả tạo hoặc chiếm email người khác.

Không tự liên kết vào tài khoản email/password có sẵn chỉ vì cùng email. Yêu cầu đăng nhập tài khoản hiện có và xác nhận liên kết provider; chống account takeover. Không cho unlink phương thức cuối cùng khiến người dùng không còn cách đăng nhập. Tài khoản admin/nhân viên chỉ liên kết provider từ phiên nội bộ đã xác thực, không tự cấp quyền theo email Google/Meta.

### 10.3. Cấu hình bên ngoài và tiêu chí hoàn thành

Tạo docs/social_login_setup.md ghi Android applicationId, SHA debug/release, Google OAuth client/server client ID, consent/testing users; Facebook app ID/client token/key hash/redirect và chế độ test theo tài liệu phiên bản đang dùng. App secret chỉ ở backend. Không đưa secret vào Flutter hoặc Git.

Config thiếu thì hiện trạng thái “Chưa cấu hình”/ẩn provider theo feature flag; không làm ứng dụng crash từ plugin Facebook khởi tạo khi thiếu metadata. Không làm nút đăng nhập trả tài khoản demo. Báo rõ nhà cung cấp nào đã E2E thật, nhà cung cấp nào chờ cấu hình. Chuẩn bị toàn bộ mã tích hợp và test xác minh giả lập có kiểm soát; test mock không thay thế E2E provider thật.

## 11. Thông báo và quyền Android

Phân biệt:

- SnackBar/toast: phản hồi thao tác lúc đang dùng app.
- Trung tâm thông báo: bản ghi trên backend, có đã đọc/chưa đọc theo tài khoản.
- Local notification: do thiết bị lên lịch hoặc hiển thị sau khi nhận dữ liệu, không tự nghe database khi app bị đóng.
- Push notification: cần FCM hoặc OneSignal và kết nối mạng, backend gửi qua provider; không đồng nghĩa với local notification.

### 11.1. Bắt buộc làm trước

Thêm thong_bao: id, tai_khoan_id, loai_su_kien, tieu_de, noi_dung, ma_pdp nullable, ngay_tao, ngay_doc nullable, event_key UNIQUE theo người nhận/sự kiện. Sinh bản ghi cùng transaction tạo/chuyển trạng thái phiếu, không sinh khi rollback. Không để khách đọc thông báo người khác.

Sự kiện: khách gửi đơn (nhân viên có quyền nhận thông báo phù hợp), xác nhận/từ chối (khách nhận), khách hủy (nhân viên nhận). Nội dung trên notification lock screen tránh điện thoại/email hoặc chi tiết nhạy cảm. Mở thông báo điều hướng chi tiết và backend vẫn kiểm tra quyền.

API phân trang, đánh dấu đọc một/tất cả và unread count. Refresh khi mở app/quay lại tab, có thể polling khoảng 30–60 giây khi foreground; dừng polling khi background/logout. Badge theo server, chống tăng lặp từ mỗi lần refresh.

flutter_local_notifications dùng nhắc trước ngày nhận cho đơn đã xác nhận; dùng timezone đúng Asia/Ho_Chi_Minh, lịch tương lai hợp lệ. Hủy lịch khi đơn hủy/từ chối/logout/chuyển tài khoản. Khi giờ nhắc đã qua không tạo lịch quá khứ. Dùng lịch không chính xác tới từng phút nếu đủ cho đồ án, tránh xin exact alarm không cần thiết. Giải thích giới hạn nhắc cục bộ: nếu đơn bị hủy trên thiết bị khác khi app này không đồng bộ, lịch có thể chưa cập nhật.

Xin quyền thông báo theo phiên bản Android và package đã chọn vào thời điểm hợp lý; từ chối quyền vẫn dùng app bình thường. Không xin tất cả quyền khi mở ứng dụng lần đầu.

### 11.2. Push là mốc mở rộng có điều kiện

Chuẩn bị thêm Firebase Messaging nếu người dùng cung cấp dự án FCM, không dùng cả OneSignal và FCM cùng lúc. Firebase chỉ làm transport push; xác thực và DB vẫn FastAPI/PostgreSQL. Backend có bảng thiết bị/token theo tài khoản, xóa liên kết khi logout và xử lý token đổi/hết hiệu lực.

Để gửi đáng tin cậy, dùng outbox transaction và worker/lệnh dispatcher có retry/dedup, không gửi trước commit hoặc tuyên bố gửi thành công chỉ vì đã thêm background task. Nếu chưa có cấu hình dịch vụ, hoàn thành inbox/local notifications và ghi push đang chờ cấu hình; không hứa thông báo realtime khi app tắt bằng polling/local notification.

## 12. Chọn thư viện từ danh sách học phần

Đối chiếu theo DANH SÁCH người dùng cung cấp; không tuyên bố đã đọc toàn bộ slide nếu chưa mở chúng. Nếu slide có trong workspace, đọc phần liên quan và cập nhật docs/course_mapping.md gồm nhóm học, package chính xác, nơi dùng, lý do và trạng thái kiểm thử.

Trước khi cài, tra pub.dev/tài liệu tác giả, kiểm tra SDK/minSdk/compileSdk/Gradle/license và API hiện tại. Chọn phiên bản tương thích dự án, commit pubspec.lock. Không nâng đồng loạt Android SDK/Gradle nếu không có lý do và không kiểm tra lại build.

| Nhóm học phần | Dùng cho TTTP | Chưa cần hoặc không chọn trùng |
| --- | --- | --- |
| 1 Hiệu ứng | shimmer cho skeleton; flutter_animate cho chuyển nhẹ | EasyLoading chỉ thêm nếu có nhu cầu overlay chưa giải quyết; NavigationBar gốc thay Convex Bottom Bar mặc định; Live Activities không thuộc mục tiêu Android hiện tại |
| 2 Slider lịch | carousel_slider cho banner; date-range picker của Flutter cho ngày nhận/trả | Không cài thêm carousel_slider_plus cùng chức năng; Table Calendar/Calendar Date Picker chỉ khi date picker gốc không đáp ứng, xác minh đúng package; Easy Date Timeline không thay thế chọn khoảng nhiều đêm |
| 3 Ảnh | cached_network_image; image_picker cho admin; easy_image_viewer xem gallery | crop_your_image tùy chọn cắt ảnh trước upload; không thêm image editor đầy đủ nếu chỉ cần crop |
| 4 File | path_provider để file tạm và export; file_selector/file_picker chỉ khi cần chọn file | PDF viewer chọn một package cụ thể nếu cần preview; không cài Microsoft Viewer/PDF Viewer theo tên chung chưa xác định |
| 5 Hệ thống | connectivity_plus cho banner trạng thái mạng; url_launcher cho gọi hotline khi cấu hình | Có Wi-Fi không bảo đảm truy cập được API, vẫn bắt lỗi request; không dùng WebView thay UI native; device_info_plus và rung/âm thanh không bắt buộc |
| 6 Media | Chưa bắt buộc | Không thêm audio/video/record/callkit nếu không có nhu cầu đã chốt |
| 7 Thông báo | flutter_local_notifications; badges nếu badge Material chưa đủ; permission_handler khi cần quyền chưa được plugin xử lý | Chỉ chọn một thư viện local, không dùng thêm Awesome Notifications cùng lúc; toast_notification tùy chọn, không lặp toast và SnackBar cho cùng sự kiện |
| 8 Push thanh toán | firebase_messaging ở mốc push có cấu hình | Không dùng thêm OneSignal; Momo/VNPAY/In App Purchase chưa triển khai, chỉ ghi nhận thu tiền thủ công |
| 9 Bản đồ | url_launcher mở địa chỉ bản đồ khi TTTP cung cấp vị trí | Chưa xin GPS hay tích hợp Google Maps/OSM/Vietmap/Mapbox nếu chưa cần |
| 10 Camera mã | image_picker dùng ảnh phòng nếu cần | Chưa quét QR/barcode/ML Kit/document scanner |
| 11 Bảo mật | flutter_secure_storage cho JWT | Native Auth/local_auth, screen lock tùy chọn sau; không coi Flutter Protector là thay thế phân quyền backend; Feedback chỉ thêm nếu có quy trình nhận phản hồi |

Thêm ngoài danh sách có mục đích: fl_chart cho biểu đồ báo cáo, share_plus cho chia sẻ file; google_sign_in, flutter_facebook_auth cho social. Không khẳng định các package này được dạy trong slide nếu chỉ là lựa chọn bổ sung. Không dùng màu/ảnh để che thiếu API.

## 13. Dữ liệu và API nâng cấp

Không giữ yêu cầu “đúng 12 bảng” khi mở rộng tính năng. 12 bảng gốc được giữ và thêm các bảng cần thiết: danh_tinh_dang_nhap, thong_bao, giao_dich_thanh_toan, audit_log; thêm thiet_bi_thong_bao và outbox nếu bật push. Audit room/account có thể dùng một bảng audit_log với entity/action/actor/before/after đã lọc bí mật; không lưu hash, token hoặc password vào JSON audit.

Migration bổ sung token_version/đổi mật khẩu lần đầu nếu dùng, tình trạng vận hành phòng, quyền admin ánh xạ chức vụ. Với email/hash nullable vì social, cập nhật response/model/form/report xử lý NULL và constraint tài khoản local phải có email/hash phù hợp. Không xóa constraint đúng một hồ sơ theo loại.

API mới gợi ý, tên có thể điều chỉnh để thống nhất code nhưng phải cập nhật docs/frontend/tests cùng lúc:

| Method | Path | Quyền |
| --- | --- | --- |
| POST | /auth/google | Xác minh credential và cấp JWT khách |
| POST | /auth/facebook | Xác minh credential và cấp JWT khách |
| POST/DELETE | /users/me/identities/{provider} | Liên kết/hủy liên kết có xác thực |
| POST | /users/me/change-password | Đổi mật khẩu theo chính sách |
| GET | /admin/accounts | ADMIN |
| POST | /admin/accounts | ADMIN tạo nội bộ |
| GET/PATCH | /admin/accounts/{id} | ADMIN, whitelist trường |
| PATCH | /admin/accounts/{id}/role | ADMIN, STAFF/ADMIN và bảo vệ admin cuối |
| PATCH | /admin/accounts/{id}/status | ADMIN khóa/mở |
| GET | /staff/rooms/status | STAFF/ADMIN |
| PATCH | /staff/rooms/{id}/operational-status | STAFF/ADMIN, service có audit |
| POST | /staff/bookings/{id}/payments | STAFF/ADMIN thu tiền |
| POST | /admin/payments/{id}/refunds | ADMIN hoàn tiền |
| GET | /admin/reports/revenue | ADMIN, KPI và series |
| GET | /admin/reports/revenue/export | ADMIN, format csv/pdf và cùng filter |
| GET | /notifications | Chính tài khoản |
| GET | /notifications/unread-count | Chính tài khoản |
| PATCH | /notifications/{id}/read | Chính tài khoản |
| PATCH | /notifications/read-all | Chính tài khoản |
| POST/DELETE | /users/me/push-devices | Chính tài khoản, nếu bật push |

Định nghĩa route tĩnh như unread-count/read-all trước route động. Mọi list phân trang và sort ổn định. API nâng cấp vẫn dùng JSON và hệ mã lỗi thống nhất; file export dùng binary response đúng MIME. Giá trị tiền server tính, quyền server xác minh. Không trả cấu hình OAuth secrets, SQL, stack trace hoặc hash.

## 14. Kiểm thử và nghiệm thu

Giữ các test gốc về ngày, quyền, trạng thái, giá và concurrency. Bổ sung tối thiểu:

1. Refactor route không mất màn hình hoặc navigation; back và tab giữ state đúng.
2. Theme TTTP, chữ Việt, màn 360px, cỡ chữ lớn và bàn phím không overflow; ảnh lỗi có placeholder.
3. Chọn ngày từ home → kết quả → chi tiết → đăng nhập → review vẫn đúng ngày/số khách; thay ngày gọi lại availability/quote.
4. Giá đổi trước xác nhận trả PRICE_CHANGED, không tạo đơn với giá khách chưa chấp nhận; retry sau xác nhận giá mới hoạt động.
5. Hai người cùng đặt vẫn chỉ một thành công; hai thao tác bảo trì/đặt không tạo lịch chéo.
6. Seed admin/staff chạy hai lần không nhân đôi hoặc reset mật khẩu; đăng nhập ra đúng giao diện.
7. Khách/nhân viên không gọi được API admin; request chèn role bị chặn; đổi quyền có audit và token cũ bị xử lý đúng.
8. Không tự hạ/khóa và không bỏ admin cuối, gồm hai request cạnh tranh.
9. Nhân viên chỉ đổi trạng thái phòng được phép; bảo trì xung đột từ chối, không đổi giá/quyền.
10. Thu/hoàn không vượt giới hạn cả khi đồng thời; lặp request_id không tạo hai giao dịch; hủy đơn có tiền thu hiện cần hoàn và giữ sổ lịch sử.
11. Báo cáo kỳ/ngày Việt Nam đúng, ngày trống bằng 0, giá trị đặt khác thực thu, thu ròng = thu - hoàn; CSV/PDF và dashboard cùng tổng, PDF tiếng Việt/biểu đồ không lỗi.
12. Social token sai audience/expired/provider subject giả bị chặn; cùng email không tự chiếm tài khoản local; tài khoản không có email/hash không crash; thiếu cấu hình không crash SDK hoặc giả login.
13. Inbox chỉ đọc của mình, badge/read-all đúng, rollback không phát notification; refresh không tạo lặp.
14. Từ chối quyền thông báo vẫn dùng app; local reminder tạo/hủy đúng; tap notification xử lý login và kiểm tra quyền.
15. Nếu có push, test token đổi/logout, retry dedup và trường hợp app background; ghi rõ E2E nào cần cấu hình thật.
16. flutter analyze, Flutter test, backend tests và build Android phù hợp. Chạy database tests trên hotel_booking_test, không reset hotel_booking.

Thêm docs/acceptance_checklist.md và docs/course_mapping.md dựa trên code thực tế. Không đánh dấu hoàn thành những tính năng chỉ có giao diện hoặc đang chờ credentials. Screenshots nội bộ chỉ phục vụ QA; không chụp mật khẩu/tài khoản bí mật vào tài liệu.

## 15. Thứ tự triển khai để hạn chế lỗi

Mốc 1: kiểm tra code hiện có, lưu baseline, lập danh sách screen/API, tách màn hình và theme TTTP; bảo toàn DB và luồng hiện có.

Mốc 2: hoàn chỉnh ngày/khách/quote/đặt phòng và câu chữ; test luồng khách với API thật trước khi bổ sung nhiều thư viện.

Mốc 3: migration/quyền/audit và seed admin/staff; làm trang tài khoản admin, tình trạng phòng nhân viên.

Mốc 4: sổ thu/hoàn, dashboard, biểu đồ và CSV/PDF; đối chiếu số liệu server.

Mốc 5: inbox, badge/local notification và quyền; ảnh/banner/shimmer/animate có tiết chế.

Mốc 6: Google/Facebook, docs cấu hình, E2E khi có credentials; push là phần có điều kiện sau inbox/local hoạt động.

Mốc 7: kiểm thử tích hợp, kiểm tra giao diện điện thoại thật, build APK dev dùng API thật và hướng dẫn chạy. Chưa có HTTPS thì không giả coi APK dev là bản production.

Nếu một mốc thiếu OAuth/push credential, tiếp tục các phần độc lập, ghi rõ cấu hình còn thiếu và cách người dùng hoàn thiện. Không dừng toàn dự án chỉ vì nút Google chưa có client ID.

## 16. Báo cáo cuối cho người dùng

Trả lời tiếng Việt ngắn gọn: màn hình đã tách/tạo, chức năng đã nối API, migration đã chạy, cách khởi tạo tài khoản demo bằng env, kết quả test/build, OAuth/push nào đã kiểm chứng thật và phần nào chờ cấu hình. Không công khai mật khẩu, không tự tuyên bố tài khoản đã tạo nếu mới viết seed chưa chạy.

Cung cấp lệnh chạy đúng cấu trúc hiện có; nhắc backend và PostgreSQL cần chạy khi APK dùng dữ liệu thật, pgAdmin không cần mở. Hướng dẫn cập nhật app đang cài mà không xóa dữ liệu tùy tiện. Ghi danh sách screen thực tế ở docs/screens.md, không dùng số ước lượng cũ.

## 17. Tài liệu tham khảo kỹ thuật cho Codex

Đây là nguồn chính thức/package tác giả để kiểm tra API và cấu hình tại thời điểm triển khai, không phải yêu cầu pin bản mới nhất bất kể tương thích:

- Google Sign-In: https://pub.dev/packages/google_sign_in
- Google xác minh backend: https://developers.google.com/identity/sign-in/android/backend-auth
- Flutter Facebook Auth: https://pub.dev/packages/flutter_facebook_auth và https://facebook.meedu.app/docs/intro
- Meta token debugging: https://developers.facebook.com/docs/facebook-login/guides/access-tokens/debugging-and-error-handling/
- Carousel Slider: https://pub.dev/packages/carousel_slider
- Flutter Animate: https://github.com/gskinner/flutter_animate
- Shimmer: https://pub.dev/packages/shimmer
- Cached Network Image: https://pub.dev/packages/cached_network_image
- Image Picker: https://pub.dev/packages/image_picker
- Connectivity Plus: https://pub.dev/packages/connectivity_plus
- Local Notifications: https://pub.dev/packages/flutter_local_notifications
- Firebase Messaging: https://firebase.google.com/docs/cloud-messaging/flutter/client
- Secure Storage: https://pub.dev/packages/flutter_secure_storage
- fl_chart: https://pub.dev/packages/fl_chart
- share_plus: https://pub.dev/packages/share_plus

Danh sách học phần được cung cấp bởi người dùng là căn cứ chọn nhóm kiến thức. Không giả nhận tất cả package hoặc chức năng đã có trong code hay đã được giảng viên yêu cầu bắt buộc.

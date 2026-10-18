# Đặc tả tích hợp thư viện và tính năng TTTP dành cho Codex

Phiên bản 3 — 18/10/2026. Đặc tả bổ sung để thực hiện trên dự án hiện có, không phải yêu cầu tạo lại dự án.

## 1. Chỉ thị triển khai

Hãy trực tiếp tích hợp các tính năng trong tài liệu này vào ứng dụng khách sạn TTTP hiện tại. Đọc AGENTS.md áp dụng, README, migration, pubspec.yaml/pubspec.lock, theme, route, backend API và kiểm thử hiện có trước khi sửa. Nếu có DAC_TA_CODEX_HOTEL_BOOKING.md hoặc DAC_TA_NANG_CAP_TTTP_CHO_CODEX.md, dùng làm nền nhưng yêu cầu mới trong tài liệu này ưu tiên khi có xung đột.

Giữ Flutter/Dart, Provider, FastAPI/Python, PostgreSQL và cấu trúc workspace thực tế. Không tạo Flutter project khác, không thay toàn bộ auth hoặc database bằng Firebase. Không di chuyển thư mục chỉ để giống sơ đồ cũ. Giữ tên TTTP, applicationId, dữ liệu, tài khoản, migration đã áp dụng, cơ chế JWT và các luồng nghiệp vụ đã hoạt động.

Người dùng chấp thuận các đề xuất phù hợp của nhóm 1–11; loại bỏ TOÀN BỘ nhóm 12 AI/Tools. Không thêm chatbot, nhận dạng giọng nói, TTS, ML Kit AI, TensorFlow Lite, LangChain hoặc OpenCV. Thanh toán online chọn MoMo và VNPAY, không dùng In App Purchase.

Tích hợp sâu theo nhu cầu thực tế, không cài mọi package theo danh sách học phần. Các thư viện thay thế nhau chỉ chọn một. Không thêm nút demo rời rạc chỉ để chứng minh có package; tính năng phải nằm trong luồng sử dụng thật. Không tự thanh toán thật, mua dịch vụ hoặc tạo tài khoản dịch vụ ngoài cho người dùng.

### 1.1. Quy tắc giải quyết xung đột

Thực hiện theo thứ tự:

1. Kiểm tra tính năng hiện có và hợp đồng API/frontend thực tế.
2. Tái sử dụng service, model, endpoint, widget và theme đã có nếu phù hợp.
3. Điều chỉnh PHẦN MỚI để thích ứng: tên trường, route, trạng thái, quyền, lịch, giao dịch, lưu file, mạng và môi trường deploy.
4. Chỉ sửa phần cũ khi cần để tích hợp đúng; cập nhật đồng thời client, server, migration và tests. Không phá luồng đang hoạt động chỉ để thuận tiện cho package.
5. Nếu thực sự không thể tích hợp sau khi đã xem phương án thay thế, không áp dụng phần đó. Ghi rõ lý do kỹ thuật, tác động và giải pháp gần nhất trong docs/integration_decisions.md. Không bỏ chỉ vì hơi khó hoặc chưa có credentials.
6. Thiếu cấu hình dịch vụ ngoài là trạng thái CHƯA CẤU HÌNH, không phải lý do xóa tính năng hoặc giả kết quả thành công.

Không cố giữ đúng 12 bảng khi thêm nghiệp vụ cần bảng mới; nhưng không tạo bảng trùng với dữ liệu đã có. Không reset/drop/truncate hotel_booking. Test dùng database riêng đã đánh dấu test.

## 2. Mục tiêu nghiệm thu xuyên suốt

Mỗi tính năng phải đồng bộ cả:

- Backend: schema, quyền, transaction, lịch sử, API response, trạng thái sự kiện và báo cáo.
- Frontend: theme, câu chữ, toolbar, điều hướng, dữ liệu giữa trang, loading/error/empty, vòng đời, trạng thái tài khoản.
- Các thiết bị: sau refresh hoặc cơ chế đồng bộ được mô tả, các trang phải phản ánh cùng trạng thái server.
- Tài liệu và kiểm thử: ghi rõ mã đã chạy, phần cần cấu hình ngoài và giới hạn thực tế.
- Lưu ý tránh việc tính năng mới làm lỗi tính năng khác, hoặc ảnh hưởng xấu (chẳng hạn như tránh việc thông báo toast hiện lên che mất thanh công cụ)

Ví dụ bắt buộc: sau hủy đặt phòng, chi tiết/list/dashboard/thông báo/lịch nhắc/khả dụng/tiền cần hoàn đều cập nhật đúng. Không chỉ update một bảng backend và để frontend hiển thị dữ liệu cũ.

## 3. Đồng bộ giao diện TTTP bắt buộc

### 3.1. Kiểm tra theme trước khi thêm package

Đọc ThemeData/ColorScheme/TextTheme/theme extension thực tế. Giữ thiết kế TTTP đang được dùng; nếu thiếu token mới thì bổ sung tập trung. Tông dự kiến: primary xanh đậm #123A52, secondary vàng đồng #B58A45, nền #F5F7FA, surface trắng; không ép đổi nếu dự án đã có bộ token TTTP tương đương được người dùng chấp nhận.

Tất cả toast, overlay, badge, lịch, PDF viewer, map controls, scanner overlay, video controls, feedback form, trang thanh toán phải dùng cùng font, spacing, bo góc, icon style, elevation, màu nền và cách viết tiếng Việt. Không để một thông báo mặc định màu hồng/tím nổi lên trong app xanh-vàng chỉ vì package mặc định như vậy.

Màu semantic được phép: thành công xanh lá, lỗi đỏ, cảnh báo vàng/cam vừa phải, nhưng dùng token chung, icon và text; không chỉ phân biệt bằng màu. Màu nhận diện MoMo/VNPAY/Google/Facebook được giữ trong LOGO/chip nhận diện chính thức, không biến cả trang sang theme của nhà cung cấp.

Tạo hoặc mở rộng AppFeedbackService, AppLoadingService và shared widgets; các màn hình gọi chúng thay vì gọi package với màu mặc định riêng lẻ. Không tạo hai hệ toast hoặc hai global overlay host chồng nhau.

### 3.2. Yêu cầu UX chung

- Tiếng Việt rõ, dùng “Đặt phòng”, “Xác nhận đặt phòng”, “Đặt phòng của tôi”, “Mã đặt phòng”; không lộ mã trạng thái hoặc stack trace.
- Touch target phù hợp điện thoại, xử lý màn 360px/cỡ chữ lớn/bàn phím, SafeArea.
- NavigationBar/AppBar/drawer/tab/FAB dùng theo vai trò, giữ trạng thái tab và back hợp lý; không nhét tất cả tính năng vào bottom bar.
- Trang mới phải có route, guard quyền và điểm truy cập dễ tìm. Thông báo/deep link mở đúng trang sau đăng nhập, không bypass guard.
- Khi logout/chuyển tài khoản: xóa dữ liệu cache theo người dùng, badge, tác vụ polling, local reminder riêng tư và trạng thái màn hình; không để lộ đơn/tài liệu tài khoản trước.
- Các request sau khi màn bị dispose không cập nhật widget sai; quản lý controller/subscription/dispose đầy đủ.
- Tôn trọng giảm chuyển động, không chớp nháy hoặc animation vô hạn khi đã tải xong.

## 4. Cấu hình dịch vụ ngoài và nút Chưa cấu hình

### 4.1. Một nguồn trạng thái tính năng

Backend cung cấp endpoint capabilities công khai AN TOÀN hoặc mở rộng endpoint hiện có, ví dụ GET /app/capabilities. Frontend kết hợp capability server với khả năng plugin/config build để xác định có thể dùng thật. Response chỉ công khai enabled/configured/environment/reason_code; không lộ secret, connection string, webhook credentials hoặc token.

Ví dụ cấu trúc định hướng:

```json
{
  "payments": {
    "momo": {"enabled": false, "configured": false, "environment": "sandbox", "reason_code": "NOT_CONFIGURED"},
    "vnpay": {"enabled": false, "configured": false, "environment": "sandbox", "reason_code": "NOT_CONFIGURED"}
  },
  "push": {"enabled": false, "configured": false},
  "social_login": {
    "google": {"enabled": false, "configured": false},
    "facebook": {"enabled": false, "configured": false}
  }
}
```

Tên có thể thích ứng code cũ, nhưng chỉ có một nguồn quyết định nghiệp vụ phía server. Client không tự bật được payment nếu server chưa sẵn sàng.

### 4.2. Cách hiển thị

Tính năng thiếu cấu hình vẫn nằm ĐÚNG VỊ TRÍ: ví dụ MoMo/VNPAY ở phần phương thức thanh toán, provider login ở trang đăng nhập. Nút/card giảm độ nổi bật, disabled, có dòng/chip “Chưa cấu hình” đọc được. Có icon thông tin riêng giải thích “Tính năng sẽ khả dụng sau khi hoàn tất cấu hình dịch vụ”. Không làm chữ mờ đến mức không đọc được, không giả xử lý khi nhấn.

Phân biệt: chưa cấu hình; không có quyền; không áp dụng cho trạng thái đơn; người dùng chưa cấp quyền; thiết bị không hỗ trợ; mạng/server tạm không truy cập được. Không đổi tất cả thành “Chưa cấu hình”. Nếu capabilities tải lỗi, dùng trạng thái chưa kiểm tra/không kết nối, retry; không suy ra mọi cấu hình đã bị xóa.

Chuẩn bị docs/external_configuration.md: dịch vụ, mục đích, config cần nhập, phía client/server, cách lấy, URL callback, test sandbox, trạng thái hiện tại. Secrets nằm env/backend, không đưa vào APK hoặc log. Nếu thiếu config gây SDK crash lúc init, dùng init có điều kiện; giữ UI placeholder nhưng không khởi tạo plugin không hợp lệ.

## 5. Ma trận thư viện chốt và trách nhiệm

| Nhóm | Lựa chọn | Vai trò trong TTTP |
| --- | --- | --- |
| 1 | toast_notification | Loading/Check/Error ngắn trong app |
| 1 | flutter_easyloading | Overlay tác vụ quản trị và progress thật |
| 1 | shimmer | Skeleton danh sách/chi tiết/dashboard |
| 1 | flutter_animate | Chuyển động nhẹ, state transition |
| 1 | convex_bottom_bar, có điều kiện | Thay bottom navigation khách nếu tương thích và đẹp hơn; không thêm bottom bar thứ hai |
| 2 | carousel_slider | Banner/gallery nổi bật, không cài Carousel Slider Plus song song |
| 2 | table_calendar | Lịch phòng/đặt/bảo trì theo tuần-tháng cho nhân viên |
| 2 | easy_date_timeline | Chọn ngày nhanh ở trang tác nghiệp nhân viên |
| 2 | Date-range picker hiện có | Giữ picker gốc nếu đủ; Calendar Date Picker chỉ chọn đúng package nếu có lợi ích rõ, không thêm lịch thứ tư |
| 3 | cached_network_image | Ảnh URL cache, placeholder/error/invalidation |
| 3 | image_picker | Avatar và ảnh phòng chụp/chọn từ thư viện |
| 3 | crop_your_image | Crop avatar/ảnh bìa theo tỷ lệ |
| 3 | easy_image_viewer | Gallery full screen, zoom, chuyển ảnh |
| 3 | image_editor, có điều kiện | Xoay/lật ảnh nếu crop/picker chưa xử lý nhu cầu |
| 4 | path_provider | File export/cache tạm có quản lý |
| 4 | file_picker | Chọn CSV nhập danh mục; save khi nền tảng hỗ trợ |
| 4 | PDF viewer cụ thể | Xem báo cáo PDF, pin package sau kiểm tra license/SDK; không cài theo tên slide chung chung |
| 5 | url_launcher | Hotline, email, bản đồ ngoài, mở cổng thanh toán phù hợp |
| 5 | connectivity_plus | Tín hiệu mạng, không thay kiểm tra request |
| 5 | device_info_plus | Thông tin thiết bị có chọn lọc cho hỗ trợ lỗi |
| 5 | webview_flutter, có điều kiện | Chính sách nội dung trusted; chỉ dùng payment WebView nếu provider cho phép |
| 6 | video_player | Video giới thiệu khách sạn/phòng |
| 7 | badges | Unread notifications/đơn chờ, đồng bộ số server |
| 7 | flutter_local_notifications | Nhắc lưu trú tại thiết bị, tap/action phù hợp |
| 7 | permission_handler khi cần | Xin quyền theo chức năng, không trùng cơ chế plugin |
| 8 | firebase_messaging | Push server, tích hợp khi có config; không dùng OneSignal đồng thời |
| 8 | MoMo và VNPAY | Hai adapter thanh toán qua API backend, SDK Flutter phù hợp nếu thật sự cần |
| 9 | geolocator | Vị trí một lần khi yêu cầu, khoảng cách thẳng |
| 9 | flutter_osm_plugin mặc định | Một bản đồ tại TTTP, marker/controls; thay bằng map hiện có nếu đã tương thích tốt |
| 10 | mobile_scanner | Nhân viên quét QR tìm đơn |
| 11 | flutter_secure_storage | Token và dữ liệu phiên tối thiểu |
| 11 | local_auth | Xác thực thiết bị để mở khóa phiên, nếu Native Auth trong slide là package khác phải ghi rõ lựa chọn |
| 11 | feedback | Ảnh đánh dấu lỗi, mô tả, gửi backend sau preview |

Phụ thuộc bổ trợ được phép: một QR generator, share_plus, PDF/chart tools, parser CSV, timezone, validators, deep-link handler nếu chưa có. Ghi chúng là phụ thuộc bổ trợ, không bịa thuộc slide. Tái sử dụng fl_chart/report exporter hiện có.

Không cài Live Activities cho mục tiêu Android hiện tại; audio/record/ringtone/callkit khi chưa có use case; nhiều scanner/map/local notifier trùng chức năng; In App Purchase; Microsoft Viewer chưa xác định package. Không thêm chức năng AI/Tools. Một mục có điều kiện không mặc nhiên được bỏ: đánh giá, dùng phương án phù hợp hoặc ghi quyết định có căn cứ.

Trước cài kiểm tra pub.dev/tài liệu tác giả, release notes, SDK/minSdk/Gradle/license. Không nâng tất cả dependency lên mới nhất; pin tương thích và giữ lockfile. Package slide cũ không chạy được thì thay thế gần nhất có giải thích thay vì sửa SDK bừa để ép chạy.

## 6. Hiệu ứng, toast và tiến trình

### 6.1. Toast

Tạo wrapper TTTP hỗ trợ tối thiểu success/error/loading, quản lý controller, thời gian hiển thị, đóng khi response đến hoặc timeout và khi logout/dispose. Dùng cho login thành công, lưu hồ sơ, tạo/hủy đơn, đổi trạng thái phòng, cập nhật danh mục, quét mã thành công/thất bại. Lỗi validation ở input vẫn hiển thị gần field, không chỉ toast thoáng qua.

Không giả định toast tự đọc progress. Loading chỉ cho biết đang chờ; percent cần số bytes/công việc có thật. Không show thành công khi server chưa commit. Nếu toast_notification không tương thích SDK hiện tại, kiểm tra API/source rồi thay adapter UI phù hợp có ghi lý do, không xóa các trạng thái nghiệp vụ.

### 6.2. EasyLoading, Shimmer và Animate

EasyLoading dành cho export/upload/tác vụ quản trị cần chờ; async try/finally luôn dismiss, tránh global overlay bị request cũ đóng nhầm request mới. Progress đo bytes khi có API hỗ trợ; server đang tạo PDF mà chưa có tiến độ thì dùng spinner và thông báo, không tăng % giả. Chặn thao tác chỉ khi thật sự cần, không khóa cả app lúc tải danh sách.

Shimmer giữ bố cục gần dữ liệu thật, không nháy liên tục giữa các refresh nền; timeout chuyển error/retry, không skeleton vô hạn. Flutter Animate dùng cho card/filter/empty/success nhẹ, không chạy lại toàn danh sách mỗi rebuild và không cản nhập liệu. Một hành động chỉ có một phản hồi nổi bật, không toast+SnackBar+overlay thành công cùng lúc.

Convex Bottom Bar nếu được chọn phải map đúng tab cũ, icon/theme TTTP, phục hồi state, accessibility và test màn nhỏ; không đưa tác vụ Đặt phòng không có ngày vào nút giữa làm sai luồng.

## 7. Lịch, carousel và luồng ngày đặt phòng

Carousel có indicator, swipe, autoplay vừa phải, pause khi tương tác, bấm mở đúng phòng/loại và truyền tiêu chí tìm kiếm khi có. Không lặp banner khi chỉ có một ảnh, không hiển thị khuyến mãi giả.

Date-range picker trên Home/Search/RoomDetail cùng dùng SearchCriteria Provider: ngay_nhan, ngay_tra, so_khach, filters. Ngày Việt Nam, DATE serialize yyyy-MM-dd, tối thiểu 1 tối đa 30 đêm, không cho nhận quá khứ. Ngày trả không chiếm đêm. Thay ngày/số khách thì quote và khả dụng invalidated trên mọi trang; không reset bộ lọc sau login.

Table Calendar dùng cho staff/admin chọn phòng, xem ngày có đơn/maintenance với marker/chú giải; chọn ngày mở danh sách sự kiện, không đọc cờ trống/bận tay thay lịch. Easy Date Timeline là bộ lọc tác nghiệp theo ngày, giữ đồng bộ với calendar/filter chung nếu cùng trang. Không thêm hai nguồn selectedDate không khớp nhau.

Backend endpoint lịch theo phòng/khoảng chỉ trả dữ liệu đúng quyền, có giới hạn khoảng ngày; không tải toàn lịch sử. Public availability không trả danh tính khách khác. Khoảng ngày đánh dấu không có nghĩa đặt chắc chắn: server kiểm tra lại khi ghi bằng transaction và exclusion constraint.

## 8. Chuỗi ảnh hoàn chỉnh

Chọn/chụp → xem trước → crop theo tỷ lệ → xoay/lật nếu cần → kiểm tra dung lượng → upload có trạng thái → chọn bìa/thứ tự → gallery khách xem.

Avatar chỉ của chính tài khoản; ảnh loại phòng chỉ ADMIN, nhân viên không được ghi danh mục qua endpoint này. Nếu chưa có avatar thì thêm trường phù hợp bằng migration, không hardcode tài khoản. Upload multipart có kiểm tra magic/content ảnh server, loại JPEG/PNG/WebP, kích thước tối đa cấu hình (mặc định 5 MiB), số lượng giới hạn, UUID filename và chống path traversal. Không chỉ tin extension hoặc MIME client.

Ảnh camera cache tạm phải upload/copy trước khi coi là lưu lâu dài. Android có xử lý lost data do activity bị hệ thống đóng theo plugin nếu cần. Crop giữ ảnh gốc cho tới khi xác nhận, Cancel không ghi; update bìa/thứ tự có transaction. Image Editor chỉ thêm cho thao tác đang thiếu, không thành editor phức tạp ngoài phạm vi.

Cached Network Image có placeholder/error/retry, phân biệt thumbnail/full size, giới hạn cache bộ nhớ; thay URL/version ảnh khi sửa để cache không hiển thị ảnh cũ. Gallery zoom/swipe/dispose; không tự tải ảnh full size cho mọi card. Ảnh báo cáo/feedback riêng tư không được public chung thư mục ảnh phòng.

Giữ storage abstraction hiện có. Nếu chạy hosting ổ tạm như Render, không lưu ảnh upload duy nhất trên filesystem tạm. Chuẩn bị persistent object storage; khi thiếu cấu hình upload online, làm mờ đúng action với Chưa cấu hình, không hứa ảnh tồn tại qua redeploy. Local dev có thể dùng uploads/ với giới hạn đã nêu.

## 9. Nhập file và xem/xuất báo cáo

### 9.1. Import CSV phòng cho admin

File Picker chỉ chọn file .csv, giới hạn kích thước/số dòng (đề xuất 2 MiB/1000 dòng). Có tải mẫu và preview: so_phong, ma_loai hoặc mã loại ổn định, tang, ghi_chu; không cho giá/quyền nhập tùy ý ngoài schema đã chốt. Parser xử lý UTF-8 BOM, dấu phẩy/trích dẫn chuẩn, không tự đoán định dạng đến mức sai dữ liệu.

Backend validate lại quyền, kiểu, loại phòng, số phòng unique và trùng trong file. Trả kết quả theo dòng, tên lỗi dễ hiểu. Hai bước validate preview → confirm import. Server xác minh lại khi confirm để tránh race; dùng file hash/token import hoặc request id để tránh người dùng preview một file rồi gửi file khác. Chọn all-or-nothing để dễ giải thích: có lỗi thì không nhập dòng nào; thành công thì một transaction, ghi audit và refresh danh sách. Không tự overwrite phòng đã tồn tại, không đổi loại phòng có đơn giữ chỗ trái nghiệp vụ. Không mở chức năng import toàn bộ DB.

### 9.2. Báo cáo PDF/CSV

Tái sử dụng báo cáo thực thu hiện có, không tạo bộ số liệu client khác server. PDF Viewer cho preview: loading/error/retry, số trang/chuyển/zoom và save/share. Path Provider dùng file tạm/app directory; File Picker/save hoặc share sheet để người dùng lưu vị trí bên ngoài theo API nền tảng. Không xin quyền quản lý toàn bộ bộ nhớ.

PDF và CSV dùng cùng filter, quyền ADMIN, định nghĩa kỳ/múi giờ/tổng khớp dashboard. PDF tiếng Việt, theme TTTP, header/date/biểu đồ/table không clipping; CSV UTF-8 BOM và escape formula injection. Giới hạn kỳ export, dung lượng, cleanup file tạm và dữ liệu riêng sau logout. Không coi PDF viewer tự sinh báo cáo.

## 10. Mạng, liên hệ, thông tin thiết bị và WebView

Connectivity Plus cung cấp tín hiệu kết nối, không chứng minh Internet/API hoạt động. ApiService giữ phân biệt network/timeout/HTTP/JSON; cảnh báo server đang khởi động khi có căn cứ, không gán mọi lỗi thành mất mạng. Retry chỉ cho request an toàn theo chính sách; không tự POST lại đặt phòng/thu tiền khi mạng trở lại. Màn offline vẫn cho xem cache có nhãn dữ liệu cũ và không báo khả dụng hiện tại như dữ liệu thật.

URL Launcher: hotline/email/site nếu đã được cấu hình, nếu thiếu để thông tin chưa cung cấp hoặc disabled, không bịa. URI allowlist/validate scheme, mở bản đồ và provider payment theo chính sách; lỗi không có app xử lý phải có fallback phù hợp. Không mở URL tùy ý từ QR hoặc response chưa xác minh.

Device Info Plus: chỉ model/OS/app version và thông tin hỗ trợ cần thiết, người dùng xem trước; không IMEI/serial/identifier dài hạn. Không tự gửi vị trí hoặc email cùng log. Không thay báo lỗi backend bằng việc chỉ xem model điện thoại.

WebView dùng trang chính sách/hướng dẫn trusted khi thực sự là nội dung web; nếu app đã render local chính sách tốt thì giữ, không nhúng browser cho đủ package. Allowlist domain, giới hạn điều hướng/JS theo nhu cầu, loading/error/back; không bỏ qua lỗi TLS, không tải file tùy ý. Payment chỉ dùng WebView nếu tài liệu gateway cho phép luồng đã chọn, không chặn mở ví app cần thiết.

## 11. Video giới thiệu

Video Player cho video TTTP hoặc loại phòng: poster, play/pause, seek, duration, volume/mute, fullscreen, buffering/error/retry. Không autoplay có tiếng, pause khi chuyển trang/background, dispose controller và không chạy nhiều video đồng thời ngoài ý muốn. Video phải ở URL media thực hoặc asset phù hợp; URL trang YouTube không đưa trực tiếp vào Video Player.

Backend/config lưu URL/poster/caption phù hợp, admin cập nhật qua quyền quản trị nếu bổ sung UI. Giới hạn tải video để không làm nặng gói miễn phí; ưu tiên video ngắn đã tối ưu, không thêm upload video nặng nếu chưa có storage. Không có media cấu hình thì trang hiện placeholder có nghĩa, không phát video giả không liên quan.

## 12. Inbox, badge, nhắc lịch và push

### 12.1. Trung tâm thông báo chung

Tái sử dụng bảng/service thông báo hoặc thêm bảng nếu chưa có. Record theo tài khoản/sự kiện, read_at, related booking ID và event key chống lặp. Tạo trong transaction nghiệp vụ hoặc transactional outbox; chỉ phát sự kiện sau commit. Sự kiện đặt/hủy/xác nhận/từ chối/thanh toán ảnh hưởng đúng người nhận, không broadcast dữ liệu khách cho mọi tài khoản.

UI list phân trang, chi tiết/điều hướng, đọc một/đọc tất cả, unread count và badge cùng nguồn. Một thông báo mở từ push/local/inbox phải đánh dấu/refresh nhất quán. Không lấy số badge bằng số sự kiện nhận mỗi lần refresh vì sẽ tăng lặp.

### 12.2. Local notification và quyền

Chọn flutter_local_notifications, không cài Awesome Notifications đồng thời. Nhắc trước nhận phòng của đơn đã xác nhận theo timezone Việt Nam; cho chọn bật/tắt và giờ nhắc hợp lý. Tạo/cập nhật/hủy dựa trên trạng thái server, không lịch quá khứ; lưu mapping notification ID ổn định tránh trùng. Hủy khi đơn hủy/từ chối hoặc logout/chuyển tài khoản. Permission theo Android version, xử lý từ chối và mở Settings khi người dùng yêu cầu, không xin exact alarm nếu lịch gần đúng đủ mục đích.

Tap khi app đang mở/background/terminated xử lý chờ router/session sẵn sàng rồi mở đơn đúng quyền; nếu chưa login lưu pending navigation an toàn. Local notification không tự nhận thay đổi server khi app tắt; ghi đúng giới hạn này, không gọi nó là push.

### 12.3. FCM

Tích hợp firebase_messaging chỉ làm transport, auth/DB vẫn FastAPI/PostgreSQL. Nếu thiếu config Firebase/provider backend: UI cài đặt push disabled Chưa cấu hình, inbox/local còn dùng theo quyền. Tạo docs cấu hình Firebase Android, applicationId đúng, file config cần thiết, service account qua secret backend, notification icon/channel và môi trường.

Device token liên kết với tài khoản đã xác thực, cập nhật khi đổi token, gỡ khi logout, hỗ trợ nhiều thiết bị và xử lý token hết hiệu lực. Backend gửi từ outbox/dispatcher retry backoff, dedup event; không nhúng server credential vào APK. Foreground chỉ hiển thị một lần: tránh FCM auto display và local show tạo hai bản.

Push chỉ là tín hiệu; khi mở phải query API trạng thái thật. Không chứa token đăng nhập/mật khẩu/điện thoại khách trong nội dung màn khóa. Hosting free ngủ có thể trì hoãn việc phát event; không hứa realtime 24/7 khi không có worker chạy liên tục. Không dùng OneSignal song song.

## 13. Thanh toán MoMo và VNPAY

### 13.1. Quyết định nghiệp vụ tương thích hệ thống

Bổ sung cả hai phương thức để người dùng chọn, nhưng cấu hình độc lập. Mặc định sandbox; môi trường production phải được người dùng cấu hình rõ. Không dùng In App Purchase. Giữ cách ghi nhận tiền mặt/chuyển khoản thủ công đã có như phương án khác, không xóa sổ thu/hoàn hiện hành.

Để không phá quy trình duyệt đơn hiện tại, online payment chỉ mở cho phiếu DA_XAC_NHAN của chính khách, còn số tiền phải thu > 0. Phiếu CHO_XAC_NHAN hiển thị “Có thể thanh toán sau khi đặt phòng được xác nhận”. Không bắt thanh toán trước xác nhận, không tự thêm trạng thái đặt mới chỉ để giống gateway.

Trang xác nhận đặt có thể giới thiệu phương thức nhưng không trừ tiền hoặc mở gateway trước tạo/duyệt đơn. Chi tiết đơn có card thanh toán: tổng tiền, đã thu ròng, còn phải thanh toán, trạng thái, lịch sử cho chủ đơn; nút Thanh toán và lựa chọn MoMo/VNPAY. Nếu chưa config, nút đúng vị trí, disabled kèm “Chưa cấu hình”, không tạo attempt hay đổi sổ tiền.

### 13.2. Adapter và phiên thanh toán

Tái sử dụng service tài chính hoặc mở rộng, thêm PaymentGatewayAdapter với create_payment/query_transaction/verify_callback và refund khi được hỗ trợ/cấu hình. MoMo/VNPAY là hai adapter khác định dạng/chữ ký. Package Flutter là công cụ mở luồng nếu phù hợp; toàn bộ secret/chữ ký và xác minh nằm backend, không chọn package cũ không an toàn chỉ vì tên trong slide.

Thêm payment_attempt nếu chưa có tương đương: id UUID, booking FK, provider, environment, merchant_reference UNIQUE, client_request_id, requested_amount_vnd, currency VND, state CREATED/PENDING/SUCCEEDED/FAILED/EXPIRED/CANCELLED/REQUIRES_REVIEW, provider_transaction_id, timestamps, expires_at và dữ liệu đối soát tối thiểu. UNIQUE tham chiếu provider+environment, khóa dedup callbacks. Không lưu thông tin thẻ hoặc payload bí mật không cần thiết.

Số tiền backend lấy từ số còn phải thu khi giữ khóa phiếu, dùng integer VND. Chuyển đơn vị sang API gateway đúng tài liệu adapter (ví dụ trường VNPAY có quy tắc nhân đơn vị); không nhân/chia 100 chung cho cả hai. Khách không tự nhập số tiền/gửi giá để server tin cậy.

Mỗi phiếu chỉ có một payment attempt active tại một thời điểm để tránh trả MoMo và VNPAY song song. Có expiry và đối soát trạng thái cũ trước khi mở attempt mới. Ghi nhận thu thủ công khi có attempt pending phải từ chối cho tới khi đối soát/hủy attempt theo chính sách; không cho hai đường ghi cộng vượt mức. Timeout client không có nghĩa tiền thất bại.

Request create có idempotency key mỗi ý định thanh toán; replay cùng payload trả attempt cũ, cùng key khác payload trả 409. Không giữ transaction khóa PostgreSQL trong lúc chờ network gateway: tạo attempt/giữ chỗ thanh toán và commit, gọi ngoài, cập nhật nguyên tử sau đó; xử lý provider tạo thành công nhưng HTTP timeout bằng query/reconcile, không tạo order mới vô hạn.

### 13.3. Callback và return

Backend tạo payment URL/deeplink từ API gateway, Flutter mở trình duyệt/ứng dụng ví bằng phương thức cho phép. Public IPN HTTPS server-to-server phải truy cập được từ gateway. Return/deep link chỉ để khôi phục UI và query trạng thái backend, KHÔNG là bằng chứng đã trả tiền.

Xác minh signature theo đúng API/version, merchant/app binding, environment, order/reference, amount/currency và kết quả provider. MoMo IPN phải xác minh chữ ký; VNPAY kiểm tra checksum cùng mã kết quả/trạng thái. Không copy một ví dụ khác loại sản phẩm token/installment để dùng sai cho cổng thanh toán thường.

Callback lặp, đảo thứ tự hoặc đến sau return phải xử lý idempotent, không ghi hai giao dịch thu, không đổi SUCCEEDED về FAILED do callback cũ. Khóa phiếu/attempt khi ghi, tạo thu đã xác minh vào cùng ledger backend và sinh lịch sử/audit/notification trong cùng transaction. Endpoint IPN có thể không dùng JWT khách nhưng bắt buộc xác thực chữ ký; trả acknowledgment đúng gateway sau persist, không trả schema lỗi app làm provider retry vô hạn.

Kết quả unknown/pending hiển thị “Đang chờ xác nhận thanh toán”, có Kiểm tra lại, polling có giới hạn khi foreground và resume; không hiển thị đã thanh toán chỉ vì app ví đóng. Khách quay lại bằng deep link độc hại cũng không thể sửa tiền.

### 13.4. Tình huống cạnh tranh và hoàn tiền

Nếu tiền thành công sau khi đơn đã hủy, không phục hồi đơn hoặc chiếm lịch phòng đã giải phóng. Vẫn ghi giao dịch thật vào sổ, đánh dấu cần hoàn/đối soát cho admin. Nếu thành công muộn khiến tổng thu vượt do tình huống không tránh được, giữ bằng chứng tiền nhận, đưa REQUIRES_REVIEW/tiền dư cần hoàn; không vứt bỏ callback và giả không nhận tiền. Báo cáo tính đúng dòng tiền và khoản cần hoàn.

Hoàn online chỉ admin, có lý do và giới hạn <= số thu chưa hoàn, khóa/dedup/đối soát. Nếu chưa cấu hình refund API thì hiển thị “Chưa cấu hình hoàn tiền trực tuyến”, trạng thái cần xử lý; có thể ghi nhận hoàn ngoài hệ thống qua luồng thủ công có quyền và căn cứ hiện có, không giả gọi refund thành công.

Không sửa/xóa giao dịch đã xác nhận, không cộng cả attempt thành công và ledger làm doanh thu hai lần. Sandbox tách rõ môi trường và KHÔNG tính vào thực thu production; báo cáo demo có nhãn sandbox. Giá trị đặt vẫn khác doanh thu thực thu.

### 13.5. Cấu hình người dùng làm ngoài

MoMo: tài khoản/ứng dụng merchant sandbox phù hợp, partner/access/secret theo sản phẩm được chọn, IPN URL public HTTPS, redirect/deep link theo tài liệu. VNPAY: sandbox merchant, TmnCode/HashSecret, payment/query endpoints và return/IPN URLs. Liệt kê đúng biến env đã implement, không bịa credentials dùng chung.

Nếu chưa cấu hình: hoàn thiện adapter interface, validation, routes, UI card, tests dùng fixture có kiểm soát và setup docs; không gọi live gateway. Báo trạng thái chờ cấu hình, không đánh dấu E2E thành công. Không đề nghị người dùng gửi secret qua chat; điền vào .env/hosting secrets.

## 14. Bản đồ và chỉ đường TTTP

Dùng CHÍNH XÁC tọa độ người dùng cung cấp:

```text
latitude  = 10.855802343959219
longitude = 106.78566243940791
```

Đây là vị trí TTTP trong ứng dụng demo. Không reverse-geocode rồi đổi tên thành tòa nhà khác, không sửa tọa độ, không yêu cầu xác minh đó có phải khách sạn thật. Marker/tiêu đề hiển thị “TTTP”. Không bịa địa chỉ đường phố/hotline từ tọa độ.

Ưu tiên flutter_osm_plugin nếu dự án chưa có bản đồ. Nếu đã có map khác tương thích và được cấu hình, giữ và áp dụng tọa độ trên, tránh cài nhiều map SDK. Tuân thủ attribution và điều kiện tile/routing provider, không tải offline hàng loạt tile. Không hứa miễn phí vô hạn mọi dịch vụ OSM.

Màn Vị trí và chỉ đường có điểm vào từ Home/giới thiệu/chi tiết, marker TTTP, zoom, trở về vị trí khách sạn, nút Vị trí của tôi và Mở chỉ đường. Chỉ khi người dùng bấm vị trí mới xin foreground location; từ chối/GPS tắt vẫn xem marker TTTP và mở map ngoài theo đích được. Không cần quyền vị trí chỉ để xem điểm cố định.

Geolocator lấy vị trí một lần, tính khoảng cách thẳng và ghi rõ “Khoảng cách tham khảo theo đường thẳng”; không gọi là quãng đường lái xe/ETA. Mở Google Maps hoặc app bản đồ bằng URL Launcher với đích tọa độ, origin có thể để app ngoài tự xác định. Vẽ route/ETA trong app chỉ khi có routing service cấu hình; nếu không, giữ chức năng chỉ đường ngoài, không vẽ đường thẳng rồi gọi là tuyến đi xe.

Mạng tile lỗi có placeholder/retry và tọa độ dạng text/nút mở bản đồ; không làm crash trang chi tiết. Controls theo theme TTTP, giữ attribution đọc được.

## 15. QR mã đặt phòng cho nhân viên

Mobile Scanner đọc QR; thêm một generator tương thích để khách xem QR trong chi tiết đơn. QR chỉ chứa opaque reference/token nhận diện đặt phòng và version hoặc định dạng TTTP đã chốt, không JWT đăng nhập/phone/password/dữ liệu cá nhân. Nếu token QR có thể dùng như bearer truy cập, phải hạn dùng/thu hồi và vẫn kiểm tra quyền server; đơn giản hơn là reference lookup chỉ staff được xác thực mới xem.

Trang quét có khung theo theme, torch/switch camera khi hỗ trợ, hướng dẫn, nhập mã thủ công và xử lý quyền. Debounce/dừng scanner sau phát hiện hợp lệ, không gọi API 30 lần theo frame. Scan reference → backend staff lookup → chi tiết hiện hành. Không tự duyệt, thu tiền hoặc check-in khi quét.

QR không đúng định dạng/đơn không tồn tại/không quyền hiển thị lỗi phù hợp, không mở URL ngẫu nhiên trong QR. Stop camera khi background/rời trang và dispose. Không dùng đồng thời Simple Barcode Scanner hoặc ML Kit scanning cho cùng mục đích. Chưa thêm quy trình check-in/out chỉ để có nút quét.

## 16. Bảo mật phiên và phản hồi lỗi

Secure Storage giữ JWT và metadata tối thiểu, không mật khẩu rõ. Đọc lỗi có recovery an toàn; logout xóa token và state. JWT hết hạn vẫn yêu cầu login hoặc refresh theo cơ chế đã có; không thay auth hiện tại để demo thư viện.

Local Auth: bật/tắt trong bảo mật tài khoản, yêu cầu xác thực phiên hợp lệ khi bật. Hỗ trợ fingerprint/device credential tùy thiết bị, xử lý cancel/unavailable/lockout; app quay lại sau thời gian chờ có thể khóa local. Local auth chỉ xác thực thiết bị, không thay kiểm tra quyền backend, không gia hạn JWT và không đồng nhất vân tay với một tài khoản TTTP. Nếu dùng khóa mã app riêng thì chỉ một cơ chế tương thích, không thêm Flutter Screen Lock trùng khi không cần.

Feedback: action Báo lỗi/góp ý từ Tài khoản hoặc trang lỗi; người dùng chụp giao diện, đánh dấu, nhập mô tả, xem trước thông tin thiết bị được gửi rồi xác nhận. Không tự chụp/gửi màn hình login/mật khẩu/payment/secret; vùng nhạy cảm được che hoặc không cho chụp. Không đính kèm token, URL có secret hoặc toàn bộ log môi trường.

Backend nhận feedback có auth, giới hạn nội dung/file/rate, lưu riêng bảo vệ quyền; admin có danh sách/chi tiết và trạng thái tiếp nhận/đang xử lý/đã xử lý. Không public ảnh lỗi như ảnh phòng. Feedback library chỉ thu dữ liệu UI; hệ thống phải có nơi tiếp nhận thật, nếu endpoint chưa xong không hiện gửi thành công.

## 17. Đồng bộ model, API và dữ liệu

Tái sử dụng endpoint naming và schema hiện tại; bổ sung docs/api.md và OpenAPI. Dùng DTO request/response đúng whitelist, toJson/fromJson đồng bộ. Đừng serialize trực tiếp SQLAlchemy model có trường secret. Ngày lưu trú DATE và timestamp có timezone giữ quy ước gốc.

Service/frontend cần xử lý tối thiểu: availability/search quote state; booking state; payment amount/status; notification read/unread; reminder schedule; admin totals; cached room images. Dùng invalidation/event dispatch Provider tập trung hoặc query refresh có kiểm soát, không tự sửa từng widget rồi bỏ sót màn khác.

Sau payment confirmed/refund/cancel, reload chi tiết booking, list, ledger và dashboard có liên quan; sau ảnh update bust cache ảnh cũ; sau đổi lịch cập nhật calendar/timeline/search; sau quyền account thay đổi update menu/routes và backend checks. Khi app resume query lại trạng thái quan trọng thay vì chỉ tin state trước khi mở ví/bản đồ.

Bảng bổ sung chỉ khi chưa có tương đương: payment_attempt/webhook dedup, notification/outbox/device token, feedback, import batch/audit, media metadata. Migration có default/backfill hợp lý, không mất dữ liệu cũ. Không đồng nhất trạng thái thanh toán với trạng thái booking hoặc trạng thái vệ sinh.

Không ngắt API LAN hiện có; cấu hình API_BASE_URL hỗ trợ local HTTPS online theo môi trường. Không hardcode IP cũ/localhost trong link ảnh, export, notification deep link hoặc payment callback. Callback gateway/push cần public server, không dùng 192.168.x.x làm IPN và không hứa tunnel chạy khi máy đã tắt.

## 18. Tài liệu và kết quả Codex phải tạo

1. docs/integration_inventory.md: hiện trạng, package/version, SDK, feature có sẵn/mới/điều chỉnh.
2. docs/integration_decisions.md: package chọn/thay/bỏ sau đánh giá, xung đột và cách giải quyết.
3. docs/course_mapping.md: nhóm học phần → package → màn/tính năng → tình huống dùng sâu → test; phân biệt package ngoài danh sách.
4. docs/screens.md: route/class/file/quyền/data source, cập nhật màn mới; không đếm theo số file.
5. docs/external_configuration.md và .env.example: dịch vụ, setup manual, môi trường, trạng thái thiếu config, test và cách bật.
6. docs/acceptance_checklist.md: đã kiểm thử thật/chỉ fixture/chờ credentials/chưa làm, không ghi đồng loạt hoàn thành.
7. README chạy backend/migration/seed/test/Flutter/build đúng layout hiện tại; app demo thật không phụ thuộc USB nếu LAN đang cấu hình.

Các tài liệu dùng tiếng Việt dễ hiểu; config secrets không xuất ra report. Ghi nhận sự phụ thuộc backend/PostgreSQL/Internet, giới hạn hosting free, lưu ảnh/video và worker notifications thực tế.

## 19. Kiểm thử bắt buộc và tính nhất quán UI

### 19.1. Giao diện

- Widget/screenshot QA các thành phần toast/loading/calendar/map/scanner/payment/feedback/PDF/video không dùng theme default lệch màu/font.
- Thành công/lỗi/loading không chồng nhiều thông báo; skeleton hết khi lỗi hoặc timeout; overlay không bị kẹt khi rời trang.
- Màn nhỏ/cỡ chữ lớn/keyboard/foreground-background/tab/back/permission denied hoạt động.
- Chưa cấu hình có đúng vị trí/nội dung/disabled, không crash và không đổi dữ liệu; capabilities API lỗi phân biệt với config thiếu.
- Logo provider có thể giữ màu brand, toàn layout TTTP vẫn nhất quán.

### 19.2. Chức năng

- Giữ tests đăng nhập/quyền/ngày/giá/chống trùng/history cũ.
- Ngày/khách/quote truyền liên tục home-search-detail-login-review và availability cập nhật sau đổi lịch.
- Calendar/timeline phản ánh cùng kỳ lưu trú, ngày trả không bị đánh chiếm đêm.
- Ảnh chọn/cancel/crop/rotate/upload lỗi/duplicate bìa/cache sau update; không lộ avatar/feedback tài khoản khác.
- Import CSV BOM/quotes/duplicate/dòng lỗi/quá kích thước/quyền sai/replay/race không tạo dữ liệu nửa chừng.
- PDF nhiều trang tiếng Việt đọc được, save/share đúng, tổng khớp CSV/dashboard.
- Mất Wi-Fi/API ngủ/HTTP lỗi/JSON lỗi tách đúng; reconnect không tạo lại POST tài chính/đặt phòng.
- Video rời trang/background pause, retry lỗi, URL YouTube sai bị xử lý không crash.
- Inbox/read-all/badge/push dedup/logout đổi tài khoản; schedule local tạo/hủy/đổi và tap cold start đúng quyền.
- Payment missing config, unauthorized, wrong amount, tampered signature, duplicate IPN, return trước IPN, timeout unknown, concurrent methods/manual receipt, late success sau hủy và refund/reconciliation; đúng ledger và báo cáo.
- Test sandbox gateway thật chỉ khi có credentials; fixture signature unit tests không tuyên bố live E2E.
- Map đúng tọa độ cố định, không cần quyền để xem marker; GPS off/denied/distance label/open maps/error tile.
- QR trùng/không hợp lệ/URL lạ/đơn không thuộc quyền không bypass server; quét không tự thực hiện nghiệp vụ.
- Biometric canceled/unavailable/token expired không bypass login; feedback preview/redaction/private storage thật.

Database tests trên test DB riêng; không reset hotel_booking. Chạy flutter analyze, Flutter tests, backend tests liên quan, migration upgrade trên test DB và build Android sau thay đổi native plugin. Báo kết quả thật, không mở rộng test vô hạn sau khi các thay đổi đã được xác minh.

## 20. Thứ tự triển khai

Mốc A: kiểm kê code/theme, capability mechanism, wrappers TTTP, chỉnh UI shared trước khi thêm các SDK.
Mốc B: lịch/carousel/ảnh và states đồng bộ; file import/export/PDF; network/system/video.
Mốc C: inbox/badge/local notifications/permissions, FCM code có conditional init và docs cấu hình.
Mốc D: payment adapters/capability/schema/UI MoMo và VNPAY; transactional ledger/dedup/reconciliation, sandbox tests khi có config.
Mốc E: map tọa độ đã chốt, QR, local auth và feedback.
Mốc F: regression, kiểm tra UI theme trên thiết bị, build và cập nhật docs.

Không chờ cấu hình MoMo/VNPAY/FCM rồi dừng mọi phần còn lại. Hoàn thiện placeholders đúng vị trí và mã tích hợp; tiếp tục các phần độc lập. Không tự bỏ cả một nhóm vì lỗi dependency đầu tiên; tra khả năng thay thế/thích ứng trước.

## 21. Báo cáo cuối

Trả lời: các tính năng đã nối thật, package dùng/thay/bỏ và lý do, UI đã kiểm tra thế nào, migration/tests/build, phần thiếu cấu hình với vị trí nút/biến env và bước người dùng làm thủ công. Không công khai secret hoặc mật khẩu, không nói tài khoản/SDK đã tạo bên ngoài khi chỉ mới viết code.

## 22. Nguồn kỹ thuật để kiểm tra khi triển khai

Codex cần đọc phiên bản tài liệu đúng sản phẩm gateway đang dùng, không lấy tham số/chữ ký từ một sản phẩm khác:

- MoMo IPN: https://developers.momo.vn/v3/docs/payment/api/result-handling/notification/
- MoMo developer portal: https://developers.momo.vn/
- VNPAY cổng thanh toán: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
- VNPAY query/refund: https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr%26refund.html
- Package chính: https://pub.dev/packages/toast_notification ; https://pub.dev/packages/flutter_easyloading ; https://pub.dev/packages/table_calendar ; https://pub.dev/packages/easy_date_timeline
- Ảnh: https://pub.dev/packages/image_picker ; https://pub.dev/packages/cached_network_image ; https://pub.dev/packages/crop_your_image ; https://pub.dev/packages/easy_image_viewer
- Hệ thống: https://pub.dev/packages/connectivity_plus ; https://pub.dev/packages/path_provider ; https://pub.dev/packages/file_picker ; https://pub.dev/packages/video_player
- Notifications: https://pub.dev/packages/flutter_local_notifications ; https://firebase.google.com/docs/cloud-messaging/flutter/client
- Map/scanner/security: https://pub.dev/packages/flutter_osm_plugin ; https://pub.dev/packages/geolocator ; https://pub.dev/packages/mobile_scanner ; https://pub.dev/packages/local_auth ; https://pub.dev/packages/flutter_secure_storage ; https://pub.dev/packages/feedback

Danh sách học phần là căn cứ gắn kiến thức; yêu cầu chính là tính năng TTTP hoạt động nhất quán, an toàn và dễ trình diễn. Không sử dụng AI/Tools để bù số lượng chủ đề.

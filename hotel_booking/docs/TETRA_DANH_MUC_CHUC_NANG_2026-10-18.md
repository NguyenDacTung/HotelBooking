# TETRA HOTEL
## Danh mục chức năng và hướng dẫn nghiệp vụ
Ngày chốt nội dung: 18/10/2026 • Bản ứng dụng Android hiện tại • Dùng API thật/PostgreSQL.

Tài liệu dành cho chủ dự án, người demo và người kiểm thử. Có cả chức năng lớn, chức năng nhỏ, hướng dẫn bấm nút, giới hạn hiện tại và đề xuất. Đây là bản kiểm kê theo mã nguồn và bằng chứng trong dự án, không phải tuyên bố mọi chức năng đã được kiểm thử trên mọi thiết bị.

## Mục lục
1. Cách đọc, mốc thời gian và tình trạng chung.
2. Những chức năng đã có từ trước ngày 18/10/2026.
3. Những chức năng thêm mới hoặc nâng cấp ngày 18/10/2026.
4. Luồng nghiệp vụ và hướng dẫn thao tác từng bước.
5. Chức năng đã có kế hoạch nhưng chưa hoạt động đầy đủ; phần chưa kiểm thử.
6. Đề xuất phát triển tiếp theo, chưa được triển khai theo tài liệu này.
7. Bằng chứng, nguồn đối chiếu và vận hành bản hiện tại.

# 1. Cách đọc và tình trạng chung
## 1.1. Quy ước thời gian
“Có từ trước” là phần đã xuất hiện trong bản TTTP và nhật ký ngày 17/10/2026 hoặc trước đó. “Hôm nay” là ngày 18/10/2026 theo giờ Việt Nam, bao gồm cả đợt sửa QA01–QA11, bổ sung nghiệp vụ và đợt tích hợp hai đặc tả thư viện/đánh giá/Drawer. Không chỉ tính riêng lần sửa mới nhất.

Một chức năng có thể xuất hiện ở cả hai phần: ví dụ đặt phòng đã có từ trước, còn chống lỗi giá, nhận/trả phòng và phụ thu được nâng cấp hôm nay. Mã CU là chức năng nền có trước; mã MOI là phần thêm/sửa hôm nay; mã L là luồng thao tác; mã CHO là phần chưa sẵn sàng; mã DX là đề xuất. Không cộng các dòng thành số màn hình độc lập.

Phân loại thời gian dựa trên nhật ký và tài liệu kiểm chứng của dự án; không có lịch sử Git đầy đủ để khẳng định thời điểm từng dòng mã. Các chức năng nhỏ cùng một nhóm được ghi trong cột chi tiết.

## 1.2. Các mức trạng thái
| Trạng thái | Ý nghĩa |
| --- | --- |
| Đang dùng | Đã có mã, có đường thao tác trong app/API hiện tại; không mặc định đã thử mọi tổ hợp. |
| Đã thử điện thoại | Có bằng chứng thao tác tiêu biểu trên SM A135F. Chi tiết ở phần 7. |
| Chờ cấu hình | Có giao diện/mã tích hợp nhưng thiếu tài khoản dịch vụ, khóa hoặc nội dung hợp lệ. |
| Chưa nghiệm thu thiết bị | Không đồng nghĩa không hoạt động; chưa kiểm thử trọn luồng trên điện thoại thật. |
| Đề xuất | Chưa có chức năng hoàn chỉnh; chỉ là phương án để chủ dự án xem xét. |

## 1.3. Tình trạng đăng nhập: cần phân biệt rõ
Đăng nhập thông thường bằng email và mật khẩu đang hoạt động với backend/PostgreSQL thật. Đã thử bằng tài khoản khách, lễ tân và quản trị. Không xếp toàn bộ “đăng nhập” vào nhóm chưa hoạt động.

Đăng nhập Google/Facebook và liên kết hai nhà cung cấp này đang chờ cấu hình OAuth. Quên mật khẩu có luồng email nhưng chưa có SMTP để gửi thư thật. Cập nhật tiếp theo ngày 18/10: đăng nhập vân tay đã chuyển sang nút ở màn đăng nhập. Sau khi bật một lần cho tài khoản/thiết bị, có thể đăng nhập không nhập email/mật khẩu; server cấp phiên mới khi chữ ký thiết bị hợp lệ. Không còn bước quét để vào phiên sau mật khẩu.

## 1.4. Vai trò và cách mở chức năng
| Vai trò | Thanh dưới | Menu ba gạch và phạm vi |
| --- | --- | --- |
| Khách vãng lai | Trang chủ; Tìm phòng; Lịch sử; Tài khoản | Thông tin khách sạn, Cài đặt; chưa đăng nhập thì không được tạo/xem đơn riêng. |
| Khách đã đăng nhập | Trang chủ; Tìm phòng; Lịch sử; Tài khoản | Thêm Đánh giá của tôi, Góp ý và báo lỗi; chỉ truy cập dữ liệu cá nhân. |
| Nhân viên/lễ tân | Yêu cầu đặt phòng; Tình trạng phòng; Tài khoản | Lịch phòng, Quét mã đặt phòng, Thông tin khách sạn, Góp ý và báo lỗi, Cài đặt. |
| Quản trị/quản lý | Tổng quan; Đặt phòng; Báo cáo; Tài khoản | Thêm Loại phòng, Phòng, Tiện nghi, Lịch tạm ngừng, Quản lý tài khoản, Quản lý đánh giá, Phản hồi khách hàng, Nhập phòng từ CSV; có quyền nghiệp vụ nhân viên. |

Nút chỉ hiện hoặc cho bấm khi đúng vai trò và trạng thái. Backend vẫn kiểm tra quyền khi gửi request; biết đường dẫn hoặc nhìn thấy mã QR không cấp quyền quản trị.

# 2. Chức năng đã có từ trước ngày 18/10/2026
## 2.1. Tài khoản, phiên và giao diện chung
| Mã | Chức năng | Chi tiết lớn và nhỏ đã có |
| --- | --- | --- |
| CU01 | Đăng ký khách hàng | Họ tên, email, mật khẩu, nhập lại mật khẩu; kiểm tra đầu vào và email trùng. Điện thoại hồ sơ có thể để trống. |
| CU02 | Đăng nhập và đăng xuất | Email/mật khẩu; ẩn/hiện mật khẩu; báo lỗi xác thực; đăng xuất phiên hiện tại. |
| CU03 | Khôi phục phiên | Lưu token ở secure storage; mở lại app lấy hồ sơ; token hết hạn/không hợp lệ yêu cầu đăng nhập lại. |
| CU04 | Phân quyền và sở hữu | Khách/lễ tân/quản trị; khách không đọc hoặc sửa phiếu của người khác; tài khoản bị khóa hoặc đổi quyền được kiểm tra ở server. |
| CU05 | Hồ sơ | Xem email/vai trò; sửa họ tên/điện thoại; lưu hồ sơ và tải lại thông tin. Avatar là phần mới hôm nay. |
| CU06 | Đổi mật khẩu | Nhập mật khẩu hiện tại, mật khẩu mới, xác nhận; kiểm tra và thu hồi phiên theo cơ chế server. Không cần email khôi phục để đổi khi biết mật khẩu hiện tại. |
| CU07 | Khung tài khoản liên kết | Có màn xem trạng thái/liên kết; việc đăng nhập ngoài hoàn chỉnh và cấu hình dịch vụ được bổ sung hôm nay. |
| CU08 | Trạng thái giao diện | Loading, rỗng, lỗi, thử lại, tải thêm/phân trang và làm mới; không coi mọi lỗi HTTP/JSON là lỗi mất mạng. |
| CU09 | Giao diện khách đã thiết kế | Banner tự chuyển; kính lúp mở/ẩn form tìm kiếm và cuộn xuống; lưới phòng đề xuất 2 thẻ/hàng; thanh dưới xanh/vàng, nhãn Lịch sử. |
| CU10 | Chế độ demo riêng | Bản demo chỉ xem mẫu và có nhận diện riêng; không trộn mẫu vào dữ liệu API thật. Bản cài hiện tại DEMO_MODE=false. |

## 2.2. Khách hàng và đặt phòng
| Mã | Chức năng | Chi tiết lớn và nhỏ đã có |
| --- | --- | --- |
| CU11 | Danh mục/tìm phòng | Ngày nhận/trả, số khách, loại phòng, khoảng giá; danh sách kết quả có phân trang. |
| CU12 | Xem phòng | Số phòng, loại, sức chứa, giá, mô tả, tiện nghi và ảnh; có xem ảnh lớn. Vị trí lưu ảnh được chuyển sang từng phòng hôm nay. |
| CU13 | Đề xuất công khai | Khách vãng lai và đã đăng nhập đều xem; thẻ có ảnh/số phòng/loại/giá; ẩn danh sách khi request lỗi. Quy tắc chiếm dụng được làm rõ hôm nay. |
| CU14 | Báo giá trước đặt | Tính số đêm, giá đêm và tổng; cập nhật lại báo giá; giá chính thức do backend quyết định. |
| CU15 | Tạo yêu cầu đặt | Chọn một phòng vật lý; ngày, số khách, liên hệ, ghi chú; xác nhận gửi và xem kết quả. |
| CU16 | Lịch sử đặt phòng | Danh sách đơn của mình; lọc trạng thái/ngày; mở chi tiết, xem trạng thái và lịch sử thay đổi. |
| CU17 | Hủy trước nhận phòng | Hủy đơn của mình khi còn được phép; cập nhật lịch giữ phòng và lưu lịch sử, không xóa phiếu. Chính sách phí/hạn được mở rộng hôm nay. |
| CU18 | Chống đặt trùng | Kiểm tra phòng/ngày/sức chứa; khóa và ràng buộc PostgreSQL chống hai người cùng chiếm một khoảng lịch. |

## 2.3. Nhân viên, quản trị và tài chính nền
| Mã | Chức năng | Chi tiết lớn và nhỏ đã có |
| --- | --- | --- |
| CU19 | Danh sách nghiệp vụ | Lễ tân/quản trị xem yêu cầu; lọc trạng thái/ngày, tải thêm và mở chi tiết khách/liên hệ. |
| CU20 | Xác nhận/từ chối | Xử lý yêu cầu chờ, ghi người thực hiện/thời điểm/lịch sử và thông báo. Hôm nay sửa trường hợp cùng ngày và lý do tùy chọn. |
| CU21 | Tình trạng phòng | Xem/lọc theo tầng, loại, vận hành; thay đổi vệ sinh/bảo trì theo quyền, có lịch sử. Chặn chuyển sai khi đang ở được hoàn thiện hôm nay. |
| CU22 | Loại phòng | Thêm/sửa tên, giá, sức chứa, mô tả, diện tích/số giường; kinh doanh/ngừng theo điều kiện. |
| CU23 | Phòng vật lý | Thêm/sửa số phòng, loại, tầng, ghi chú; trạng thái kinh doanh; bảo vệ dữ liệu đang được tham chiếu. |
| CU24 | Tiện nghi | Thêm/sửa danh mục, biểu tượng; gắn/bỏ tiện nghi theo loại phòng. |
| CU25 | Quản lý ảnh | Upload, sắp xếp, đặt ảnh bìa, xóa có xác nhận; xác thực định dạng/dung lượng. Hôm nay chuyển ảnh sang từng phòng và thêm crop/preview. |
| CU26 | Lịch tạm ngừng | Chọn phòng/khoảng ngày; kiểm tra xung đột với đặt phòng; điều chỉnh hiệu lực thay vì làm mất lịch sử. |
| CU27 | Tài khoản nội bộ | Quản trị tạo nhân viên, tìm tên/email, lọc vai trò/khóa; xem/sửa hồ sơ, đổi quyền và khóa/mở khóa. |
| CU28 | Bảo vệ quyền quản trị | Không tự khóa/hạ quyền sai điều kiện; không loại admin cuối; có audit trước/sau. Lý do bắt buộc cũ được bỏ hôm nay. |
| CU29 | Sổ thu/hoàn | Ghi nhận thu thực tế, tiền mặt/chuyển khoản, tham chiếu; admin hoàn có giao dịch gốc; chống trùng bằng request ID. Hôm nay nâng độ an toàn khi mất mạng và gắn hóa đơn phụ thu. |
| CU30 | Báo cáo quản lý | Tổng quan, lọc thời gian/nhóm kỳ, biểu đồ/bảng, tiền thu/hoàn/ròng, xuất CSV/PDF server. Xem PDF ngay trong app là phần mới. |
| CU31 | Thông báo trong app | Danh sách inbox, badge chưa đọc, xem/đánh dấu đọc, tải thêm; không đồng nghĩa push nền đã chạy. |
| CU32 | Nhắc lịch cơ bản | Có cơ chế thông báo cục bộ cho nhận phòng; hôm nay bổ sung giờ chọn và ID ổn định theo đơn. |

## 2.4. Hạ tầng sẵn có
| Mã | Chức năng | Chi tiết |
| --- | --- | --- |
| CU33 | Backend thật | FastAPI, API danh mục/nghiệp vụ, health và health/database, phân loại lỗi có status/path/code. |
| CU34 | PostgreSQL và migration | Model/schema, khóa ngoại/index/check/exclusion; migration Alembic, không dùng SQLite thay thế. |
| CU35 | Seed và kiểm thử an toàn | Seed có kiểm tra trùng; hotel_booking_test riêng cho PostgreSQL/cạnh tranh; bảo vệ database chính. |
| CU36 | Dùng qua Wi-Fi | API LAN, backend lắng nghe LAN, firewall mạng riêng; không cần USB nếu mạng/máy tính/backend hoạt động. Có PowerShell khởi động. |
| CU37 | Icon Android | Launcher icon từ tài sản đã chọn, adaptive icon có khoảng an toàn; applicationId giữ nguyên khi cập nhật. Nhãn TTTP được đổi hôm nay. |

# 3. Thêm mới hoặc nâng cấp ngày 18/10/2026
## 3.1. Đợt QA01–QA11 và nghiệp vụ lưu trú
| Mã | Phần thêm/sửa | Chức năng nhỏ và tác động |
| --- | --- | --- |
| MOI01 | Xử lý đơn cùng ngày | Cho xác nhận/từ chối/hủy đúng ngày đến khi chưa nhận phòng, không chặn chỉ vì là ngày hiện tại. |
| MOI02 | Thu/hoàn khi lỗi mạng | Không dùng tổng cũ sau tải lỗi; giữ nguyên nội dung/UUID giao dịch chưa rõ kết quả; kiểm tra/thử lại giao dịch cũ thay vì tạo thu trùng. |
| MOI03 | Đồng bộ tìm kiếm | Ô số khách và dữ liệu tìm kiếm đồng bộ khi form còn tồn tại; không gửi lại điều kiện cũ ngoài ý muốn. |
| MOI04 | Kiểm tra số điện thoại | Client/server kiểm tra số Việt Nam/quốc tế; chặn abc/số quá ngắn; không ép đổi dữ liệu cũ hàng loạt. |
| MOI05 | Cài đặt dễ đọc | Sửa nền Material, SwitchListTile và chữ dài/cỡ chữ lớn; tránh lỗi giao diện màn hẹp. |
| MOI06 | Nhận phòng thực tế | Phiếu đã xác nhận, đúng ngày đến; phòng sẵn sàng, không còn khách trước; lưu thời điểm thực nhận, chuyển Đang ở. |
| MOI07 | Yêu cầu trả/hóa đơn | Khách hoặc nhân viên yêu cầu; tính tiền phòng/phụ thu/số đã thu/hoàn/còn nợ; có cập nhật hóa đơn trước bàn giao. |
| MOI08 | Hoàn tất trả phòng | Chỉ nhân viên/quản trị; chặn khi còn cần thu/hoàn; lưu thời điểm trả, kết thúc đơn, chuyển phòng sang Cần dọn dẹp. |
| MOI09 | Vệ sinh sau trả | Cần dọn dẹp → Đang dọn dẹp → Sẵn sàng; không ép phòng đang có khách sang dọn/bảo trì. |
| MOI10 | Đặt hộ khách | Nhập email/tên/điện thoại/số khách/ngày, tìm phòng và tạo; email mới không tự được cấp mật khẩu chung. |
| MOI11 | Hủy hộ/đổi lịch | Hủy trước nhận; đổi phòng/ngày/số khách, xem giá mới và ghi audit. Không viết lại đơn đã có thu/hoàn. |
| MOI12 | Đã đặt trước/đang ở | Tách Đã đặt trước và Đang sử dụng; khách quá ngày trả nhưng chưa trả thực tế vẫn đang sử dụng; đề xuất loại cả hai nhóm. |
| MOI13 | Giữ chỗ có hạn | Phiếu mới chờ xác nhận có hạn giữ; worker giải phóng; không tự hết hạn hồi tố các phiếu cũ. |
| MOI14 | Hủy sát ngày/no-show | Snapshot chính sách, phí một đêm theo điều kiện; lễ tân xác nhận Khách không đến sau ngày đến. Không tự thu tiền ngân hàng. |
| MOI15 | Chốt giá/chính sách | Giá, mốc giờ và chính sách được lưu với phiếu; thay cấu hình sau này không tự đổi phiếu cũ. |
| MOI16 | Phụ thu sớm/muộn | Nhận sớm, trả trễ, quá ngày; tính theo mốc Việt Nam và mã tự động chống cộng hai lần. |
| MOI17 | Phụ thu phát sinh | Minibar, giặt là, giường phụ, hư hỏng, khác; nhập căn cứ/nội dung, số lượng/đơn giá; quản lý hủy khoản phí có lịch sử. |
| MOI18 | Báo cáo gồm phụ thu | Công nợ/tổng hóa đơn/thực thu/hoàn đối chiếu tiền phòng và phí; không chỉ xem giá phòng ban đầu. |
| MOI19 | Sửa dialog nghiệp vụ | Chờ dialog đóng xong mới hủy controller, tránh request thành công nhưng giao diện đỏ. |

## 3.2. Danh mục, ảnh và nhận diện
| Mã | Phần thêm/sửa | Chức năng nhỏ và tác động |
| --- | --- | --- |
| MOI20 | Danh mục đa dạng | Thêm 10 loại và 10 phòng; sau seed có 13 loại, 22 phòng. Gồm Single/Double/Twin, Superior, Deluxe King/Twin, Family Quad, Junior/Executive Suite cùng loại cũ. |
| MOI21 | Ảnh thuộc từng phòng | Loại phòng không quản lý ảnh; thêm/sửa phòng đi tới ảnh của chính phòng đó; giữ dữ liệu ảnh cũ để truy vết. |
| MOI22 | Thay ảnh danh mục | Danh mục chính có 39 ảnh chụp thật có nguồn/giấy phép; không phải ảnh AI. Không khẳng định là ảnh được khảo sát tại một cơ sở khách sạn cụ thể. |
| MOI23 | Gỡ giải thích đồ án | Bỏ nội dung giải thích kỹ thuật/ảnh minh họa khỏi giao diện khách theo yêu cầu. |
| MOI24 | Đổi tên TETRA | Tên trong app TETRA; nhãn launcher TETRA Hotel; giữ applicationId và khóa kỹ thuật/email cũ để tương thích. |
| MOI25 | Lý do tùy chọn | Áp dụng hủy/từ chối/đổi phòng/quyền/khóa/hoàn/tạm ngừng/ẩn đánh giá/hủy phí. Nhận/trả phòng bỏ dialog hỏi lý do. Nội dung khoản phát sinh, số tiền và liên hệ vẫn có kiểm tra. |

## 3.3. Đánh giá và điều hướng
| Mã | Phần mới | Chức năng nhỏ và trạng thái |
| --- | --- | --- |
| MOI26 | Đánh giá lưu trú | Chỉ khách sở hữu đơn đã hoàn tất và có thời điểm trả thật; chọn 1–5 sao, nhận xét tối đa 1.000 ký tự; không chọn sẵn 5 sao; một đơn một đánh giá. |
| MOI27 | Đánh giá công khai | Điểm trung bình/số lượt/phân bố sao, lọc sao/sắp xếp/phân trang, xác minh đã lưu trú; ẩn thông tin nhạy cảm. |
| MOI28 | Điểm trên thẻ phòng | Thẻ/đề xuất/chi tiết có điểm hoặc Chưa có đánh giá; thống kê chỉ tính các đánh giá đang hiện. |
| MOI29 | Đánh giá của tôi | Danh sách riêng, cả đánh giá bị ẩn; xem lý do nếu quản trị đã nhập. Không có luồng khách tùy ý xóa/sửa sao đã gửi. |
| MOI30 | Kiểm duyệt đánh giá | Quản trị lọc phòng/loại/sao/ngày/hiện ẩn; ẩn/hiện, lý do tùy chọn, có audit; không sửa sao/nội dung thay khách. |
| MOI31 | Drawer dùng chung | Header avatar/tên/email/vai trò; mở hồ sơ hoặc đăng nhập; menu đúng vai trò, cuộn và đăng xuất; giữ thanh dưới hiện có. |
| MOI32 | Chặn route riêng | Chặn route quản trị/nhân viên trước dựng màn; server vẫn xác thực lại; đăng xuất đưa về gốc và dọn dữ liệu phiên riêng. |
| MOI33 | Thông báo giao diện | Hàng đợi SnackBar tránh chồng; EasyLoading khi nhập CSV và luôn đóng sau tác vụ. Giữ badge Material có sẵn. |

## 3.4. Tích hợp công cụ và cài đặt
| Mã | Phần mới | Chức năng nhỏ và trạng thái |
| --- | --- | --- |
| MOI34 | Avatar | Chọn thư viện/chụp, căn/cắt, xem trước, xác nhận upload, URL ảnh mới; có khôi phục ảnh picker dang dở. Đã nghiệm thu chọn ảnh thư viện → kéo/reset/căn lại → preview/lưu trên SM A135F, sửa lệch crop bằng tọa độ ảnh hiển thị. Camera/hủy tiến trình còn chưa đủ. |
| MOI35 | Crop ảnh phòng | Dùng chung chuỗi chọn/chụp → căn → xem → xác nhận; giới hạn 5 MiB; hủy không tự gửi ảnh. |
| MOI36 | Lịch phòng | Chọn phòng, lịch tháng và thanh ngày đồng bộ; hiển thị phiếu giữ/lịch ngừng, ngày trả không chiếm đêm; chạm đơn mở chi tiết, quay lại tải lại lịch. |
| MOI37 | QR của khách | Mã tham chiếu TETRA:1:UUID trong chi tiết đơn, không chứa mật khẩu/token/thông tin khách. |
| MOI38 | Tra cứu QR lễ tân | Camera hoặc nhập tay; chống đọc lặp, tắt camera khi ra nền, đèn pin/đổi camera; không tự nhận phòng/thu tiền. Nhập tay đã thử điện thoại; quét camera chưa nghiệm thu. |
| MOI39 | Nhập phòng CSV | Chọn CSV UTF-8/BOM, tối đa 2 MiB/1.000 dòng; preview/lỗi từng dòng; xác nhận nguyên lô, chống replay/cạnh tranh; không ghi đè phòng có sẵn. |
| MOI40 | PDF trong app | Xem báo cáo server bằng pdfrx; Lưu hoặc chia sẻ qua Android; tệp tạm riêng được dọn khi đăng xuất. Đã render thực tế. |
| MOI41 | Thông tin khách sạn | Trang thông tin/liên hệ được quản trị cấu hình; không bịa hotline/website; trường chưa có thì không hiện nút rỗng. |
| MOI42 | Bản đồ | OSM với ghim tọa độ theo đặc tả; attribution, sửa lỗi tile 403; đã thử bản đồ trên SM A135F. |
| MOI43 | Vị trí và chỉ đường | Bấm mới xin vị trí; tính khoảng cách đường thẳng; từ chối quyền vẫn xem được ghim; mở chỉ đường ngoài. Chưa nghiệm thu đầy đủ quyền/GPS thực tế. |
| MOI44 | Video giới thiệu | URL HTTPS trực tiếp được cấu hình; phát/dừng/tua/toàn màn hình, dừng khi ra nền; chưa có video thật nên ẩn. |
| MOI45 | Góp ý/báo lỗi | Nội dung tối đa 4.000 ký tự; chụp/chú thích chỉ trang góp ý, xem/bỏ ảnh; thông tin thiết bị chỉ gửi nếu chọn; ảnh lưu riêng có xác thực. Text đã thử điện thoại. |
| MOI46 | Xử lý góp ý | Quản trị xem nội dung/ảnh riêng; Tiếp nhận → Đang xử lý → Đã xử lý; có audit và phân trang. Đã thử cập nhật trạng thái. |
| MOI47 | Giờ nhắc cá nhân | Chọn giờ ngày trước khi đến; ID ổn định theo đơn/tài khoản, đồng bộ/hủy khi đổi phiên hoặc đơn; phụ thuộc quyền/thời gian chạy nền. |
| MOI48 | Đăng nhập bằng vân tay | Bật một lần trong Cài đặt, xác nhận mật khẩu và vân tay để đăng ký. Lần sau bấm vân tay ở màn đăng nhập, không nhập email/mật khẩu; ký challenge Keystore để server cấp JWT mới. Bỏ khóa phiên sau 30 giây. Tắt để thu hồi; xem báo cáo nghiệm thu hồ sơ/vân tay mới. |
| MOI49 | Cài đặt công khai | Admin sửa điện thoại/email/website, URL và chú thích video trong app, không sửa khóa bí mật; mọi tài khoản xem trạng thái cấu hình dịch vụ. Tên TETRA không có ô đổi tên tại màn này. |
| MOI50 | Capabilities | Phân biệt Đang tải, Không tải được trạng thái và Chưa cấu hình; không in khóa bí mật; UI vô hiệu nút dịch vụ chưa sẵn sàng. |

## 3.5. Dịch vụ ngoài, an toàn tiền và hạ tầng hôm nay
| Mã | Phần đã viết | Tình trạng và giới hạn |
| --- | --- | --- |
| MOI51 | Khôi phục qua email | Mã băm, hết hạn/dùng một lần, giới hạn thử; luồng nhập mã/mật khẩu mới. Chưa có SMTP để gửi email thật. |
| MOI52 | Google/Facebook | Hoàn thiện luồng tích hợp/cấu hình và kiểm tra readiness client/server trên khung xác minh/liên kết đã có; không tự gộp do trùng email. Chưa có OAuth để chạy thật. |
| MOI53 | Push FCM | Thiết bị gắn tài khoản/phiên, outbox bền vững, retry/backoff và chống hiển thị trùng; không giữ transaction DB khi gọi dịch vụ. Chưa có Firebase để E2E. |
| MOI54 | MoMo/VNPAY | Nút Thanh toán online, chọn cổng, lưu yêu cầu, mở HTTPS, xem/làm mới/kiểm tra kết quả; adapter chữ ký/callback/query. Chờ merchant/public HTTPS và khóa. |
| MOI55 | Bảo vệ kết quả tiền | UUID idempotency, một yêu cầu hoạt động/đơn, callback xác minh merchant/số tiền/chữ ký; trang trình duyệt quay về không tự kết luận thành công. |
| MOI56 | Tách sandbox | Giao dịch thử có nhãn; không giảm công nợ thật, không tính doanh thu, không được hoàn bằng tiền thật. Chỉ mới kiểm thử fixture. |
| MOI57 | Hạn chế upload | Cấu hình lưu media bền vững; chưa cấu hình thì không nhận ảnh, vẫn cho gửi góp ý text; ảnh góp ý không public dưới uploads. |
| MOI58 | Migration và sao lưu | Nâng tới 0007 có dump và đối chiếu cột/dòng cũ; thêm review, avatar, import batch, feedback, settings, payment attempt, retry push. Không reset DB chính. |
| MOI59 | Tương thích Android | Sửa KGP cho file_picker/OSM, giữ minSdk 24 bằng OSM 1.4.6; FlutterFragmentActivity hỗ trợ local_auth; quyền camera/vị trí/biometric theo tính năng. |
| MOI60 | Kiểm thử nâng cấp | 89 ca backend PostgreSQL khác nhau; 34 Flutter test lượt đầy đủ cuối; analyze sạch; build/cài và QA thật trên SM A135F, dùng DB test riêng. |

# 4. Luồng nghiệp vụ và hướng dẫn thao tác
## 4.1. Quy tắc chung trước khi thao tác
Chạm menu ba gạch góc trên trái để mở Drawer. “Mở đơn” nghĩa là chạm thẻ phòng/đơn trong danh sách. Những màn dài có thể phải cuộn xuống mới thấy nút. Nếu không thấy nút, kiểm tra vai trò, trạng thái đơn, ngày đến, công nợ và trạng thái vận hành; không tự đổi dữ liệu DB để ép nút xuất hiện.

Tất cả lý do là tùy chọn. Bấm xác nhận với lý do rỗng vẫn hợp lệ khi các điều kiện khác đúng. Tuy nhiên số tiền, họ tên/liên hệ cần thiết, ngày, số khách và nội dung phụ thu không trở thành tùy chọn vì thay đổi này.

### L01. Mở ứng dụng và kiểm tra kết nối
Điều kiện: máy tính/backend/PostgreSQL đang chạy; điện thoại truy cập được cùng LAN.
1. Trên máy tính mở PowerShell ở thư mục có pubspec.yaml, chạy lệnh ở phần 7.3.
2. Trên điện thoại mở TETRA Hotel; xem Trang chủ và thẻ phòng đề xuất.
3. Nếu lỗi, mở trình duyệt điện thoại tới http://192.168.31.112:8000/health/db; chỉ kết luận kết nối DB khi trả status ok/database connected.
4. Quay lại app, làm mới/thử lại; không cần tạo adb reverse. Nếu IP máy tính đổi, bản LAN cần cập nhật địa chỉ API khi build.

### L02. Đăng ký tài khoản khách
1. Bấm Tài khoản ở thanh dưới → Đăng nhập / Đăng ký.
2. Chuyển sang biểu mẫu đăng ký bằng liên kết đăng ký trên màn xác thực.
3. Nhập Họ tên, Email, Mật khẩu, Nhập lại mật khẩu; Điện thoại có thể để trống.
4. Bấm Đăng ký. Email phải chưa được dùng; mật khẩu tối thiểu 8 ký tự.
5. Khi thành công, kiểm tra màn tài khoản/trang chủ. Nếu app yêu cầu đăng nhập thì dùng email/mật khẩu vừa tạo. Vai trò khách không tự được nâng lên nhân viên.

### L03. Đăng nhập, đăng xuất và mở lại
1. Tài khoản → Đăng nhập / Đăng ký → nhập Email và Mật khẩu → Đăng nhập.
2. Kiểm tra giao diện theo vai trò: khách thấy Trang chủ/Lịch sử; lễ tân thấy Yêu cầu đặt phòng; admin thấy Tổng quan/Báo cáo.
3. Đóng/mở lại app: phiên còn hạn sẽ được kiểm tra hồ sơ và khôi phục; phiên hết hạn phải đăng nhập lại.
4. Để thoát, vào Tài khoản hoặc menu → Đăng xuất. Không gửi mật khẩu/token vào chat hay log để kiểm tra.

### L04. Sửa hồ sơ và đổi mật khẩu
1. Tài khoản → sửa họ tên/điện thoại → Lưu hồ sơ.
2. Mở menu → Cài đặt → Đổi mật khẩu (cũng có điểm vào từ trang tài khoản).
3. Nhập Mật khẩu hiện tại, Mật khẩu mới và nhập lại → Đổi mật khẩu và đăng nhập lại.
4. Nếu hệ thống thu hồi phiên/yêu cầu đăng nhập lại, đăng nhập bằng mật khẩu mới; không dùng khôi phục email khi đã biết mật khẩu hiện tại.

### L05. Chọn/chụp avatar và ảnh phòng
1. Với avatar: Tài khoản → Đổi ảnh đại diện. Với ảnh phòng: admin → menu Phòng → mở phòng/sửa → Chọn / quản lý ảnh phòng.
2. Chọn Thư viện ảnh hoặc Chụp ảnh; cấp quyền nếu muốn sử dụng chức năng đó.
3. Căn vùng ảnh → Xem ảnh đã căn.
4. Xem trước → Dùng ảnh này để upload; quay lại/căn lại nếu chưa đúng.
5. Chờ lưu xong và kiểm tra ảnh. Nếu có Ảnh chưa lưu từ lần trước, chọn Xem ảnh khôi phục hoặc Chọn ảnh khác. Chưa kiểm thử đủ chuỗi native này trên điện thoại.

### L06. Xem đề xuất, tìm kiếm và xem phòng
1. Trang chủ → lướt lưới Phòng đề xuất; chạm thẻ để mở chi tiết.
2. Muốn chọn điều kiện, bấm kính lúp cạnh Chào mừng đến TETRA; trang cuộn xuống và mở form giữa banner với lưới.
3. Chọn ngày nhận/ngày trả, số khách và điều kiện hiện có → bấm nút tìm phòng. Hoặc mở tab Tìm phòng.
4. Xem danh sách; đổi loại/giá theo bộ lọc; tải thêm nếu có.
5. Mở phòng → xem ảnh, tiện nghi, giá và đánh giá. Bấm lại kính lúp để ẩn form, nội dung đã nhập được giữ.
6. Nếu mất kết nối, lưới đề xuất ẩn; không hiểu là khách sạn đã hết tất cả phòng.

### L07. Đặt phòng của khách
1. Tìm phòng theo L06 → mở phòng → bấm nút đặt phòng để sang màn xem lại/báo giá.
2. Đăng nhập nếu được yêu cầu. Chọn ngày/số khách; kiểm tra số phòng, số đêm, giá, chính sách nhận/trả và phụ thu.
3. Nhập Tên liên hệ và Điện thoại liên hệ; ghi chú tùy chọn.
4. Bấm Cập nhật báo giá nếu thay điều kiện; kiểm tra báo giá còn khả dụng.
5. Bấm Xác nhận đặt phòng; xem kết quả rồi vào Lịch sử kiểm tra phiếu Chờ xác nhận.
6. Nếu chưa rõ kết quả do timeout, dùng Kiểm tra Đặt phòng của tôi; không bấm tạo nhiều đơn liên tiếp. Nếu giá thay đổi, xem giá mới và xác nhận lại.

### L08. Xem/hủy đơn của mình
1. Khách → Lịch sử → chọn bộ lọc trạng thái/ngày khi cần → mở đơn.
2. Đọc lịch sử, trạng thái, hạn giữ, hóa đơn và liên hệ.
3. Nếu còn được hủy, bấm Hủy đặt phòng → để trống hoặc nhập lý do → Xác nhận.
4. Kiểm tra Đã hủy và khoản cần thu/hoàn nếu có. Hủy không tự chuyển tiền hoàn về tài khoản ngân hàng.

### L09. Lễ tân xác nhận hoặc từ chối
1. Đăng nhập lễ tân: Yêu cầu đặt phòng; admin: tab Đặt phòng.
2. Lọc Chờ xác nhận → mở đơn → kiểm tra ngày, phòng, số khách và liên hệ.
3. Bấm Xác nhận đặt phòng để duyệt, hoặc Từ chối → lý do tùy chọn → Xác nhận trong dialog.
4. Tải lại, kiểm tra trạng thái/lịch sử. Cùng ngày đến vẫn xử lý được trước nhận; phiếu đã hết hạn không được xác nhận như còn hiệu lực.

### L10. Tạo đặt phòng hộ khách
1. Lễ tân/admin mở danh sách đặt phòng → bấm biểu tượng có tooltip Đặt phòng hộ khách trên thanh trên.
2. Nhập Email khách hàng, Tên liên hệ, Điện thoại liên hệ, Số khách; chọn ngày nhận/trả.
3. Bấm Tìm phòng còn trống → chọn phòng → kiểm tra báo giá/chính sách.
4. Bấm Tạo yêu cầu đặt phòng; mở đơn vừa tạo và xác nhận khi đúng nghiệp vụ.
5. Email mới được tạo hồ sơ chưa có mật khẩu; không phát mật khẩu mặc định. Cần SMTP để khách dùng khôi phục email tự đặt mật khẩu.

### L11. Đổi phòng/ngày hoặc hủy hộ
1. Lễ tân/admin mở đơn Chờ xác nhận/Đã xác nhận trước nhận.
2. Bấm Đổi phòng / ngày → chọn phòng/ngày/số khách mới → kiểm tra giá mới → lý do tùy chọn.
3. Bấm Xác nhận giá và lịch mới; kiểm tra đơn/lịch sử.
4. Nếu đã có giao dịch thu/hoàn, không sửa trực tiếp: đối chiếu/hoàn theo quyền và tạo phiếu thay thế theo nghiệp vụ.
5. Để hủy hộ, bấm Hủy hộ khách → lý do tùy chọn → Xác nhận; kiểm tra tiền phải hoàn/thu, không xóa sổ tiền.

### L12. Nhận phòng
1. Đúng ngày đến, lễ tân/admin mở đơn Đã xác nhận.
2. Kiểm tra khách/liên hệ, phòng không còn người ở trước và vận hành Sẵn sàng.
3. Bấm Nhận phòng; không có ô bắt nhập lý do.
4. Kiểm tra Đang ở, thời điểm nhận và phụ thu nhận sớm nếu có. Không nhận chỉ vì đã có đặt trước khi phòng chưa sẵn sàng.

### L13. Thêm/hủy phụ thu
1. Lễ tân/admin mở đơn Đang ở hoặc Chờ thanh toán → Thêm phụ thu.
2. Chọn Minibar/Giặt là/Giường phụ/Hư hỏng/Khác; nhập Nội dung / căn cứ, Đơn giá và Số lượng.
3. Bấm Ghi nhận → kiểm tra từng dòng và tổng hóa đơn.
4. Admin muốn miễn/hủy: bấm biểu tượng Hủy phụ thu trên dòng → để trống hoặc nhập lý do → Xác nhận.
5. Khoản phí được đánh dấu Đã hủy và giữ lịch sử; không xóa dấu vết. Phí tự động sớm/muộn tính theo chính sách, không tự thêm tay lần nữa cho cùng khoản.

### L14. Yêu cầu trả, thu tiền và hoàn tất trả
1. Khách vào Lịch sử hoặc nhân viên mở đơn Đang ở → Yêu cầu trả phòng.
2. Kiểm tra hóa đơn/phụ thu; khi cần bấm Cập nhật hóa đơn trả phòng.
3. Lễ tân/admin mở Thu / hoàn tiền; thực hiện thu theo L15 và hoàn theo L16 nếu có khoản cần hoàn.
4. Sau khi đối chiếu đủ tiền, nhân viên bấm Hoàn tất trả phòng. Không hỏi lý do.
5. Nếu giờ bàn giao làm tăng phụ thu/còn nợ, xem hóa đơn mới và xử lý khoản chênh trước khi hoàn tất.
6. Thành công: đơn Đã trả phòng; phòng Cần dọn dẹp; khách đủ điều kiện đánh giá. Giải phóng lịch không có nghĩa phòng đã sạch.

### L15. Ghi thu tiền thực tế và xử lý chưa rõ kết quả
1. Lễ tân/admin mở đơn → Thu / hoàn tiền → Ghi nhận thu tiền.
2. Kiểm tra số còn phải thu mới tải; nhập Số tiền (VND), chọn Tiền mặt/Chuyển khoản; mã tham chiếu và ghi chú tùy chọn.
3. Chỉ sau khi đã nhận tiền thực tế, bấm Xác nhận ghi nhận.
4. Kiểm tra giao dịch trong sổ và số dư; không coi “đã bấm nút” là đã thu thành công.
5. Nếu timeout/kết quả không rõ, bấm Kiểm tra / thử lại giao dịch cũ; app giữ UUID/nội dung cũ. Không ghi thêm giao dịch mới cho cùng lần thu.

### L16. Hoàn tiền thủ công
1. Admin mở Thu / hoàn tiền của đơn → chọn giao dịch thu gốc → Ghi nhận hoàn cho khoản thu này.
2. Kiểm tra số còn được hoàn và khoản cần hoàn; nhập số tiền, tham chiếu/ghi chú hoặc lý do tùy chọn.
3. Hoàn tiền thực tế ngoài app, rồi Xác nhận ghi nhận; kiểm tra sổ tiền và số dư.
4. App không tự chuyển khoản ngân hàng. Không dùng tiền thật hoàn giao dịch sandbox; hoàn gateway tự động chưa bật.

### L17. Hết hạn và khách không đến
1. Với phiếu Chờ xác nhận mới, xem Giữ chỗ đến trong chi tiết; quá hạn sẽ được xử lý Hết hạn và giải phóng lịch theo worker/kiểm tra server.
2. Với Đã xác nhận nhưng khách không đến sau ngày nhận, lễ tân/admin mở đơn → Khách không đến.
3. Ghi chú tùy chọn → Xác nhận; kiểm tra trạng thái và phí theo chính sách chốt.
4. Không dùng no-show thay cho trả phòng khi khách đã nhận; không tự cộng phí hồi tố cho đơn legacy.

### L18. Dọn phòng và bảo trì
1. Đăng nhập lễ tân → tab Tình trạng phòng. Backend cho admin quyền vận hành nhưng bản giao diện admin hiện chưa có lối mở trực tiếp màn này; không nhầm menu Phòng với màn vận hành.
2. Lọc tầng/loại/vận hành nếu cần → tìm thẻ phòng → Cập nhật tình trạng.
3. Chọn Cần dọn dẹp → Đang dọn dẹp khi bắt đầu, rồi Sẵn sàng khi kiểm tra xong; lý do tùy chọn → Xác nhận.
4. Bảo trì/tạm ngừng phải tôn trọng lịch và khách đang ở; không ép chuyển phòng đang sử dụng sang dọn để nhận khách khác.

### L19. Đánh giá sau lưu trú và xem đánh giá
1. Khách → Lịch sử → mở đơn Đã trả phòng có thời điểm trả thực tế → Đánh giá phòng.
2. Chủ động chọn 1–5 sao, nhập nhận xét tùy chọn tối đa 1.000 ký tự → Gửi đánh giá.
3. Xem lại Đánh giá của bạn trong đơn; menu → Đánh giá của tôi để xem danh sách cá nhân.
4. Muốn đọc công khai: mở phòng → phần đánh giá → chọn lọc sao/sắp xếp và phân trang.
5. Một đơn chỉ gửi một lần; không đủ điều kiện chỉ vì đã đến ngày trả dự kiến. Đánh giá bị ẩn vẫn xuất hiện trong danh sách riêng.

### L20. Quản trị ẩn/hiện đánh giá
1. Admin → menu → Quản lý đánh giá.
2. Chọn sao/trạng thái, nhập mã phòng/mã loại hoặc Lọc ngày đánh giá → Áp dụng bộ lọc; Xóa bộ lọc để trở lại.
3. Trên đánh giá bấm Ẩn đánh giá → lý do tùy chọn → Xác nhận.
4. Kiểm tra Đang ẩn; đánh giá không còn tính trong tổng điểm công khai.
5. Muốn phục hồi bấm Hiện lại đánh giá → Xác nhận. Không có nút sửa sao thay khách.

### L21. Xem lịch và tra cứu đơn bằng mã
1. Lễ tân/admin → menu → Lịch phòng → chọn Phòng trong ô đầu.
2. Chạm ngày ở lịch tháng hoặc thanh ngày; hai phần cùng chọn một ngày. Chạm sự kiện để mở đơn; quay lại lịch được tải lại.
3. Khách muốn xuất trình mã: chi tiết đơn → Mã đặt phòng.
4. Lễ tân/admin → menu → Quét mã đặt phòng → nhập Mã tham chiếu đặt phòng → Tra cứu.
5. Hoặc Mở camera quét mã và cấp quyền; dùng Đèn pin/Đổi camera khi cần. Quét đúng chỉ mở chi tiết; nhận phòng/thu tiền vẫn bấm theo luồng riêng. Camera chưa nghiệm thu đầy đủ.

### L22. Quản lý phòng, loại và tiện nghi
1. Admin → menu → Loại phòng/Phòng/Tiện nghi → bấm dấu + (Thêm mới).
2. Loại phòng: nhập tên, giá mỗi đêm, sức chứa; mô tả/diện tích/số giường khi cần → Lưu.
3. Phòng: nhập số phòng, chọn loại, tầng/ghi chú khi cần → Lưu. Sau lưu có luồng chọn ảnh của phòng.
4. Muốn sửa, mở dòng hiện có → sửa → Lưu. Không hạ sức chứa/đổi loại/ngừng kinh doanh trái ràng buộc các đơn đang giữ.
5. Với tiện nghi, tạo tên/biểu tượng; mở sửa loại phòng → Quản lý tiện nghi → chọn tiện nghi → Lưu tiện nghi. Loại phòng không có ảnh riêng.

### L23. Sắp xếp ảnh phòng và ảnh bìa
1. Admin → menu → Phòng → mở/sửa phòng → Chọn / quản lý ảnh phòng.
2. Thêm ảnh theo L05; upload xong kiểm tra đúng phòng.
3. Bật công tắc Ảnh bìa để đặt ảnh đại diện của phòng; dùng Đưa lên trước/Đưa xuống sau để đổi thứ tự.
4. Bấm Xóa ảnh → chọn Giữ lại hoặc Xóa trong xác nhận. Mỗi phòng chỉ có một bìa; ảnh lỗi có fallback thay vì làm hỏng thẻ.

### L24. Tạm ngừng phòng theo khoảng ngày
1. Admin → menu → Lịch tạm ngừng → dấu + Thêm mới.
2. Chọn phòng, Từ ngày và Đến ngày (không chiếm ngày này); lý do tùy chọn.
3. Lưu; nếu xung đột với đơn giữ phòng, xem lỗi và chọn khoảng hợp lệ thay vì ghi đè.
4. Mở lịch hiện có để sửa/đổi hiệu lực theo màn; kiểm tra lại tìm phòng/lịch nhân viên.

### L25. Quản lý tài khoản và quyền
1. Admin → menu → Quản lý tài khoản → tìm tên/email, lọc vai trò/trạng thái.
2. Tạo nhân viên: bấm Tạo tài khoản nội bộ → nhập email, mật khẩu ban đầu, vai trò, họ tên/điện thoại → lưu.
3. Mở tài khoản → sửa hồ sơ hoặc đổi vai trò/khóa/mở khóa bằng nút tương ứng → lý do tùy chọn → Xác nhận.
4. Xem lịch sử thay đổi trong chi tiết. Không tự hạ quyền/khóa trái điều kiện, không xóa admin cuối; tài khoản khách không tự biến thành nhân viên.

### L26. Báo cáo doanh thu và xuất tệp
1. Admin → tab Tổng quan để xem chỉ số; tab Báo cáo để chọn thời gian/nhóm kỳ và áp dụng bộ lọc.
2. Đọc riêng thực thu, hoàn, thu ròng, công nợ và giá trị đặt; chúng không phải cùng một khái niệm.
3. Cuộn tới Xuất PDF → xem trong app → Lưu hoặc chia sẻ để chuyển sang hộp chia sẻ Android.
4. Chọn Xuất CSV để lưu/chia sẻ dữ liệu bảng qua hệ điều hành.
5. Tệp đã lưu/chia sẻ ra ngoài không bị app tự xóa; tệp tạm nội bộ được dọn khi đăng xuất. Sandbox không cộng vào doanh thu thực.

### L27. Nhập nhiều phòng từ CSV
1. Admin chuẩn bị CSV UTF-8 với dòng đầu: so_phong,ma_lp,tang,ghi_chu. ma_lp là mã loại đã có; không nhập ảnh/giá vào CSV này.
2. Menu → Nhập phòng từ CSV → Chọn CSV và xem trước → chọn tệp trong Android.
3. Kiểm tra số dòng/lỗi từng dòng và bảng preview. Tệp tối đa 1.000 dòng/2 MiB; bảng chỉ hiển thị 100 dòng đầu nhưng kiểm tra toàn bộ file.
4. Có lỗi thì sửa file và chọn lại; chỉ khi hợp lệ mới bấm Xác nhận nhập toàn bộ.
5. Kiểm tra danh mục phòng sau thành công. Nhập nguyên lô, không cập nhật/ghi đè phòng cũ và không cố bấm lại để tạo trùng. Trọn luồng trên điện thoại chưa nghiệm thu; API đã được kiểm thử.

### L28. Thông tin khách sạn, bản đồ và video
1. Mọi vai trò → menu → Thông tin khách sạn.
2. Bấm Vị trí khách sạn để xem bản đồ/ghim. Bấm Khoảng cách từ tôi khi muốn tính, cấp quyền vị trí nếu đồng ý.
3. Bấm Chỉ đường để mở ứng dụng ngoài; khoảng cách trong app là đường thẳng, không phải tuyến đường lái xe.
4. Hotline/email/website chỉ bấm được khi đã có thông tin hợp lệ; cần app xử lý liên kết trên điện thoại.
5. Video chỉ xuất hiện khi có URL hợp lệ; bấm phát/dừng/tua/toàn màn hình. Hiện chưa có video thật để thử.

### L29. Cấu hình thông tin công khai khách sạn
1. Admin → menu → Cài đặt → Thông tin công khai khách sạn.
2. Điền Điện thoại liên hệ, Email liên hệ, Website HTTPS, URL video HTTPS trực tiếp và Chú thích video khi có; không dùng URL trang YouTube thay URL video trực tiếp. Màn này không có ô đổi tên ứng dụng/khách sạn.
3. Bấm Lưu → quay lại Thông tin khách sạn để kiểm tra phần công khai.
4. Không điền mật khẩu merchant/SMTP/Firebase vào các ô này; khóa bí mật cấu hình ở backend ngoài giao diện.

### L30. Gửi và xử lý góp ý
1. Tài khoản đã đăng nhập → menu → Góp ý và báo lỗi → nhập Nội dung phản hồi.
2. Nếu cần, bấm Chụp và chú thích màn hình góp ý; viết/đánh dấu rồi Xem lại ảnh đính kèm. Bỏ ảnh đính kèm nếu chưa phù hợp.
3. Chỉ tích Đính kèm model, phiên bản Android và ứng dụng nếu muốn gửi thông tin đó; không gửi mật khẩu/token/mã thanh toán.
4. Bấm Gửi phản hồi; nhận thông báo tiếp nhận. Góp ý text đã thử thành công; chuỗi ảnh chưa nghiệm thu đầy đủ trên điện thoại.
5. Admin → menu → Phản hồi khách hàng → xem nội dung, Xem ảnh đính kèm riêng tư nếu có → chọn Tiếp nhận/Đang xử lý/Đã xử lý trong ô trạng thái.

### L31. Thông báo trong app và nhắc lịch
1. Bấm chuông thông báo trên thanh trên → mở mục để xem/đánh dấu đã đọc và tải thêm khi có.
2. Với thông báo có đơn hợp lệ, chạm mở chi tiết; nếu chưa đăng nhập thì phải xác thực trước, server kiểm tra quyền.
3. Menu → Cài đặt → Thông báo và nhắc lịch → bật Nhắc lịch nhận phòng và cấp quyền thông báo nếu đồng ý.
4. Bấm Giờ nhắc ngày trước khi đến → chọn giờ/phút → xác nhận. Chỉ nhắc các đơn xác nhận phù hợp.
5. Thông báo đẩy là mục riêng, hiện chờ Firebase; không nhầm inbox/nhắc cục bộ đang có với push qua Internet đã hoạt động.

### L32. Đăng nhập bằng vân tay
1. Đăng nhập mật khẩu lần đầu → menu → Cài đặt → bật Đăng nhập bằng vân tay.
2. Xác nhận mật khẩu tài khoản một lần → Tiếp tục → chạm cảm biến trong hộp thoại hệ thống để đăng ký điện thoại. Không lưu mật khẩu hoặc ảnh vân tay.
3. Đăng xuất hoặc mở lại app → Tài khoản → Đăng nhập / Đăng ký → Đăng nhập bằng vân tay; không cần điền email/mật khẩu → chạm cảm biến.
4. Backend xác minh chữ ký thử thách và cấp phiên mới. Hủy hoặc không được nhận diện thì dùng email/mật khẩu; không hỏi quét thêm sau đăng nhập mật khẩu.
5. Mỗi máy lưu một tài khoản, đăng xuất vẫn giữ lựa chọn; tắt trong Cài đặt để thu hồi khi dùng máy chung. Đổi mật khẩu/quyền, thay vân tay hoặc quá 90 ngày có thể cần đăng nhập mật khẩu và bật lại. Không tự đăng ký vân tay/PIN OS hộ người dùng.

### L33. Thanh toán online — luồng đã chuẩn bị, chưa chạy thật
1. Khách mở đơn Đã xác nhận/Đang ở/Chờ thanh toán còn nợ → Thanh toán online.
2. Xem trạng thái cấu hình MoMo/VNPAY. Hiện thiếu cấu hình nên không thể tạo giao dịch thật.
3. Sau khi được cấu hình và nghiệm thu: chọn cổng → mở trang thanh toán HTTPS → thanh toán phía nhà cung cấp → quay lại app.
4. Bấm Kiểm tra kết quả/Làm mới danh sách; nếu cần Mở lại cổng thanh toán của yêu cầu đang có. Kết quả do server xác minh callback/query, không chỉ dựa màn trình duyệt quay về.
5. Khi kết quả chưa rõ không tự tạo yêu cầu khác; sandbox hiển thị riêng, không trả nợ thật. Nhân viên đối chiếu số dư trước hoàn tất trả phòng.

### L34. Quên mật khẩu — chờ SMTP
1. Màn Đăng nhập → Quên mật khẩu? → nhập Email tài khoản.
2. Hiện chưa có SMTP nên nút/trạng thái báo chưa cấu hình, chưa nhận thư thật.
3. Sau cấu hình: bấm Gửi mã xác nhận → mở email → nhập Mã xác nhận trong email, Mật khẩu mới, Nhập lại mật khẩu mới.
4. Bấm Đổi mật khẩu rồi đăng nhập bằng mật khẩu mới; mã có hạn, dùng một lần và giới hạn số lần thử.

### L35. Google/Facebook và liên kết — chờ OAuth
1. Ở màn Đăng nhập xem nút Google/Facebook; hiện chưa có cấu hình nên không thực hiện đăng nhập ngoài thật.
2. Sau cấu hình đúng client/server: bấm nhà cung cấp, chọn tài khoản và chấp thuận; backend xác minh rồi mới tạo phiên TETRA.
3. Với tài khoản đã đăng nhập: menu → Cài đặt → Tài khoản liên kết → Liên kết/Hủy liên kết.
4. Không tự gộp hai tài khoản chỉ vì cùng email; không hủy phương thức đăng nhập cuối cùng. Hủy liên kết có thể yêu cầu đăng nhập lại.

## 4.2. Sơ đồ nghiệp vụ và các điều kiện quan trọng
Luồng chính: Chờ xác nhận → Đã xác nhận → Đang ở → Chờ thanh toán → Đã trả phòng. Nhánh kết thúc: Đã hủy, Đã từ chối, Hết hạn, Khách không đến. Bốn trạng thái đầu giữ lịch theo quy tắc server; không xóa phiếu khi kết thúc.

Luồng phòng sau trả: Cần dọn dẹp → Đang dọn dẹp → Sẵn sàng. Trạng thái đặt trước/đang sử dụng khác trạng thái vệ sinh/vận hành và khác trạng thái kinh doanh.

| Tình huống | Cách tính/điều kiện hiện tại |
| --- | --- |
| Khoảng lưu trú | Một phiếu/một phòng vật lý; 1–30 đêm; khoảng [ngày nhận, ngày trả), ngày trả không chiếm đêm. |
| Mốc chuẩn | Nhận từ 14:00; trả đến 12:00; giờ Việt Nam. Đây là chính sách ứng dụng, không khẳng định mọi khách sạn đều giống nhau. |
| Nhận sớm | Trước 06:00: 100% giá một đêm; 06:00 đến trước 14:00: 50%. |
| Trả trễ | Sau 12:00 đến 15:00: 30%; sau 15:00 đến 18:00: 50%; sau 18:00: 100%. Đúng 12:00 chưa có phí, đúng 15:00 thuộc 30%, đúng 18:00 thuộc 50%. |
| Quá ngày dự kiến | Thêm 100% mỗi ngày quá hạn và phần theo giờ ngày bàn giao; khách vẫn được tính đang ở đến khi trả thực tế. |
| Phí dịch vụ | Giường phụ gợi ý 250.000đ/đêm, tối đa một giường/phiếu; lễ tân xác nhận thực tế. Minibar/giặt là/hư hỏng/khác dùng phát sinh được ghi nhận. |
| Hủy | Đơn chờ hoặc đơn xác nhận cách giờ nhận ít nhất 24 giờ: không phí; xác nhận hủy sát hơn 24 giờ/no-show: một đêm, không vượt tiền phòng. Chính sách chốt theo đơn. |
| Tiền và trả phòng | Không bắt buộc cọc; cho ghi thu một phần theo điều kiện. Tổng phải trả gồm phòng + phí chưa hủy; trừ thu ròng để biết còn thu/hoàn. Còn chênh thì chặn hoàn tất trả. |
| Đơn cũ | Không áp phụ thu/hết hạn mới hồi tố vào đơn legacy; giữ giá, liên hệ và sổ tiền cũ. |

# 5. Phần chưa sẵn sàng và phần chưa nghiệm thu
## 5.1. Đã chuẩn bị nhưng hiện chưa hoạt động đầy đủ
| Mã | Chức năng | Vì sao/chỗ còn thiếu và cách hiện tại |
| --- | --- | --- |
| CHO01 | Đăng nhập Google | Thiếu cấu hình OAuth client/server, thông tin ký/package/redirect phù hợp. Email/mật khẩu vẫn dùng bình thường. |
| CHO02 | Đăng nhập Facebook | Thiếu cấu hình Meta app, public SDK settings và khóa server. Chưa đăng nhập ngoài thật. |
| CHO03 | Liên kết Google/Facebook | Có màn và kiểm tra server nhưng cùng phụ thuộc CHO01/02. Không phải nút đã đảm bảo liên kết thành công. |
| CHO04 | Quên mật khẩu qua email | Thiếu SMTP/sender hợp lệ, chưa gửi mã thật; mã/hết hạn/throttle mới kiểm thử với transport giả lập. |
| CHO05 | Khách mới được lễ tân đặt hộ tự đặt mật khẩu | Hồ sơ email mới không được cấp mật khẩu chung; cần luồng email khôi phục CHO04 để tự đặt mật khẩu. |
| CHO06 | Push FCM | Thiếu Firebase client/server; chưa kiểm chứng token thiết bị, cấp quyền và nhận push nền thật. Inbox trong app vẫn có. |
| CHO07 | MoMo online | Thiếu merchant/khóa và callback HTTPS công khai hợp lệ; chưa chạy sandbox/live nhà cung cấp. Không tạo thu tiền giả. |
| CHO08 | VNPAY online | Thiếu merchant/khóa và callback HTTPS/IPN hợp lệ; chưa chạy query/settlement thật với gateway. |
| CHO09 | Hoàn tiền tự động gateway | Chưa bật/chưa có quy trình hoàn tự động hoàn chỉnh; hiện chỉ có ghi nhận hoàn thủ công theo giao dịch thực tế và quyền admin. |
| CHO10 | Video giới thiệu thật | Chưa có URL video khách sạn HTTPS trực tiếp; trang khách đang ẩn phần video. Không thay bằng video giả. |
| CHO11 | Liên hệ công khai đầy đủ | Chỉ hiện hotline/email/website đã cấu hình thật; cần chủ dự án cung cấp và admin lưu. Không mặc định bịa thông tin. |
| CHO12 | Chạy công khai mọi nơi | Hiện API LAN/máy tính cá nhân; chưa có hosting HTTPS, domain, release signing/phát hành production. Ra Wi-Fi khác không đảm bảo truy cập IP LAN cũ. |
| CHO13 | Backend tự chạy sau reboot | PostgreSQL Auto; backend hiện khởi động bằng PowerShell, chưa cài Windows service/tác vụ tự chạy. Máy tính tắt thì API LAN ngừng. |
| CHO14 | Ảnh trên hosting không bền vững | Có media guard nhưng vẫn cần ổ bền vững và đường lưu đúng khi triển khai; nếu tắt lưu media thì chặn upload ảnh, góp ý text vẫn gửi được. |
| CHO15 | Điểm vào vận hành phòng cho admin | API cho admin quyền vận hành, nhưng thanh dưới/menu admin hiện không mở trực tiếp RoomStatusScreen. Menu Phòng là sửa danh mục, không thay thế màn vệ sinh. Lễ tân có tab Tình trạng phòng; cần bổ sung điểm vào admin nếu muốn thao tác trực tiếp vai trò đó. |

Điền cấu hình là bước cần, chưa đủ để coi nghiệm thu xong. Sau cấu hình phải thử lỗi/từ chối quyền/hết hạn/callback/khôi phục mạng theo từng dịch vụ. Khóa bí mật điền ở cấu hình cục bộ hoặc secret của máy chủ, không trong chat hay file hướng dẫn công khai.

## 5.2. Có mã nhưng chưa kiểm thử trọn luồng trên điện thoại
| Mã | Phần cần kiểm thử | Đã có bằng chứng đến đâu |
| --- | --- | --- |
| KT01 | Camera quét QR | Nhập mã tay/tra cứu đã thử; chưa nghiệm thu camera đọc QR, đổi camera/đèn pin/từ chối quyền trong mọi trạng thái. |
| KT02 | Avatar/ảnh phòng crop | Avatar thư viện → kéo/reset/preview/căn lại/lưu đã đạt trên máy, có đối chiếu pixel và ảnh hồ sơ. Camera, crop ảnh phòng với đủ tỷ lệ/hủy, Android mất tiến trình và thao tác pinch hai ngón trên máy chưa được nghiệm thu đầy đủ. |
| KT03 | Ảnh góp ý có chú thích | Đã chụp, vẽ chú thích, xem trước và gửi ảnh trên SM A135F; ảnh có nét vẽ, lưu private, không đăng nhập 401/chủ 200. Chưa nghiệm thu hết các tổ hợp bỏ ảnh, chụp lại, xoay máy và Android hủy tiến trình. |
| KT04 | Nhập CSV trọn luồng | Hộp chọn Android đã mở/hủy, preview/confirm API đã thử; chưa chọn CSV rồi xác nhận nhập từ điện thoại. |
| KT05 | GPS/khoảng cách/chỉ đường | Bản đồ/ghim đã hiển thị; chưa nghiệm thu đủ xin/từ chối quyền, GPS tắt và khoảng cách thực tế/ứng dụng chỉ đường. |
| KT06 | Đăng nhập vân tay | Chủ máy đã đăng ký và đăng nhập thật không nhập email/mật khẩu, backend cấp JWT mới; đã bỏ khóa phiên. Chưa thay đổi bộ vân tay/PIN của OS để thử vô hiệu hóa khóa, không coi kiểm thử server là thao tác OS. |
| KT07 | Nhắc lịch đúng giờ khi nền | ID/logic có test; chưa đo giao thông báo khi Doze, khởi động lại, đổi múi giờ và giới hạn pin Samsung. |
| KT08 | Phạm vi UI tổng thể | Có QA tiêu biểu, không khẳng định mọi nút/mọi tổ hợp/mọi điện thoại đã được thao tác thủ công. Các kiểm thử API không thay cho thử UI tương ứng. |

## 5.3. Những mục đặc tả đã điều chỉnh, không phải lỗi bỏ sót
- Giữ thanh điều hướng xanh/vàng đang dùng; không thêm thanh dưới thứ hai hoặc convex_bottom_bar.
- Dùng SnackBar có kiểm soát thay toast_notification; giữ Badge Material có sẵn thay thêm gói trùng chức năng.
- Ảnh thuộc phòng, không quay về loại phòng. Dùng crop/preview thay thêm bộ image editor tổng hợp.
- Không thêm WebView khi chưa có nội dung website đáng tin cần nhúng; thanh toán mở ngoài bằng HTTPS.
- Pin OSM 1.4.6 để giữ minSdk 24; không ép bỏ kiểm tra manifest.
- Không thêm AI/ML/Tools, InAppPurchase hoặc thay backend PostgreSQL bằng Firebase/SQLite. Đây không phải các chức năng đã triển khai.

# 6. Đề xuất phát triển tiếp theo
Những mục dưới đây là đề xuất mới để chủ dự án chọn, chưa được thực hiện chỉ vì có tên trong tài liệu. Mức ưu tiên dựa trên khoảng trống của hệ thống hiện tại, không phải cam kết thời gian/chi phí.

| Mã/ưu tiên | Đề xuất | Lý do và phạm vi nên làm |
| --- | --- | --- |
| DX01 / Cao | Hoàn tất cấu hình và nghiệm thu dịch vụ | OAuth/SMTP/Firebase/merchant, domain HTTPS, kiểm thử sandbox trước live; ưu tiên hoàn thiện cái đã có. |
| DX02 / Cao | Hoàn tất ma trận QA thiết bị | Thử KT01–KT08, quyền bị từ chối, mạng chập chờn, chữ lớn, nhiều vai trò, restart app/server; bổ sung test hồi quy từ lỗi thật. |
| DX03 / Cao | Triển khai server ổn định | Domain HTTPS, backup/restore đã diễn tập, media bền vững, worker, log không secret, theo dõi health; tách dev/test/production. |
| DX04 / Cao | Tự khởi động và cấu hình địa chỉ API | Backend Windows service/tác vụ hoặc server riêng; chọn môi trường/địa chỉ qua cấu hình phù hợp, tránh build lại chỉ vì đổi LAN IP. |
| DX05 / Cao | Đối soát và xử lý tiền chưa rõ | Màn tập trung attempt pending, đối soát gateway và nhật ký xử lý, cảnh báo chênh; tránh thu tay trong khi online chưa rõ kết quả. |
| DX06 / Cao | Hoàn tiền gateway có kiểm soát | Quy trình yêu cầu/duyệt/nhà cung cấp/kết quả, quyền và idempotency; chỉ bật sau nghiệm thu merchant, không giả hoàn tiền. |
| DX07 / Vừa | Cấu hình chính sách kinh doanh | Admin quản lý giờ nhận/trả, mức phí/giữ chỗ, ngày hiệu lực và preview; snapshot phiên bản để giữ nguyên chính sách đơn cũ. |
| DX08 / Vừa | Danh mục dịch vụ và tồn minibar | Giá/đơn vị chuẩn, tồn kho, số lượng tiêu thụ; giảm nhập tay và sai phí. |
| DX09 / Vừa | Điều phối buồng phòng | Giao nhân viên dọn, checklist, giờ bắt đầu/kết thúc, báo hỏng và kiểm tra phòng sẵn sàng; khác thay trạng thái thủ công hiện có. |
| DX10 / Vừa | Nhiều phòng trên một đặt chỗ | Đặt đoàn/nhiều phòng, phân bổ khách, nhận/trả từng phòng và hóa đơn chung; hiện mỗi phiếu một phòng vật lý. |
| DX11 / Vừa | Hồ sơ lưu trú thực tế | Danh sách khách đi cùng, giấy tờ theo nhu cầu và quyền truy cập, hạn lưu/xóa dữ liệu; hiện liên hệ đặt phòng chưa thay thế hồ sơ này. |
| DX12 / Vừa | Chứng từ và hóa đơn thuế | Tách hóa đơn lưu trú nội bộ khỏi chứng từ/hóa đơn điện tử hợp lệ; tích hợp nhà cung cấp khi có yêu cầu thực tế. |
| DX13 / Vừa | Hỗ trợ khách hàng hai chiều | Khách xem tiến độ và trả lời góp ý; quản trị phản hồi, thông báo kết quả; hiện quản trị mới cập nhật trạng thái xử lý. |
| DX14 / Thấp | Chính sách đánh giá mở rộng | Chủ khách sạn trả lời, báo cáo lạm dụng; nếu cho khách sửa thì lưu phiên bản/audit, không âm thầm thay lịch sử. |
| DX15 / Thấp | Yêu thích và gợi ý cá nhân | Lưu phòng yêu thích, lọc tiện nghi/nhu cầu; ưu tiên quy tắc có thể giải thích trước khi cân nhắc AI. |
| DX16 / Vừa | Chăm sóc khách và khuyến mãi | Mã giảm giá, giới hạn sử dụng, loyalty, giá theo mùa/cuối tuần; phải chốt giá/điều kiện vào đơn và chống lạm dụng. |
| DX17 / Vừa | Mở rộng quản trị | Lễ tân/buồng phòng/kế toán với quyền chi tiết, nhiều cơ sở, ca trực; hiện không coi vai trò lễ tân là quản lý toàn bộ. |
| DX18 / Vừa | Phát hành Android chính thức | Release signing riêng, HTTPS, giảm kích thước, chính sách quyền/riêng tư và quy trình cập nhật; APK debug hiện tại chưa phải gói production. |
| DX19 / Cao | Mở vận hành phòng từ admin | Thêm điểm vào Tình trạng phòng trong menu admin và kiểm thử quyền/đường quay lại; khắc phục CHO15 thay vì hướng dẫn người dùng bấm nút chưa có. |

# 7. Bằng chứng, nguồn và vận hành
## 7.1. Kết quả đã có
- Backend mới nhất: 97 đạt trong lượt đầy đủ, 1 kiểm tra metadata cũ sai số bảng; sửa kỳ vọng rồi chạy lại 16/16 unit đạt. Tổng 98 ca khác nhau đã đạt; PostgreSQL thật/hotel_booking_test, không thay SQLite.
- Flutter mới nhất: lượt đầy đủ 42/42 đạt, có kiểm tra pixel crop và đăng nhập vân tay; APK ARM debug trên SM A135F. Trạng thái analyze/build/nghiệm thu cuối xem docs/profile_biometric_acceptance.md.
- QA nghiệp vụ trước đợt tích hợp: đăng ký/đăng nhập, xác nhận cùng ngày, nhận phòng, thêm minibar, yêu cầu trả, ghi thu và hoàn tất trả; phát hiện/sửa dialog lỗi sau request thành công.
- QA tích hợp hôm nay trên điện thoại: gửi đánh giá 4 sao cho đơn đã trả thật; admin ẩn với lý do rỗng; kiểm tra công khai không còn đánh giá và chủ vẫn thấy bản ẩn.
- Gửi góp ý text và admin đổi Đang xử lý; chọn lịch phòng có đơn; tra cứu mã nhập tay; render PDF tiếng Việt; mở/hủy picker CSV; sửa bản đồ 403 và xác nhận bản đồ/ghim thật.
- QA dùng dữ liệu test riêng. Sau QA đã đăng xuất tài khoản thử, đưa backend về hotel_booking, đối chiếu dữ liệu không đổi. health/db và tải phòng từ điện thoại HTTP 200 qua Wi-Fi, không adb reverse.
- Sau đó chủ dự án yêu cầu thêm dữ liệu gốc để quay: đã sao lưu và thêm 12 phòng/23 ảnh, 6 khách/1 lễ tân, 22 đơn/9 đánh giá; không thay bản ghi cũ. Đã chạy kịch bản trên hotel_booking qua UI bằng các tài khoản mới, giữ thêm 1 đơn/1 khoản thu/1 đánh giá. Kịch bản và kết quả ở docs/KICH_BAN_QUAY_TIEN_DO_TETRA.md; không lẫn giai đoạn này với QA cách ly trước đó.

Các con số kiểm thử không phải số chức năng, cũng không chứng minh đã thử mọi trường hợp thủ công. Không ghi mật khẩu/token trong tài liệu này.

## 7.2. Nguồn đối chiếu trong dự án
| Nguồn | Nội dung dùng để lập tài liệu |
| --- | --- |
| docs/STATUS.md; docs/upgrade_notes.md | Mốc phiên bản ngày 17/10 và các thay đổi ngày 18/10. |
| docs/upgrade_verification.md | QA01–QA11, danh mục/ảnh/phụ thu và bằng chứng điện thoại đợt trước. Một số mô tả cũ đã được thay bởi bản hiện tại. |
| docs/integration_acceptance.md | Kết quả mới nhất, giới hạn thiết bị/dịch vụ, khôi phục DB chính. |
| docs/integration_decisions.md | Các điều chỉnh hai đặc tả theo yêu cầu trực tiếp mới nhất. |
| docs/screens.md; lib/widgets/app_drawer.dart; lib/app/app_root.dart | Điểm vào, menu và thanh dưới theo vai trò. |
| lib/screens; lib/widgets/booking_operations.dart; catalog_edit.dart | Nhãn nút/form và điều kiện thao tác hiện tại. |
| backend/app/api; backend/app/models; backend/app/services | Quyền/nghiệp vụ, review, CSV, feedback, thanh toán và outbox. |
| docs/external_configuration.md; docs/service_configuration.md | Cách chuẩn bị OAuth/SMTP/Firebase/gateway và những điều kiện triển khai. |

Khi nhật ký cũ nói “lý do bắt buộc”, “ảnh loại phòng”, “chưa có gateway” hoặc chỉ dùng USB, lấy quyết định và mã hiện tại làm chuẩn: lý do tùy chọn, ảnh từng phòng, adapter gateway đã có nhưng chờ cấu hình, API Wi-Fi không cần USB.

## 7.3. Chạy bản hiện tại
1. Mở máy tính; PostgreSQL 18 đã đặt tự chạy cùng Windows, không cần mở pgAdmin.
2. Mở PowerShell trong thư mục dự án chứa pubspec.yaml và chạy:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_backend.ps1 -Lan`
3. Giữ máy tính/backend hoạt động; điện thoại dùng mạng truy cập được máy tính. Bản đã cài dùng http://192.168.31.112:8000, DEMO_MODE=false.
4. Kiểm tra /health/db khi không kết nối được. Nếu IP đổi cần xử lý địa chỉ API/cấu hình mạng; không mở cổng PostgreSQL cho điện thoại.
5. Không reset/drop/truncate hotel_booking để demo hoặc kiểm thử. Dùng hotel_booking_test riêng; sao lưu dữ liệu trước migration hoặc chuyển máy.

Tài liệu chốt theo trạng thái đã kiểm tra ngày 18/10/2026. Những thay đổi mã/cấu hình sau ngày này cần được cập nhật vào bản kiểm kê tiếp theo.

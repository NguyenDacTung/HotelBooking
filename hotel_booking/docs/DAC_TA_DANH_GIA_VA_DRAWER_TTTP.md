# Đặc tả bổ sung đánh giá phòng và Navigation Drawer cho TTTP

## 1. Yêu cầu triển khai chung

Nâng cấp trực tiếp dự án TTTP hiện có, gồm hai phần:

1. Đánh giá phòng sau khi hoàn tất lưu trú.
2. Navigation Drawer và trang Cài đặt phù hợp từng vai trò.

Trước khi sửa, kiểm tra màn hình, route, theme, model, API, phân quyền, trạng thái đặt phòng và migration hiện tại.

**Ưu tiên điều chỉnh phần bổ sung theo hệ thống đang có.** Tái sử dụng chức năng tương đương nếu đã tồn tại; không tạo hai luồng hoàn tất lưu trú, hai trang tài khoản hoặc hai nguồn dữ liệu phiên.

Giữ dữ liệu và các chức năng đang hoạt động. Không reset database, không sửa migration đã áp dụng để thay cho migration bổ sung.

Mọi thay đổi phải đồng bộ **backend, frontend, lịch sử thao tác, dữ liệu thống kê và kiểm thử**. Giao diện mới sử dụng theme TTTP hiện hành, không dùng màu sắc, font hoặc thành phần mặc định lệch thiết kế.

## 2. Đánh giá phòng sau kỳ lưu trú

### 2.1. Mục đích

Khách hàng có thể tự nguyện đánh giá phòng đã sử dụng, giúp người khác tham khảo và khách sạn nhận phản hồi.

Đánh giá không phải điều kiện bắt buộc để hoàn tất đơn hoặc sử dụng tiếp ứng dụng.

### 2.2. Điều kiện được đánh giá

Backend chỉ cho tạo đánh giá khi:

- Tài khoản đã đăng nhập và là khách sở hữu đặt phòng.
- Đặt phòng có trạng thái nghiệp vụ tương đương **đã hoàn tất lưu trú**.
- Đặt phòng chưa có đánh giá.
- Tài khoản còn hoạt động.

Không cho đánh giá đơn chờ xác nhận, bị từ chối, đã hủy hoặc chỉ mới xác nhận.

**Không suy ra đã lưu trú chỉ vì ngày trả phòng đã qua.**

### 2.3. Hoàn tất lưu trú

Kiểm tra hệ thống trước:

- Nếu đã có check-out/hoàn tất lưu trú: sử dụng trạng thái và service hiện có.
- Nếu chưa có: bổ sung thao tác **“Hoàn tất lưu trú”** cho nhân viên/admin.

Đối với luồng bổ sung tối thiểu:

- Chỉ áp dụng cho đơn đã xác nhận.
- Chỉ thực hiện từ ngày trả phòng trở đi, tính theo giờ Việt Nam.
- Nhân viên xác nhận khách thực sự đã sử dụng và kết thúc kỳ lưu trú.
- Không tự động hoàn tất tất cả đơn hết ngày.
- Khóa bản ghi, kiểm tra lại trạng thái và cập nhật trong transaction.
- Ghi người thực hiện, thời điểm và lịch sử chuyển trạng thái.

Nếu chưa có mã tương đương, có thể thêm `DA_HOAN_TAT`. Cập nhật đầy đủ constraint, enum, API, bộ lọc, nhãn hiển thị và lịch sử.

Không biến trạng thái thanh toán thành trạng thái lưu trú. Việc hoàn tất lưu trú không tự tạo giao dịch thu tiền hoặc xóa công nợ.

Đơn hoàn tất không được hủy theo luồng hủy đặt phòng thông thường. Không tự thêm chức năng mở lại đơn.

### 2.4. Nội dung đánh giá

| Trường | Quy định |
|---|---|
| Số sao | Số nguyên từ 1 đến 5, bắt buộc |
| Nhận xét | Không bắt buộc, tối đa 1.000 ký tự |
| Đặt phòng | Một đặt phòng tối đa một đánh giá |
| Phòng | Lấy từ đặt phòng trên server |
| Người đánh giá | Lấy từ tài khoản đã xác thực |
| Thời điểm | Server ghi nhận |

Trim nội dung nhận xét, kiểm tra độ dài và hiển thị dưới dạng văn bản an toàn.

Không nhận `ma_kh`, `ma_phong`, trạng thái kiểm duyệt hoặc thời điểm do client gửi để quyết định dữ liệu.

**Phiên bản này chưa cần ảnh đánh giá, trả lời của khách sạn hoặc chỉnh sửa đánh giá sau khi gửi.** Form phải thông báo rõ khách kiểm tra trước khi gửi. Sau gửi, hiển thị đánh giá đã tạo thay cho nút tạo mới.

### 2.5. Giao diện gửi đánh giá

Trong chi tiết đặt phòng đã hoàn tất:

- Chưa đánh giá: hiện nút **“Đánh giá kỳ lưu trú”**.
- Đã đánh giá: hiện số sao, nhận xét và thời điểm.
- Không đủ điều kiện: không hiện nút gửi đánh giá.

Form gồm:

1. Tóm tắt phòng và ngày lưu trú.
2. Bộ chọn 5 sao.
3. Nhãn mô tả tương ứng: Rất không hài lòng, Không hài lòng, Bình thường, Hài lòng, Rất hài lòng.
4. Ô nhận xét, bộ đếm ký tự.
5. Nút **“Gửi đánh giá”**.

Không chọn sẵn 5 sao thay khách. Nút gửi chỉ hoạt động khi đã chọn số sao hợp lệ.

Trong lúc gửi, khóa nút chống bấm lặp. Nếu lỗi mạng hoặc kết quả chưa rõ, tải lại đánh giá của đơn trước khi cho gửi tiếp. Database phải có UNIQUE trên mã đặt phòng để chống tạo trùng.

Thành công hiển thị **“Cảm ơn bạn đã chia sẻ trải nghiệm tại TTTP.”**

### 2.6. Hiển thị trên thẻ phòng

Thẻ phòng hiển thị dạng:

```text
★ 4,7 · 12 đánh giá
```

Quy định:

- Điểm trung bình làm tròn một chữ số thập phân.
- Chỉ tính đánh giá đang hiển thị công khai.
- Chưa có đánh giá: **“Chưa có đánh giá”**, không hiển thị `0 sao`.
- Chỉ có số sao, không có nhận xét vẫn tính là một đánh giá hợp lệ.
- Thẻ giữ bố cục gọn, không bị tràn khi tên phòng dài.

Nếu thẻ đại diện **phòng vật lý**, dùng điểm của phòng đó.

Nếu thẻ đại diện **loại phòng**, dùng điểm tổng hợp các đánh giá của phòng thuộc loại đó và diễn đạt rõ trong trang chi tiết. Tính trung bình từ từng đánh giá, **không lấy trung bình đơn giản của các điểm trung bình phòng**.

### 2.7. Hiển thị trên trang chi tiết

Bổ sung mục **“Đánh giá của khách lưu trú”**, gồm:

- Điểm trung bình và tổng số đánh giá.
- Phân bố số lượng đánh giá 5, 4, 3, 2, 1 sao.
- Danh sách đánh giá phân trang.
- Sắp xếp Mới nhất, Điểm cao nhất, Điểm thấp nhất.
- Bộ lọc số sao nếu phù hợp bố cục.

Mỗi đánh giá hiển thị:

- Tên hiển thị an toàn, avatar nếu có.
- Số sao, ngày đánh giá.
- Nhận xét nếu có.
- Nhãn **“Đã lưu trú”**, vì đánh giá được tạo từ đơn đủ điều kiện.

Không công khai email, số điện thoại, mã đặt phòng hoặc thông tin thanh toán.

Backend tổng hợp điểm và số lượng; frontend không tải toàn bộ đánh giá về để tự tính. Tránh truy vấn riêng cho từng thẻ phòng gây N+1.

### 2.8. Đánh giá của tôi

Bổ sung trang **“Đánh giá của tôi”**:

- Danh sách đánh giá do tài khoản hiện tại tạo.
- Phòng, kỳ lưu trú, số sao, nhận xét, thời điểm.
- Trạng thái Đang hiển thị hoặc Đã ẩn.
- Nếu bị ẩn, hiển thị lý do kiểm duyệt phù hợp cho chủ đánh giá.
- Có lối mở phòng hoặc đặt phòng liên quan theo quyền.

Khách không được tự đổi trạng thái kiểm duyệt hoặc xem dữ liệu riêng của người khác.

## 3. Quản trị đánh giá

### 3.1. Quyền

Chỉ admin được ẩn hoặc hiển thị lại đánh giá. Nhân viên không có quyền này trừ khi hệ thống có cơ chế cấp quyền rõ ràng được yêu cầu riêng.

Admin **không được sửa số sao, nhận xét hoặc người đánh giá**.

### 3.2. Trang quản lý

Có tìm/lọc theo:

- Phòng hoặc loại phòng.
- Số sao.
- Đang hiển thị/Đã ẩn.
- Khoảng ngày tạo.

Danh sách và chi tiết có phân trang, loading, empty, lỗi và thử lại. Admin xem được cả đánh giá đã ẩn.

### 3.3. Quy trình kiểm duyệt

Mặc định đánh giá hợp lệ được hiển thị ngay; không thêm luồng chờ duyệt nếu chưa cần.

Khi ẩn, bắt buộc chọn lý do:

- Xúc phạm hoặc ngôn từ không phù hợp.
- Spam/quảng cáo.
- Tiết lộ thông tin cá nhân.
- Nội dung không liên quan.
- Lý do khác, bắt buộc nhập mô tả.

**Không ẩn chỉ vì đánh giá thấp hoặc nhận xét tiêu cực hợp lệ.**

Thao tác ẩn/hiện lại phải có xác nhận, kiểm tra quyền backend và lưu audit:

- Đánh giá liên quan.
- Trạng thái trước/sau.
- Người thao tác.
- Lý do.
- Thời điểm.

Không xóa cứng đánh giá qua giao diện quản trị.

Sau ẩn/hiện lại, cập nhật thống nhất điểm trung bình, số lượng, phân bố sao, thẻ phòng, chi tiết phòng và trang quản trị. Invalidate cache nếu có.

## 4. Dữ liệu và API đánh giá

Tái sử dụng bảng tương đương nếu đã có. Nếu chưa, bổ sung bảng đánh giá với tối thiểu:

- ID.
- Mã đặt phòng FK, UNIQUE.
- Số sao, CHECK từ 1 đến 5.
- Nhận xét nullable.
- Trạng thái hiển thị.
- Thời điểm tạo/cập nhật.

Tác giả và phòng có thể truy từ đặt phòng. Nếu lưu dư FK để tối ưu, server phải bảo đảm khớp, client không được tự chọn.

Lịch sử kiểm duyệt có thể sử dụng `audit_log` hiện có; không bắt buộc tạo một hệ audit riêng.

API gợi ý, điều chỉnh theo quy ước dự án:

| Method | Endpoint | Quyền |
|---|---|---|
| POST | `/bookings/{id}/review` | Khách sở hữu, đã hoàn tất |
| GET | `/bookings/{id}/review` | Chủ đơn hoặc admin theo quyền |
| GET | `/rooms/{id}/reviews` | Công khai, chỉ đánh giá hiển thị |
| GET | `/room-types/{id}/reviews` | Công khai nếu có trang loại phòng |
| GET | `/users/me/reviews` | Chính tài khoản |
| GET | `/admin/reviews` | Admin |
| PATCH | `/admin/reviews/{id}/visibility` | Admin |
| PATCH | `/staff/bookings/{id}/complete` | Nhân viên/admin, nếu chưa có endpoint tương đương |

Response danh sách phòng bổ sung summary đánh giá, giữ tương thích frontend. Endpoint danh sách đánh giá trả summary, phân bố sao và pagination nhất quán.

Không cho request giả điều kiện đã lưu trú. Tạo đánh giá kiểm tra quyền và trạng thái trong transaction; request cạnh tranh cùng đơn chỉ tạo được một bản ghi.

## 5. Navigation Drawer cho các vai trò

### 5.1. Mục tiêu

Bổ sung hoặc cải tiến Navigation Drawer cho:

- Khách chưa đăng nhập.
- Khách hàng.
- Nhân viên.
- Admin.

Biểu tượng mở Drawer là hamburger menu ở đầu AppBar của các trang cấp cao phù hợp. Trang con vẫn ưu tiên nút Back, không thay toàn bộ nút Back bằng menu.

Dùng một cấu trúc Drawer chung với danh sách mục theo quyền. Không sao chép bốn bản Drawer dễ lệch giao diện.

### 5.2. Header tài khoản ở trên cùng

Header nằm phía trên mọi nhóm chức năng, gồm:

- Avatar.
- Tên tài khoản.
- Email cỡ chữ nhỏ hơn, nếu có.
- Nhãn quyền: **Quản trị viên / Nhân viên / Khách hàng**.
- Dấu hiệu có thể bấm để mở **Thông tin tài khoản**.

Cả khối header có thể bấm, không chỉ avatar.

Tên/email dài được xử lý xuống dòng hoặc ellipsis phù hợp. Không hiện chữ `null`, email giả hoặc ID kỹ thuật khi thiếu dữ liệu.

Khách chưa đăng nhập:

- Avatar mặc định.
- Tiêu đề **“Chào mừng đến TTTP”**.
- Lời mời **“Đăng nhập / Đăng ký”**.
- Bấm mở đăng nhập; giữ ngữ cảnh quay về khi thích hợp.

Avatar, tên, email và quyền lấy từ cùng nguồn session/profile với trang tài khoản. Sửa hồ sơ phải cập nhật header ngay; logout phải xóa thông tin tài khoản cũ.

### 5.3. Nguyên tắc chọn mục

Không lặp lại mọi chức năng đã có trên bottom navigation.

**Ngoại lệ cố ý:** khối tài khoản luôn có dù bottom navigation đã có tab Tài khoản.

Danh sách cuối cùng phải dựa trên route/bottom navigation thực tế. Không đưa nút tới trang chưa triển khai hoặc người dùng không có quyền.

Gợi ý:

| Vai trò | Mục có thể đưa vào Drawer |
|---|---|
| Chưa đăng nhập | Vị trí và chỉ đường, Trợ giúp, Cài đặt công khai |
| Khách | Đánh giá của tôi, Vị trí và chỉ đường, Góp ý/Báo lỗi, Cài đặt |
| Nhân viên | Lịch phòng, Quét mã đặt phòng, Góp ý/Báo lỗi, Cài đặt |
| Admin | Quản lý phòng, Loại phòng, Tiện nghi/Hình ảnh, Lịch tạm ngừng, Quản lý tài khoản, Quản lý đánh giá, Phản hồi người dùng, Cài đặt |

Nếu mục đã có trên bottom navigation thì có thể bỏ khỏi Drawer. Nhóm quản trị nhiều mục có thể chia bằng tiêu đề nhóm hoặc expandable section, không tạo danh sách phẳng quá dài.

**Đăng xuất** nằm cuối, tách biệt; chỉ hiển thị khi đã đăng nhập.

### 5.4. Hành vi và giao diện

- Dùng theme TTTP: nền, font, icon, màu mục đang chọn, khoảng cách và bo góc nhất quán.
- Header nổi bật vừa phải, chữ dễ đọc; không đặt chữ trực tiếp trên ảnh nền khó nhìn.
- Có SafeArea và cuộn khi màn hình thấp/cỡ chữ lớn.
- Chọn mục thì đóng Drawer rồi điều hướng đúng.
- Không đẩy lặp cùng một route nhiều lần khi đang ở chính trang đó.
- Đánh dấu mục đang chọn khi phù hợp.
- Back khi Drawer đang mở phải đóng Drawer trước.
- Nếu quyền thay đổi hoặc phiên hết hạn, cập nhật menu và chặn trang không còn được phép.

Danh sách menu theo quyền chỉ là lớp giao diện. API vẫn kiểm tra quyền độc lập.

## 6. Trang Cài đặt

### 6.1. Phân biệt hai loại cài đặt

**Cài đặt cá nhân** áp dụng cho tài khoản/thiết bị đang dùng.

**Cấu hình hệ thống** áp dụng toàn khách sạn, chỉ admin được quản lý.

Không trộn hai loại vào cùng form khiến nhân viên thay đổi cấu hình toàn hệ thống.

### 6.2. Cài đặt cá nhân

Tái sử dụng tùy chọn đã có, chỉ hiển thị chức năng thực sự hỗ trợ:

- Thông báo trong ứng dụng/push theo cơ chế hiện có.
- Nhắc lịch lưu trú dành cho khách.
- Thông báo nghiệp vụ dành cho nhân viên/admin.
- Bảo mật và mở khóa sinh trắc học nếu đã tích hợp.
- Tùy chọn hiển thị được ứng dụng hỗ trợ.
- Thông tin phiên bản và lối vào Trợ giúp/Góp ý.

Không thêm switch không có tác dụng. Không thêm Dark Mode hoặc đổi ngôn ngữ chỉ để có mục nếu toàn ứng dụng chưa hỗ trợ đầy đủ.

Phân biệt:

- Quyền thông báo của hệ điều hành.
- Tùy chọn nhận từng loại thông báo trong app.
- Dịch vụ push chưa cấu hình.

Nếu push chưa cấu hình, hiển thị **“Chưa cấu hình”**, không giả bật thành công. Thay đổi switch không tự thay quyền hệ điều hành; hướng dẫn mở Settings khi cần.

Tùy chọn cần đồng bộ nhiều thiết bị lưu backend theo tài khoản. Tùy chọn chỉ ảnh hưởng thiết bị, như khóa sinh trắc học, lưu cục bộ theo tài khoản và thiết bị. Không lưu mật khẩu rõ.

### 6.3. Cấu hình hệ thống dành cho admin

Nếu đã có trang cấu hình hệ thống, thêm lối vào riêng từ khu vực quản trị.

Chỉ chỉnh các trường công khai được phép và đã có chức năng hỗ trợ. Không hiển thị hoặc cho sửa database password, JWT secret, khóa thanh toán hoặc service account trong app.

Các trạng thái MoMo/VNPAY/Google/Facebook/FCM có thể hiển thị thông tin khả dụng an toàn, nhưng secret vẫn được cấu hình bên ngoài theo tài liệu trước.

## 7. Đồng bộ và bảo toàn hệ thống

- Thêm đánh giá thành công: cập nhật trang đơn, Đánh giá của tôi, điểm trên card và chi tiết phòng.
- Admin ẩn/hiện lại: cập nhật thống kê công khai và danh sách theo quyền.
- Hoàn tất lưu trú: cập nhật chi tiết, list, bộ lọc, lịch sử, điều kiện đánh giá và thông báo nếu hệ thống có.
- Sửa tên/avatar: header Drawer và mọi trang dùng cùng profile cập nhật thống nhất.
- Đổi quyền/khóa tài khoản: refresh session, Drawer, route guard và backend cùng phản ánh.
- Logout: xóa trạng thái tài khoản, danh sách riêng, cài đặt theo tài khoản và pending navigation nhạy cảm.
- Giữ nguyên ràng buộc chống trùng lịch, tính giá, sổ thu/hoàn và logic thanh toán.
- Không đưa thông tin đánh giá hoặc cài đặt riêng của người khác vào cache dùng chung.

## 8. Kiểm thử bắt buộc

### Đánh giá

1. Khách không đăng nhập không gửi được.
2. Khách không đánh giá đơn người khác.
3. Đơn chưa hoàn tất/hủy/từ chối không đánh giá được.
4. Ngày trả đã qua nhưng chưa xác nhận hoàn tất vẫn không đủ điều kiện.
5. Số sao ngoài 1–5 hoặc nhận xét quá dài bị từ chối.
6. Hai request cùng đơn chỉ tạo một đánh giá.
7. Đánh giá không nhận xét vẫn được tính đúng.
8. Admin ẩn/hiện lại làm điểm, số lượng và phân bố cập nhật đúng.
9. Khách/nhân viên không gọi được API kiểm duyệt.
10. Không có email, điện thoại, mã đặt phòng trong response công khai.
11. Đánh giá thấp hợp lệ không bị tự động ẩn.
12. Hoàn tất lưu trú có quyền, điều kiện, transaction và lịch sử đúng.

### Drawer và Cài đặt

1. Cả ba vai trò và khách chưa đăng nhập có menu phù hợp.
2. Header hiển thị đúng avatar/tên/email/quyền.
3. Bấm header mở tài khoản hoặc đăng nhập đúng ngữ cảnh.
4. Không lặp mục bottom navigation không cần thiết.
5. Menu dài cuộn được, chữ lớn không tràn.
6. Back đóng Drawer trước, không tạo route trùng.
7. Đổi quyền/logout không còn menu hoặc dữ liệu cũ.
8. Cài đặt cá nhân không ảnh hưởng tài khoản khác.
9. Nhân viên/khách không sửa cấu hình toàn khách sạn.
10. Các trạng thái quyền bị từ chối, chưa cấu hình và thiết bị không hỗ trợ được phân biệt.
11. Tất cả thành phần giữ theme TTTP.

Chạy kiểm thử backend trên database test riêng, Flutter tests phù hợp và `flutter analyze`. Không reset database người dùng.

## 9. Thứ tự thực hiện và báo cáo kết quả

1. Kiểm tra hiện trạng và xác định service/trang có thể tái sử dụng.
2. Bổ sung điều kiện hoàn tất lưu trú và dữ liệu/API đánh giá.
3. Tích hợp đánh giá vào đơn, card phòng và chi tiết phòng.
4. Làm quản trị kiểm duyệt và cập nhật thống kê.
5. Refactor Drawer dùng chung, header tài khoản và menu theo quyền.
6. Tích hợp Cài đặt cá nhân/cấu hình hệ thống theo phạm vi thực tế.
7. Kiểm thử hồi quy và kiểm tra giao diện trên điện thoại.

Sau khi hoàn thành, cập nhật `docs/screens.md`, tài liệu API và checklist kiểm thử. Báo rõ chức năng đã hoạt động thật, migration đã chạy, kết quả kiểm thử và phần còn giới hạn; không coi màn hình chưa nối backend là đã hoàn thành.

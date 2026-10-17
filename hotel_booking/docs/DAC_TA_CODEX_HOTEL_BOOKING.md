# Đặc tả triển khai Hotel Booking dành cho Codex

Ngày chốt: 17/10/2026. Ngôn ngữ trao đổi và giao diện: tiếng Việt.

## 1. Lệnh thực hiện và cách làm việc

Hãy trực tiếp xây dựng dự án theo đặc tả này trong workspace đang mở. Đây là yêu cầu triển khai mã nguồn hoạt động, không chỉ viết kế hoạch hoặc ví dụ. Trước tiên đọc các hướng dẫn AGENTS.md có áp dụng và kiểm tra mã nguồn hiện có. Nếu đã có backend/main.py, môi trường Python hoặc dự án Flutter, tiếp tục từ hiện trạng; không xóa, ghi đè hay tạo dự án lồng nhau ngoài ý muốn.

Tài liệu này chốt lựa chọn mới nhất: Flutter/Dart + Python/FastAPI + PostgreSQL. Những hướng dẫn cũ về C#, Firebase hoặc Supabase không còn là lựa chọn triển khai. Nếu người dùng cung cấp chỉ dẫn mới hơn, làm theo chỉ dẫn mới và cập nhật tài liệu tương ứng.

Tự thực hiện các lựa chọn nhỏ hợp lý trong phạm vi. Chỉ hỏi khi thiếu thông tin thực sự ngăn tiến độ, có xung đột yêu cầu quan trọng hoặc cần thao tác phá hủy dữ liệu. Không yêu cầu người dùng xác nhận lại các quyết định đã chốt. Khi thiếu PostgreSQL hoặc thiết bị Android, vẫn hoàn thiện phần mã không phụ thuộc, ghi rõ phần chưa kiểm chứng; không thay database bằng SQLite để tuyên bố hoàn thành.

Triển khai tuần tự theo các mốc ở cuối tài liệu. Mỗi mốc phải có mã chạy được và kiểm tra phù hợp. Cập nhật ngắn gọn tiến độ. Không dừng sau khi chỉ tạo khung dự án; tiếp tục các mốc trong điều kiện công cụ cho phép, trừ khi người dùng yêu cầu dừng. Không báo đã chạy kiểm thử nếu chưa chạy. Không tự triển khai công khai, mua dịch vụ hoặc tạo tài khoản ngoài.

## 2. Bối cảnh và kết quả cần đạt

Đồ án môn Lập trình trên thiết bị di động, nhóm 4 thành viên. Ứng dụng Android đặt phòng cho MỘT khách sạn, phục vụ khách hàng, lễ tân và quản lý. Mục tiêu là luồng đặt phòng hoàn chỉnh, dữ liệu tập trung, chống trùng lịch kể cả yêu cầu đồng thời, phân quyền backend và lịch sử thay đổi có truy vết.

Một phiếu đặt tương ứng đúng một phòng vật lý và một khoảng lưu trú. Loại phòng chứa giá và các đặc tính dùng chung; phòng vật lý chứa số phòng cụ thể. Đặt nhiều phòng tạo nhiều phiếu độc lập; không xây giỏ hàng đặt nhiều phòng.

Sản phẩm gồm mã nguồn backend, Flutter mobile, migration PostgreSQL, dữ liệu demo, kiểm thử nghiệp vụ, tài liệu chạy trên Windows và cấu hình mẫu không chứa bí mật. APK được tạo khi môi trường build Android cho phép.

## 3. Công nghệ bắt buộc

| Thành phần | Lựa chọn |
| --- | --- |
| Mobile | Flutter, Dart, Material 3 |
| State | Provider, ChangeNotifier |
| HTTP và JSON | package http, dart:convert |
| Lưu token | flutter_secure_storage |
| Định dạng ngày tiền | intl |
| Backend | Python 3.13, FastAPI, Pydantic |
| ORM và driver | SQLAlchemy 2, psycopg 3; session đồng bộ |
| Database | PostgreSQL 18, theo cập nhật trực tiếp của người dùng ngày 17/10/2026 |
| Migration | Alembic |
| Cấu hình | pydantic-settings, biến môi trường, .env |
| Mật khẩu | pwdlib với Argon2 |
| Token | PyJWT, JWT bearer |
| API docs | OpenAPI và Swagger UI tại /docs |
| Backend tests | pytest, httpx hoặc TestClient |
| IDE mục tiêu | VS Code; Android Studio cung cấp Android SDK và emulator |

Không dùng Firebase, Supabase SDK, Django, FastAPI thay bằng framework khác, hoặc C# cho backend. Không dùng Flutter kết nối PostgreSQL trực tiếp. Không thêm Docker, Redis, Celery, microservice, WebSocket hoặc kiến trúc nhiều tầng quá mức chỉ để làm khung. Không dùng Bloc/Riverpod thay Provider. Nếu phụ thuộc buộc thay đổi phiên bản, giải thích và cập nhật hướng dẫn; không tự đổi bộ công nghệ.

Flutter gửi HTTP/HTTPS và nhận JSON từ FastAPI. Chỉ backend có DATABASE_URL và khóa ký JWT. Backend triển khai bằng router, schema, service và model rõ ràng; không bắt buộc generic repository hoặc abstraction cho mọi thao tác.

## 4. Cấu trúc thư mục

```text
HotelBooking/
  backend/
    app/
      main.py
      api/                 # router auth, users, rooms, bookings, staff
      core/                # settings, security, errors, auth dependencies
      db/                  # engine, session, Base
      models/              # SQLAlchemy models
      schemas/             # Pydantic request và response
      services/            # nghiệp vụ và transaction
    alembic/
      versions/
    tests/
    uploads/               # ảnh demo; file sinh ra không commit tùy tiện
    alembic.ini
    requirements.txt
    .env.example
    README.md
  mobile/
    lib/
      main.dart
      app/                 # route, theme, khởi tạo provider
      core/                # constants, errors, format, API config
      models/
      services/            # ApiService, TokenStorage
      repositories/
      providers/
      screens/auth/
      screens/customer/
      screens/staff/
      widgets/
    test/
    integration_test/
    pubspec.yaml
  docs/
    api.md
    business_rules.md
    test_cases.md
  .gitignore
  README.md
```

Nếu main.py cũ ở gốc backend đã có /health, có thể chuyển vào app/main.py và cập nhật lệnh chạy. Không duy trì hai app khác nhau gây nhầm. Không commit .venv, .env, token, log nhạy cảm hoặc build output.

## 5. Người dùng và quyền

- Khách chưa đăng nhập: xem danh mục, tìm phòng trống, xem chi tiết; phải đăng nhập để đặt.
- Khách hàng: đăng ký, đăng nhập, xem/sửa hồ sơ của mình; tạo, xem và hủy phiếu của mình; xem lịch sử phiếu của mình.
- Lễ tân: đăng nhập bằng tài khoản được cấp; xem và lọc toàn bộ phiếu, xác nhận hoặc từ chối phiếu chờ. Không quản lý danh mục hoặc tự cấp quyền.
- Quản lý: mọi quyền lễ tân; thêm/sửa/ẩn loại phòng và phòng; quản lý tiện nghi, ảnh và lịch tạm ngừng.
- Tài khoản nhân viên và chức vụ được cấp bằng CLI quản trị backend hoặc seed tin cậy. Không có đăng ký nhân viên công khai; không cần màn hình quản trị tài khoản nhân sự trong bản cơ sở.

Loại tài khoản gồm KHACH_HANG và NHAN_VIEN. Quyền nhân viên lấy từ CHUC_VU với ma_quyen LE_TAN hoặc QUAN_LY. Mỗi tài khoản thuộc đúng một loại hồ sơ. Không lấy role, ma_kh hoặc nhan_vien_xu_ly từ client để tin cậy. UI ẩn chức năng theo quyền nhưng API vẫn bắt buộc kiểm tra quyền.

## 6. Phạm vi không triển khai

Không làm nhiều khách sạn, thanh toán trực tuyến, đặt cọc, hóa đơn VAT, check-in/check-out, dọn phòng, dịch vụ phát sinh, quản lý giấy tờ tùy thân, giá theo mùa, OTA, chat, AI, mã giảm giá, push notification hoặc đăng nhập Google. Không thêm các chức năng này để thay cho hoàn thiện nghiệp vụ cốt lõi.

Ảnh đại diện và gallery dùng chung theo loại phòng, không tạo thêm bảng ảnh riêng từng phòng. Không tích hợp gửi email xác minh/khôi phục mật khẩu trong bản cơ sở; không hiển thị nút hứa có các chức năng chưa triển khai.

## 7. Quy tắc nghiệp vụ chính xác

### 7.1. Ngày, khoảng ở và khả dụng

- Ngày nhận không trước ngày hiện tại theo Asia/Ho_Chi_Minh tại thời điểm server xử lý.
- Ngày trả lớn hơn ngày nhận. Từ 1 đến 30 đêm.
- Lưu DATE cho ngày lưu trú. Khoảng ở là [ngay_nhan, ngay_tra), không chiếm ngày trả.
- Hai khoảng giao nhau khi A.ngay_nhan < B.ngay_tra và B.ngay_nhan < A.ngay_tra.
- Phiếu A trả 22/11, phiếu B nhận 22/11: được phép.
- Khả dụng tính theo phòng đang kinh doanh, loại đang kinh doanh, sức chứa, phiếu giữ chỗ giao lịch và lịch tạm ngừng đang hiệu lực.
- Không dùng một cột trạng thái trống/bận hiện tại để suy ra khả dụng trong tương lai.
- Số khách ít nhất 1 và không lớn hơn sức chứa loại phòng.
- Khoảng tạm ngừng cũng dùng [tu_ngay, den_ngay), den_ngay > tu_ngay.
- Không tạo/sửa kỳ tạm ngừng giao với phiếu giữ chỗ; không tạo phiếu giao với kỳ tạm ngừng.
- Tắt kinh doanh phòng/loại chỉ chặn đặt mới; không tự hủy các phiếu đã có. Không cho thay đổi loại phòng của phòng đang có phiếu giữ chỗ với ngày trả sau ngày hiện tại; báo xung đột, tránh đổi đặc tính đã cam kết. Sửa sức chứa loại phòng cũng phải từ chối nếu khiến phiếu giữ chỗ chưa hết kỳ lưu trú vượt sức chứa.

### 7.2. Trạng thái phiếu

| Trạng thái trước | Thao tác | Trạng thái sau | Ai làm |
| --- | --- | --- | --- |
| Chưa có | Tạo phiếu hợp lệ | CHO_XAC_NHAN | Khách |
| CHO_XAC_NHAN | Xác nhận | DA_XAC_NHAN | Lễ tân hoặc quản lý |
| CHO_XAC_NHAN | Từ chối và có lý do | DA_TU_CHOI | Lễ tân hoặc quản lý |
| CHO_XAC_NHAN | Hủy trước hạn | DA_HUY | Khách sở hữu |
| DA_XAC_NHAN | Hủy trước hạn | DA_HUY | Khách sở hữu |

CHO_XAC_NHAN và DA_XAC_NHAN đều giữ phòng ngay từ lúc tạo. DA_HUY và DA_TU_CHOI không giữ phòng. Không tự hết hạn phiếu chờ trong bản này; không có lịch tác vụ dọn phiếu. Không chuyển trạng thái khác ngoài bảng trên, không khôi phục phiếu đã hủy/từ chối. Phiếu giữ trạng thái xác nhận khi qua ngày lưu trú vì không làm check-out.

Hạn hủy: trước 00:00 ngày nhận theo giờ Việt Nam, tức ngày hiện tại ở Việt Nam phải nhỏ hơn ngay_nhan. Nhân viên chỉ xác nhận/từ chối phiếu chờ chưa đến ngày nhận; sau hạn này trả lỗi nghiệp vụ, không tự sửa lịch sử. Không sửa phòng, ngày ở, số khách hoặc giá sau khi tạo; thay đổi cần hủy hợp lệ và đặt lại.

### 7.3. Tiền và dữ liệu lịch sử

Server đọc gia_co_ban hiện hành của loại phòng, chốt don_gia_moi_dem, tính tong_tien = số đêm × đơn giá. Dùng Decimal/NUMERIC; API trả số nguyên VND. Giá thay đổi sau đó không đổi phiếu cũ. Báo giá trước khi đặt là dự kiến; thao tác đặt tính lại và trả giá đã chốt, UI hiển thị kết quả thật.

Tạo phiếu và mọi chuyển trạng thái thành công ghi LICH_SU_DAT_PHONG trong cùng transaction. Người thực hiện lấy từ phiên xác thực. Lưu tên và điện thoại liên hệ tại thời điểm đặt; sửa hồ sơ sau đó không thay dữ liệu liên hệ phiếu cũ.

Không xóa cứng phiếu, lịch sử, tài khoản hoặc phòng đã phát sinh nghiệp vụ qua API. Sử dụng cờ hoạt động/kinh doanh. Mọi thao tác thất bại rollback, không để lịch sử hoặc hồ sơ mồ côi.

## 8. Cơ sở dữ liệu gồm đúng 12 bảng cốt lõi

Tên bảng và cột dùng snake_case, chữ thường không dấu. Tên class Python/Dart có thể dùng tiếng Anh rõ nghĩa. Nhất quán tên JSON bên dưới, không trộn room_id với ma_phong trong payload cùng API.

Quy ước: PK khóa chính; FK khóa ngoại; ? cho phép NULL. BIGINT tự tăng bằng identity; UUID sinh ở server; TIMESTAMPTZ mặc định now(). Mặc định boolean nêu rõ trong migration. Tên schema public.

### 8.1. tai_khoan

- id UUID PK.
- email VARCHAR(254) NOT NULL UNIQUE, trim và chuyển chữ thường trước khi lưu; CHECK email = lower(trim(email)).
- mat_khau_bam TEXT NOT NULL, Argon2 có salt, tuyệt đối không serialize ra response.
- loai_tai_khoan VARCHAR(20) NOT NULL CHECK KHACH_HANG hoặc NHAN_VIEN.
- dang_hoat_dong BOOLEAN NOT NULL DEFAULT true.
- ngay_tao TIMESTAMPTZ NOT NULL.

### 8.2. chuc_vu

- ma_cv BIGINT PK; ten_chuc_vu VARCHAR(80) NOT NULL.
- ma_quyen VARCHAR(20) UNIQUE NOT NULL CHECK LE_TAN hoặc QUAN_LY.
- dang_su_dung BOOLEAN NOT NULL DEFAULT true.

### 8.3. khach_hang

- id UUID PK đồng thời FK tai_khoan.id.
- ho_ten VARCHAR(120) NOT NULL; so_dien_thoai VARCHAR(20)?; ngay_tao TIMESTAMPTZ.

### 8.4. nhan_vien

- id UUID PK đồng thời FK tai_khoan.id.
- ho_ten VARCHAR(120) NOT NULL; ma_cv BIGINT NOT NULL FK chuc_vu.
- dang_hoat_dong BOOLEAN NOT NULL DEFAULT true; ngay_tao TIMESTAMPTZ.

Một tài khoản không có cả hai hồ sơ. Thực thi kiểm tra loại tài khoản và đúng một hồ sơ bằng deferred constraint trigger ở PostgreSQL, kiểm tra đến cuối transaction để cho phép tạo tài khoản rồi hồ sơ. Trigger phải kiểm tra cả thay đổi bảng tài khoản và hai bảng hồ sơ. Không chỉ dựa vào UI. Không cho API đổi loại tài khoản.

### 8.5. loai_phong

- ma_lp BIGINT PK; ten_loai VARCHAR(100) NOT NULL UNIQUE; mo_ta TEXT?.
- gia_co_ban NUMERIC(12,0) NOT NULL CHECK >= 0.
- suc_chua SMALLINT NOT NULL CHECK > 0.
- dien_tich_m2 NUMERIC(6,1)? CHECK > 0; so_giuong SMALLINT? CHECK > 0.
- dang_kinh_doanh BOOLEAN NOT NULL DEFAULT true.

### 8.6. phong

- ma_phong BIGINT PK; so_phong VARCHAR(20) NOT NULL UNIQUE.
- ma_lp BIGINT NOT NULL FK loai_phong; tang SMALLINT?; ghi_chu TEXT?.
- dang_kinh_doanh BOOLEAN NOT NULL DEFAULT true.

### 8.7. tien_nghi

- ma_tn BIGINT PK; ten_tien_nghi VARCHAR(100) NOT NULL UNIQUE; bieu_tuong VARCHAR(80)?.

### 8.8. loai_phong_tien_nghi

- ma_lp BIGINT FK loai_phong; ma_tn BIGINT FK tien_nghi.
- PK kép (ma_lp, ma_tn), cả hai NOT NULL.

### 8.9. anh_loai_phong

- ma_anh BIGINT PK; ma_lp BIGINT NOT NULL FK loai_phong.
- duong_dan TEXT NOT NULL; la_anh_bia BOOLEAN NOT NULL DEFAULT false.
- thu_tu SMALLINT NOT NULL DEFAULT 0 CHECK >= 0.
- Partial UNIQUE index trên ma_lp WHERE la_anh_bia để mỗi loại có tối đa một ảnh bìa. Nếu chưa có ảnh bìa, UI dùng ảnh đầu hoặc placeholder.

### 8.10. phieu_dat_phong

- ma_pdp UUID PK; ma_kh UUID NOT NULL FK khach_hang.id; ma_phong BIGINT NOT NULL FK phong.
- ngay_nhan DATE NOT NULL; ngay_tra DATE NOT NULL; CHECK ngay_tra > ngay_nhan và số đêm <= 30.
- so_khach SMALLINT NOT NULL CHECK > 0.
- don_gia_moi_dem NUMERIC(12,0) NOT NULL CHECK >= 0.
- tong_tien NUMERIC(14,0) NOT NULL CHECK >= 0 và bằng đơn giá × (ngay_tra - ngay_nhan).
- trang_thai VARCHAR(20) NOT NULL DEFAULT CHO_XAC_NHAN, CHECK trong 4 trạng thái ở mục 7.
- ten_lien_he VARCHAR(120) NOT NULL; sdt_lien_he VARCHAR(20) NOT NULL; ghi_chu TEXT?.
- nhan_vien_xu_ly UUID? FK nhan_vien.id; ly_do_tu_choi TEXT?.
- ngay_tao TIMESTAMPTZ; ngay_cap_nhat TIMESTAMPTZ; ngay_xu_ly TIMESTAMPTZ?.
- DA_TU_CHOI phải có lý do không trắng. Backend cập nhật ngay_cap_nhat và ngay_xu_ly khi phù hợp.

### 8.11. lich_su_dat_phong

- ma_ls BIGINT PK; ma_pdp UUID NOT NULL FK phieu_dat_phong.
- tu_trang_thai VARCHAR(20)?; NULL chỉ khi tạo mới.
- den_trang_thai VARCHAR(20) NOT NULL, CHECK trạng thái hợp lệ.
- nguoi_thuc_hien UUID NOT NULL FK tai_khoan.id; ly_do TEXT?.
- thoi_diem TIMESTAMPTZ NOT NULL.

### 8.12. phong_tam_ngung

- ma_ngung BIGINT PK; ma_phong BIGINT NOT NULL FK phong.
- tu_ngay DATE NOT NULL; den_ngay DATE NOT NULL CHECK den_ngay > tu_ngay.
- ly_do TEXT NOT NULL, không trắng; dang_hieu_luc BOOLEAN NOT NULL DEFAULT true.
- nguoi_tao UUID NOT NULL FK tai_khoan.id; ngay_tao TIMESTAMPTZ.

Không tạo chi_tiet_phieu_dat_phong vì mỗi phiếu chỉ một phòng. Không thêm bảng hóa đơn/thanh toán trong bản này. Các bảng phiên bản nội bộ của Alembic không tính vào 12 bảng nghiệp vụ.

### 8.13. Chỉ mục và chống trùng tại database

Migration tạo extension btree_gist và exclusion constraint tương đương:

```sql
ALTER TABLE public.phieu_dat_phong
ADD CONSTRAINT ex_phong_khong_trung
EXCLUDE USING gist (
  ma_phong WITH =,
  daterange(ngay_nhan, ngay_tra, '[)') WITH &&
)
WHERE (trang_thai IN ('CHO_XAC_NHAN', 'DA_XAC_NHAN'));

ALTER TABLE public.phong_tam_ngung
ADD CONSTRAINT ex_ngung_khong_trung
EXCLUDE USING gist (
  ma_phong WITH =,
  daterange(tu_ngay, den_ngay, '[)') WITH &&
)
WHERE (dang_hieu_luc);
```

Tạo index FK, phiếu theo (ma_kh, ngay_tao), theo (trang_thai, ngay_tao), lịch sử theo (ma_pdp, thoi_diem) và các FK liên kết tiện nghi/ảnh. Hai constraint trên KHÔNG tự ngăn xung đột giữa hai bảng; phải có transaction khóa phòng ở mục 9.

## 9. Giao dịch và xử lý cạnh tranh bắt buộc

Dùng transaction thật trong PostgreSQL, mức READ COMMITTED. Không dùng khóa Python trong RAM vì không bảo vệ nhiều process.

Tạo phiếu:

1. Xác thực tài khoản khách còn hoạt động.
2. Mở transaction, khóa hàng PHONG bằng SELECT FOR UPDATE.
3. Đọc loại phòng và giá bằng SELECT FOR SHARE để phối hợp thao tác sửa giá/loại; kiểm tra cờ hoạt động và sức chứa.
4. Kiểm tra ngày hiện tại giờ Việt Nam và khoảng ở.
5. Kiểm tra phiếu giữ chỗ và lịch tạm ngừng giao khoảng.
6. Tính giá server; INSERT phiếu và lịch sử tạo.
7. Commit, chỉ sau đó trả 201.
8. Nếu constraint 23P01 hoặc xung đột nghiệp vụ: rollback, trả 409 phù hợp.

Tạo/sửa/dừng kỳ tạm ngừng: khóa PHONG trước, kiểm tra chéo các phiếu và kỳ tạm ngừng, ghi trong transaction. Không hỗ trợ chuyển kỳ tạm ngừng sang phòng khác qua PATCH; muốn đổi phòng thì dừng kỳ cũ, tạo kỳ mới.

Hủy/duyệt/từ chối phiếu: đọc mã phòng, khóa PHONG trước rồi khóa PHIEU_DAT_PHONG; đọc lại quyền/trạng thái/hạn thao tác trong transaction; ghi thay đổi và lịch sử. Giữ thứ tự khóa thống nhất. Các service cập nhật loại phòng, sức chứa hoặc cờ kinh doanh phải phối hợp với khóa trên loại phòng; tránh lấy khóa theo thứ tự ngược gây deadlock. Khi phải khóa nhiều phòng, khóa theo ma_phong tăng dần.

Không commit trong helper ghi lịch sử tách khỏi transaction nghiệp vụ. Không trả raw SQL hoặc stack trace ra client. Kiểm thử concurrency bằng các session/connection độc lập trên PostgreSQL thật, không chỉ mock.

## 10. Xác thực và an toàn dữ liệu

- Register JSON: ho_ten, email, mat_khau, so_dien_thoai tùy chọn. Mật khẩu 8–128 ký tự, không cắt ngắn âm thầm. Trim tên/email, không tự trim mật khẩu.
- Email đăng ký trùng: 409 EMAIL_ALREADY_EXISTS. Tạo tài khoản và hồ sơ trong cùng transaction.
- Login JSON: email, mat_khau. Không dùng OAuth2 password-form nếu hợp đồng đã chọn JSON.
- JWT HS256, sub là chuỗi UUID tài khoản, exp và iat; allowlist thuật toán HS256. JWT_SECRET đọc từ env, không có giá trị production mặc định.
- Access token hết hạn sau 60 phút. Chưa làm refresh token. Mỗi request bảo vệ kiểm tra tài khoản/hồ sơ còn hoạt động và quyền hiện hành.
- Logout xóa token phía client; bản cơ sở không có danh sách thu hồi token. Không mô tả logout là vô hiệu hóa mọi bản token trên server.
- GET /users/me trả hồ sơ và quyền hiện hành, không trả hash. PATCH chỉ sửa ho_ten và so_dien_thoai; không cho sửa email, vai trò, id hoặc trạng thái hoạt động.
- CORS chỉ cần cấu hình khi chạy trình duyệt, không phải cơ chế phân quyền Android. Không dùng allow-all CORS như một cách sửa lỗi mạng không xác định.
- Tài khoản SQL của backend có quyền tối thiểu; thao tác migration/extension có thể dùng tài khoản phát triển riêng đủ quyền.
- .env.example chỉ chứa giá trị mẫu; không log mật khẩu, token, DATABASE_URL có mật khẩu hoặc request đăng nhập.
- Không tự tắt bảo mật để vượt lỗi; HTTP chỉ phục vụ dev, triển khai thật dùng HTTPS.

## 11. Hợp đồng API

Không thêm tiền tố /api/v1 trong bản cơ sở để tránh sai URL so với danh mục bên dưới. UUID dùng chuỗi; mã số dùng integer. Ngày YYYY-MM-DD; timestamp ISO 8601 UTC có Z hoặc +00:00. Tiền là integer VND. Response không serialize trực tiếp model có trường nhạy cảm; dùng Pydantic response schema.

### 11.1. Endpoint

| Method | Path | Chức năng và quyền |
| --- | --- | --- |
| GET | /health | Công khai, server liveness, không lộ cấu hình |
| POST | /auth/register | Đăng ký khách, trả 201 và hồ sơ công khai, không tự đăng nhập |
| POST | /auth/login | Trả token, 200 |
| GET | /users/me | Hồ sơ và quyền hiện hành |
| PATCH | /users/me | Sửa tên và số điện thoại của chính mình |
| GET | /room-types | Loại đang kinh doanh, công khai |
| GET | /rooms | Phòng đang kinh doanh, phân trang |
| GET | /rooms/available | Tìm phòng theo ngày/sức chứa/giá/loại |
| GET | /rooms/{room_id} | Chi tiết phòng cùng loại, ảnh và tiện nghi |
| POST | /rooms/{room_id}/quote | Báo giá và khả dụng dự kiến |
| POST | /bookings | Khách tạo phiếu, trả 201 |
| GET | /bookings/my | Danh sách phiếu của khách |
| GET | /bookings/{booking_id} | Chi tiết và lịch sử, chủ phiếu hoặc nhân viên |
| PATCH | /bookings/{booking_id}/cancel | Chủ phiếu hủy, ly_do tùy chọn |
| GET | /staff/bookings | Nhân viên xem và lọc tất cả phiếu |
| PATCH | /staff/bookings/{booking_id}/confirm | Xác nhận phiếu chờ |
| PATCH | /staff/bookings/{booking_id}/reject | Từ chối phiếu chờ, ly_do bắt buộc |
| GET | /staff/room-types | Quản lý đọc cả loại đang ẩn |
| POST | /staff/room-types | Quản lý tạo loại |
| PATCH | /staff/room-types/{id} | Quản lý sửa/ẩn loại |
| GET | /staff/rooms | Quản lý đọc cả phòng đang ẩn |
| POST | /staff/rooms | Quản lý tạo phòng |
| PATCH | /staff/rooms/{id} | Quản lý sửa/ẩn phòng |
| GET | /staff/amenities | Quản lý xem tiện nghi |
| POST | /staff/amenities | Quản lý tạo tiện nghi |
| PATCH | /staff/amenities/{id} | Quản lý sửa tiện nghi |
| PUT | /staff/room-types/{id}/amenities | Thay tập tiện nghi bằng danh sách ma_tn không trùng |
| POST | /staff/room-types/{id}/images | Upload ảnh multipart, thu_tu và la_anh_bia |
| PATCH | /staff/images/{id} | Sửa thu_tu/la_anh_bia |
| DELETE | /staff/images/{id} | Xóa ảnh, trả 204 |
| GET | /staff/room-closures | Quản lý xem lịch ngừng, có filter phòng/ngày |
| POST | /staff/room-closures | Tạo kỳ tạm ngừng |
| PATCH | /staff/room-closures/{id} | Sửa kỳ hoặc dang_hieu_luc=false |

Các endpoint GET quản trị bổ sung là cần thiết để giao diện sửa được cả dữ liệu đang ẩn. Không triển khai chức năng xóa cứng danh mục có liên kết. Định nghĩa route /rooms/available và /bookings/my trước các route có path parameter để không bị nhận nhầm.

### 11.2. Truy vấn và phân trang

GET /rooms/available: ngay_nhan, ngay_tra, so_khach bắt buộc; ma_lp, gia_min, gia_max tùy chọn. Lọc giá theo đơn giá mỗi đêm, không phải tổng kỳ. Kiểm tra gia_min <= gia_max. Sắp xếp mặc định theo giá tăng rồi ma_phong tăng để ổn định.

Danh sách: page mặc định 1, page_size mặc định 20, tối đa 100. Response {items: [...], page: 1, page_size: 20, total: 12}. GET /room-types có thể dùng cùng cấu trúc. total là tổng bản ghi sau lọc trước phân trang. /bookings/my và /staff/bookings cho filter trang_thai, ngay_nhan_tu, ngay_nhan_den, sắp xếp ngay_tao giảm rồi ma_pdp ổn định.

Room response thống nhất có ma_phong, so_phong, tang, ma_lp, ten_loai, gia_co_ban, suc_chua, dang_kinh_doanh; chi tiết bổ sung mo_ta, dien_tich_m2, so_giuong, tien_nghi và hinh_anh. Không trả ghi_chu nội bộ trong API công khai.

### 11.3. Payload ví dụ

POST /auth/login:

```json
{"email":"khach@example.com","mat_khau":"mat-khau-do-nguoi-dung-nhap"}
```

Response login:

```json
{"access_token":"JWT_THAT_DO_SERVER_TAO","token_type":"bearer","expires_in":3600}
```

POST /bookings:

```json
{
  "ma_phong": 1,
  "ngay_nhan": "2026-11-20",
  "ngay_tra": "2026-11-22",
  "so_khach": 2,
  "ten_lien_he": "Nguyễn Văn A",
  "sdt_lien_he": "0901234567",
  "ghi_chu": null
}
```

Ngày ví dụ chỉ minh họa; seed và test phải dùng ngày tương lai tính từ thời điểm chạy. ma_phong là PK, so_phong là số phòng hiển thị, không đồng nhất hai giá trị.

Response 201 gồm ma_pdp UUID thật, ma_phong, so_phong, ma_kh, ngay_nhan, ngay_tra, so_dem, so_khach, don_gia_moi_dem, tong_tien, trang_thai, ten_lien_he, sdt_lien_he, ghi_chu, ngay_tao, ngay_cap_nhat. Chi tiết thêm lịch sử có người thực hiện được trình bày an toàn; không lộ email/tài khoản khác ngoài thông tin cần thiết.

POST quote nhận ngay_nhan, ngay_tra, so_khach; trả ma_phong, ngày, so_dem, don_gia_moi_dem, tong_tien, kha_dung. Quote không giữ phòng. Không tin số tiền do client gửi. Schema ghi nghiệp vụ dùng extra='forbid' để từ chối các trường như ma_kh, trang_thai hoặc giá bị chèn thêm.

### 11.4. Lỗi

```json
{"error":{"code":"ROOM_UNAVAILABLE","message":"Phòng không còn trống trong khoảng ngày đã chọn"}}
```

| HTTP | code ví dụ | Khi dùng |
| --- | --- | --- |
| 400 | INVALID_OPERATION | Quy tắc nghiệp vụ không cho thao tác, ví dụ quá hạn hủy |
| 401 | UNAUTHENTICATED | Thiếu/sai/hết hạn token hoặc phiên không còn hợp lệ |
| 403 | FORBIDDEN | Sai vai trò |
| 404 | NOT_FOUND | Không tồn tại hoặc không nằm trong phạm vi sở hữu |
| 409 | ROOM_UNAVAILABLE, STATE_CONFLICT, EMAIL_ALREADY_EXISTS | Trùng lịch, trạng thái bị đổi, email trùng |
| 422 | VALIDATION_ERROR | Thiếu trường, ngày/giá trị không hợp lệ |
| 500 | INTERNAL_ERROR | Lỗi ngoài dự kiến, thông báo chung |

Tùy biến handler validation để cùng định dạng; có thể thêm details chỉ gồm tên trường và thông báo, không chứa input mật khẩu/token. Với khách A đọc/hủy phiếu khách B trả 404 nhất quán. Lỗi 401 ở Flutter xóa phiên và đưa về đăng nhập; 403 hiển thị không đủ quyền, không giả báo thành công.

## 12. Ảnh phòng

Lưu file vào backend/uploads với tên UUID, không dùng nguyên tên file người dùng làm đường dẫn. Cho phép JPEG/PNG/WebP, kiểm tra nội dung ảnh thực bằng thư viện thích hợp và giới hạn 5 MiB mỗi file. Không chỉ tin Content-Type hoặc phần mở rộng. Chỉ QUAN_LY được upload/sửa/xóa. Không nhận đường dẫn tùy ý để đọc/xóa file ngoài uploads.

Phục vụ ảnh tại /uploads bằng static route; duong_dan có thể lưu đường dẫn tương đối /uploads/xxx.jpg. Flutter ghép với API origin, không lưu localhost vào bản ghi để thiết bị Android bị sai địa chỉ. Thay ảnh bìa trong transaction để không tạo hai ảnh bìa. Xử lý thất bại DB bằng dọn file vừa tạo; xóa record và file có xử lý lỗi rõ ràng. Ảnh lỗi/mất mạng phải có placeholder.

## 13. Flutter và giao diện

Giao diện tiếng Việt, Material 3, đơn giản, dễ dùng. Không dùng WebView thay app Flutter. Không yêu cầu thiết kế cầu kỳ trước khi nghiệp vụ hoạt động.

### 13.1. Màn hình

1. Đăng nhập: email, mật khẩu, ẩn/hiện mật khẩu, loading, lỗi, link đăng ký.
2. Đăng ký: họ tên, email, số điện thoại tùy chọn, mật khẩu, xác nhận mật khẩu; thành công về đăng nhập.
3. Trang chủ: các loại phòng, ảnh và tìm nhanh theo ngày.
4. Tìm phòng: date range, số khách, loại, khoảng đơn giá; danh sách có phân trang hoặc tải thêm.
5. Chi tiết phòng: số phòng, loại, gallery, tiện nghi, sức chứa, giá; nút đặt.
6. Xác nhận đặt: ngày, số đêm, số khách, liên hệ, báo giá, xác nhận gửi.
7. Đơn của tôi: lọc 4 trạng thái, mở chi tiết.
8. Chi tiết đơn: mã phiếu, phòng, ngày, giá chốt, trạng thái, lý do từ chối, lịch sử; nút hủy đúng điều kiện.
9. Hồ sơ: tên, điện thoại, email chỉ đọc, đăng xuất.
10. Nhân viên xem phiếu: lọc trạng thái/ngày, mở chi tiết, duyệt hoặc từ chối có lý do.
11. Quản lý loại phòng/phòng: danh sách gồm dữ liệu ẩn, thêm/sửa/ẩn, validator.
12. Quản lý tiện nghi và ảnh theo loại, chọn ảnh bìa/thứ tự.
13. Quản lý lịch tạm ngừng: danh sách, thêm/sửa/dừng hiệu lực, báo xung đột nếu có đơn.

Khách có thanh điều hướng Trang chủ, Đơn của tôi, Hồ sơ. Nhân viên có giao diện phù hợp quyền; quản lý có danh mục và lịch tạm ngừng. Không hiển thị nút không có chức năng hoặc dữ liệu mock như dữ liệu thật.

### 13.2. Dữ liệu và trạng thái

- Model Dart có toJson/fromJson rõ ràng; request DTO tách khỏi response model khi trường khác nhau.
- Gửi: object → toJson tạo Map → jsonEncode → HTTP body.
- Nhận: response.body → jsonDecode → fromJson; danh sách đọc đúng items.
- ApiService quản lý base URL, header JSON/bearer, timeout và parse lỗi; không lặp HTTP trực tiếp trong từng widget.
- Provider quản lý phiên, tìm phòng và phiếu. Không gọi request lặp trong build().
- Hiển thị loading, rỗng, lỗi mạng, lỗi nghiệp vụ và thử lại. Khóa nút trong lúc gửi, kiểm tra mounted trước cập nhật UI sau await.
- Chỉ báo đặt thành công sau response thành công; nếu timeout sau gửi, ghi rõ chưa xác định kết quả và cho làm mới Đơn của tôi trước khi gửi lại. Không tự retry POST tạo phiếu.
- Sau tạo/hủy/duyệt, invalidate hoặc tải lại danh sách liên quan.
- Đồng bộ bằng làm mới khi quay lại màn hình và thao tác pull-to-refresh. Không yêu cầu realtime; không tuyên bố cập nhật tức thời nếu chưa có.
- Chuyển ngày DATE thành chuỗi yyyy-MM-dd không biến ngày lưu trú qua UTC làm lệch ngày. Timestamp được hiển thị giờ Việt Nam.
- Định dạng VND; validate phía client để hỗ trợ nhập liệu, server vẫn kiểm tra lại.
- Lưu token bằng secure storage, không SharedPreferences. Không in token vào console.
- Bổ sung package image_picker hoặc tương đương chỉ nếu cần thao tác chọn ảnh Android của màn hình quản lý; ghi rõ lý do.

## 14. Môi trường và lệnh chạy Windows

Người dùng đã có VS Code, Flutter và Android Studio; không mặc định đã cài Python/PostgreSQL hoặc đã tạo dự án. Kiểm tra công cụ trước, hướng dẫn bổ sung đúng phần thiếu. Không cài lại công cụ đang có.

PowerShell, từ thư mục backend:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Không đổi ExecutionPolicy vì các lệnh gọi trực tiếp Python của .venv. README phải chỉ rõ vị trí chạy mỗi lệnh, cách tạo database và user, cách tạo JWT_SECRET, điền .env, chạy seed, test và build.

.env.example có DATABASE_URL dạng postgresql+psycopg://USER:PASSWORD@localhost:5432/hotel_booking, JWT_SECRET mẫu cần thay, ACCESS_TOKEN_EXPIRE_MINUTES=60 và thư mục upload. Mã cấu hình từ chối chạy với JWT_SECRET rỗng; không hardcode mật khẩu. DATABASE_URL dùng ký tự đặc biệt cần encode đúng hoặc cấu hình xây URL an toàn.

Máy tính mở http://127.0.0.1:8000/docs. Android Studio emulator gọi http://10.0.2.2:8000. Điện thoại thật dùng IPv4 LAN máy backend, cùng Wi-Fi, cho phép cổng 8000 trên mạng riêng. localhost trên Android là chính Android.

Flutter cấu hình qua --dart-define=API_BASE_URL=http://10.0.2.2:8000, cấu hình một chỗ. Thêm android.permission.INTERNET. Chỉ cho cleartext HTTP trong cấu hình phát triển cần thiết; không mở rộng cấu hình release vô điều kiện. Tài liệu nêu bản release sử dụng HTTPS. Không mở cổng PostgreSQL cho điện thoại.

APK không chứa Python/PostgreSQL: backend cần chạy riêng với địa chỉ truy cập được. Không hứa cài APK là tự có backend.

## 15. Migration và dữ liệu demo

Alembic là nguồn quản lý lược đồ. Không gọi create_all thay thế migration khi khởi động app. Không tự drop/reset database nếu chưa được người dùng yêu cầu. Migration có upgrade/downgrade phù hợp; việc xóa dữ liệu khi downgrade phải được cảnh báo trong README.

Seed chạy bằng CLI rõ ràng, có thể chạy lại mà không nhân đôi danh mục/tài khoản, không tự chạy khi server khởi động. Dữ liệu:

- 2 chức vụ LE_TAN và QUAN_LY.
- 3 loại Standard, Deluxe, Family với giá và sức chứa khác nhau.
- 12 phòng vật lý, ít nhất 2 tầng.
- 6 tiện nghi, liên kết với loại phòng.
- 2 ảnh mỗi loại; ảnh có quyền sử dụng hoặc placeholder được ghi rõ, không bịa là ảnh khách sạn đã khảo sát.
- 3 tài khoản khách, 1 lễ tân, 1 quản lý; mật khẩu demo lấy từ biến môi trường hoặc tham số, băm qua cùng service. Không hardcode bí mật thật.
- 6 phiếu trải 4 trạng thái, có lịch sử nhất quán; 2 kỳ tạm ngừng không xung đột.
- Ngày seed dựa trên ngày hiện tại giờ Việt Nam để demo không hết hạn sau vài tuần.

## 16. Kiểm thử bắt buộc

Chạy kiểm thử nghiệp vụ database trên database PostgreSQL test riêng, tên hoặc cấu hình phân biệt rõ với dữ liệu người dùng. Từ chối chạy reset fixture trên database không được đánh dấu test. Không dùng SQLite làm bằng chứng kiểm tra exclusion constraint hoặc concurrency.

| Mã | Tình huống | Mong đợi |
| --- | --- | --- |
| TC01 | Đăng ký hợp lệ | Tạo tài khoản và hồ sơ cùng transaction |
| TC02 | Email khác hoa/thường đã có | 409, không nhân đôi |
| TC03 | Đăng nhập sai hoặc token hết hạn | 401, không lộ bí mật |
| TC04 | Chèn role/ma_kh/giá vào request | 422 hoặc từ chối, không nâng quyền |
| TC05 | Ngày trả <= nhận, quá khứ, hơn 30 đêm | Không tạo phiếu |
| TC06 | Khách vượt sức chứa | Không đặt được |
| TC07 | Tạo hợp lệ | 201, giá đúng, CHO_XAC_NHAN và lịch sử |
| TC08 | Giao phiếu chờ | 409 |
| TC09 | Giao phiếu đã xác nhận | 409 |
| TC10 | Giao phiếu đã hủy/từ chối | Được đặt nếu không vướng điều kiện khác |
| TC11 | Nhận đúng ngày phiếu trước trả | Được đặt |
| TC12 | Hai khách đồng thời đặt cùng phòng và kỳ | Chính xác một thành công; không hai phiếu giữ chỗ giao nhau |
| TC13 | Hai thao tác đồng thời tạo phiếu và kỳ ngừng cùng phòng/kỳ | Chỉ một nghiệp vụ chiếm lịch thành công |
| TC14 | Kỳ ngừng hiệu lực hoặc phòng/loại ẩn | Không đặt mới |
| TC15 | Hủy trước hạn | DA_HUY, log và giải phóng lịch |
| TC16 | Hủy khi đã đến ngày nhận giờ Việt Nam | Từ chối |
| TC17 | Xác nhận/từ chối phiếu chờ hợp lệ | Đúng trạng thái, người xử lý và lịch sử |
| TC18 | Hai người xử lý hoặc khách hủy cùng lúc | Không ghi đè trạng thái, chỉ chuyển hợp lệ một lần |
| TC19 | Khách A đọc/hủy phiếu B | 404, không đổi dữ liệu |
| TC20 | Khách/lễ tân gọi API quản lý | 403 |
| TC21 | Đổi giá loại sau đặt | Phiếu cũ giữ giá, phiếu mới dùng giá hiện hành |
| TC22 | Lỗi sau ghi phiếu trước ghi lịch sử | Rollback cả hai |
| TC23 | Tạo hồ sơ sai loại hoặc hai hồ sơ | Database từ chối khi commit |
| TC24 | Hai ảnh bìa cùng loại | Constraint ngăn, thao tác thay bìa nguyên tử |
| TC25 | Upload giả ảnh/quá dung lượng/path traversal | Từ chối an toàn |
| TC26 | Mất mạng/timeout khi gửi | UI không báo thành công giả hoặc tự gửi lặp |
| TC27 | Nhân viên xử lý rồi khách refresh | Hiển thị trạng thái thật từ backend |
| TC28 | Đăng xuất và mở lại app | Không dùng lại token đã xóa |
| TC29 | Giảm sức chứa không tương thích phiếu giữ chỗ | Từ chối thay đổi |

Các bài kiểm thử đồng thời phải dùng kết nối độc lập và phối hợp thời điểm khởi chạy để có cạnh tranh thật. Không viết bài test chỉ kiểm tra hàm mock trả đúng hằng số. Thêm unit/widget test có giá trị cho JSON, validator, loading và quyền điều hướng. Kiểm thử tối thiểu một luồng E2E khách đăng nhập → tìm → đặt → nhân viên xác nhận → khách làm mới thấy kết quả, có thể trình diễn hai tài khoản/thiết bị.

## 17. Các mốc triển khai

1. Kiểm tra workspace, tạo cấu trúc phù hợp, backend /health và cấu hình, .env.example, README chạy đầu tiên.
2. Tạo model, migration PostgreSQL đủ 12 bảng và constraint/trigger; kiểm tra migration trên database test sạch.
3. Đăng ký/đăng nhập/JWT/users/me, CLI cấp nhân viên và seed; kiểm tra phân quyền.
4. API danh mục, phòng trống và quote; triển khai service đặt/hủy/duyệt/từ chối với transaction; kiểm thử cạnh tranh trước khi làm UI đặt.
5. Khởi tạo hoặc tích hợp Flutter: ApiService, model JSON, token store, Provider, đăng nhập/đăng ký và danh sách phòng từ API thật.
6. Hoàn thiện luồng khách đặt, lịch sử, chi tiết, hủy và hồ sơ.
7. Hoàn thiện giao diện nhân viên, quản lý danh mục, tiện nghi/ảnh và lịch tạm ngừng; bổ sung API quản trị tương ứng trước khi nối UI.
8. Chạy kiểm thử tích hợp, flutter analyze, các test phù hợp, sửa lỗi, chuẩn bị dữ liệu demo và build APK nếu có môi trường.

Mỗi mốc cập nhật README và ghi phần đã kiểm chứng/chưa kiểm chứng. Không coi skeleton, mock data hoặc màn hình chưa nối API là chức năng hoàn thành. Khi gặp thiếu dịch vụ ngoài, ghi rõ lỗi thực tế, không giả kết quả.

## 18. Tiêu chí hoàn thành và báo cáo cuối cho người dùng

- Flutter chạy với backend thật và PostgreSQL thật cho các luồng chính.
- Đủ 12 bảng, migration, ràng buộc tài khoản, chống trùng và lịch sử.
- Quyền được kiểm tra tại server và theo chủ sở hữu.
- Không còn giá/trạng thái/vai trò do client quyết định, không kết nối database từ Flutter.
- Không có dữ liệu mock trong luồng production; seed demo được phân biệt rõ.
- Hướng dẫn Windows có thể làm theo từ clone/source mới, nêu rõ cách điền cấu hình và địa chỉ API emulator/điện thoại.
- Kiểm thử và phân tích tĩnh đã chạy có kết quả thật; nêu giới hạn môi trường còn lại.
- Không ghi bí mật vào repo; .gitignore phù hợp backend và Flutter.

Khi kết thúc, trả lời ngắn gọn bằng tiếng Việt: đã làm gì, cách chạy bằng lệnh cụ thể, kiểm thử nào đã chạy và kết quả, phần nào còn cần môi trường hoặc thông tin người dùng. Không chỉ trả một khối mã để người dùng tự chép nếu có quyền chỉnh file trực tiếp.

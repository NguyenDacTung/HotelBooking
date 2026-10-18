# Phòng 404 chưa trả nhưng vẫn đặt được — 18/10/2026

## Nguyên nhân

Phòng 404 có một đơn 17–18/10 ở trạng thái CHO_THANH_TOAN, chưa có thời điểm trả thực tế. Phòng có đánh giá từ một lượt lưu trú cũ đã hoàn tất, nhưng đánh giá không thể hiện khả dụng hiện tại.

Tìm kiếm và `check_room` trước đây chỉ kiểm tra giao khoảng ngày theo quy ước ngày đi không chiếm đêm kế tiếp. Vì vậy khi đến ngày trả dự kiến, khách cũ chưa hoàn tất trả vẫn có thể bị coi là không giao lịch. Báo giá, tạo đơn và xác nhận cho phép đi tiếp; bước nhận phòng có kiểm tra khách đang ở nên mới trả ROOM_OCCUPIED. API đề xuất đã chặn khách đang ở/chờ thanh toán, nhưng kiểm tra trước đó chỉ bao phủ đề xuất, bỏ sót tìm kiếm/báo giá/tạo đơn/xác nhận.

Đã tái hiện trực tiếp trên API đang chạy: tìm 21–22/10 vẫn có phòng 404 và quote trả `kha_dung=true`, dù đơn cũ chưa trả.

## Sửa

- Thêm điều kiện chung `physical_stay_exists` cho DANG_O/CHO_THANH_TOAN, không lấy ngày trả dự kiến thay cho trả thực tế.
- Tìm kiếm và đề xuất cùng loại phòng đang sử dụng. Thông tin chi tiết vẫn hiển thị DANG_SU_DUNG, không giấu lịch sử đánh giá.
- Báo giá, đặt của khách, đặt hộ và đổi phòng dùng chung `check_room`, chặn cả truy cập trực tiếp hoặc màn hình đã lưu kết quả cũ.
- Xác nhận đơn cũ kiểm tra lại khách đang sử dụng dưới khóa phòng; trả HTTP 409 ROOM_OCCUPIED, giữ nguyên trạng thái đơn nếu bị chặn. Nhận phòng tiếp tục giữ kiểm tra bảo vệ hiện có.
- Không migration, không tự trả phòng/thu tiền/hủy/chuyển các đơn 404 đã có. Các đơn cũ cần nhân viên xử lý đúng nghiệp vụ.

## Kiểm thử

- Bốn ca hồi quy PostgreSQL: DANG_O/CHO_THANH_TOAN × ngày trả dự kiến hôm nay/đã qua. Mỗi ca kiểm tra tìm hôm nay và tương lai, đề xuất, trạng thái phòng, quote, tạo đơn, đặt hộ, đổi phòng và xác nhận. Sau đó đi qua lập hóa đơn → thu đúng tiền → hoàn tất trả, kiểm tra phòng mở lại khả dụng và xác nhận được.
- Lượt đầu có 2 ca fixture sai tổng tiền khi đổi ngày; đã sửa dữ liệu fixture để giữ ràng buộc số đêm × giá. Không bỏ ràng buộc hoặc sửa database chính.
- Lượt toàn bộ sau sửa: **102/102 backend đạt**, gồm PostgreSQL/cạnh tranh. Wrapper đối chiếu toàn bộ hotel_booking không đổi trong kiểm thử.
- Backend đã được restart với API LAN thật. Cùng truy vấn 21–22/10: trước nạp có 404/quote true; sau nạp không có 404/quote false; chi tiết vẫn DANG_SU_DUNG. Các phòng khác, bao gồm 411, còn khả dụng; health/db 200.
- Đã thao tác thật trên SM A135F: Tìm phòng → Superior Double → ngày 21–22/10 → Tìm phòng. Có đúng hai phòng 504 và 412, không có 404. Ảnh `artifacts/QA-404-fix-search-future.png`. Không cần build/cài APK mới vì sửa ở backend. Đã trả lại cấu hình giữ sáng màn hình sau kiểm tra.
- Phòng 411 vẫn trống cho 18–19/10 và đã có đánh giá, phù hợp kịch bản tiến độ. Các đơn 404 đang có giữ nguyên; muốn nhận đơn mới phải hoàn tất trả lượt cũ, dọn phòng, hoặc chủ động đổi phòng cho đơn mới. Không tự hủy để tránh phát sinh phí hoặc sửa sổ tiền ngoài ý muốn của chủ dự án.

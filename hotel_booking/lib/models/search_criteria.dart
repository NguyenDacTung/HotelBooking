import '../core/config.dart';
import 'models.dart';

class SearchCriteria {
  final DateTime start, end;
  final int guests;
  final int? typeId, minPrice, maxPrice;
  const SearchCriteria({
    required this.start,
    required this.end,
    required this.guests,
    this.typeId,
    this.minPrice,
    this.maxPrice,
  });
  int get nights => DateTime(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime(start.year, start.month, start.day)).inDays;
  String? validate() {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    if (DateTime(
          start.year,
          start.month,
          start.day,
        ).isBefore(DateTime(vn.year, vn.month, vn.day)) ||
        nights < 1 ||
        nights > 30) {
      return 'Chọn từ 1 đến 30 đêm, ngày nhận không trước hôm nay.';
    }
    if (guests < 1) return 'Số khách phải lớn hơn 0';
    if ((minPrice ?? 0) < 0 ||
        (maxPrice ?? 0) < 0 ||
        (minPrice != null && maxPrice != null && minPrice! > maxPrice!)) {
      return 'Khoảng giá không hợp lệ';
    }
    return null;
  }

  Json toJson() => {
    'ngay_nhan': dateOnly(start),
    'ngay_tra': dateOnly(end),
    'so_khach': guests,
    if (typeId != null) 'ma_lp': typeId,
    if (minPrice != null) 'gia_min': minPrice,
    if (maxPrice != null) 'gia_max': maxPrice,
  };
}

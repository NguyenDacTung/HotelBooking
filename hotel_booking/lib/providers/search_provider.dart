import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../models/models.dart';
import '../repositories/hotel_repository.dart';
import '../models/search_criteria.dart';

class SearchProvider extends ChangeNotifier {
  final HotelRepository repository;
  SearchProvider(this.repository);
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Room> rooms = [];
  bool loading = false;
  String? error;
  int page = 1, total = 0, guests = 2;
  DateTime start = DateUtilsVN.today;
  DateTime end = DateUtilsVN.today.add(const Duration(days: 1));
  int? typeId, minPrice, maxPrice;
  SearchCriteria get criteria => SearchCriteria(
    start: start,
    end: end,
    guests: guests,
    typeId: typeId,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );
  void setCriteria(SearchCriteria value) {
    start = value.start;
    end = value.end;
    guests = value.guests;
    typeId = value.typeId;
    minPrice = value.minPrice;
    maxPrice = value.maxPrice;
    notifyListeners();
  }

  Future<void> search({bool more = false}) async {
    if (loading || _disposed) return;
    final validation = criteria.validate();
    if (validation != null) {
      error = validation;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = more ? page + 1 : 1;
      final result = await repository.rooms({
        'ngay_nhan': dateOnly(start),
        'ngay_tra': dateOnly(end),
        'so_khach': guests,
        'page': next,
        if (typeId != null) 'ma_lp': typeId,
        if (minPrice != null) 'gia_min': minPrice,
        if (maxPrice != null) 'gia_max': maxPrice,
      });
      rooms = more ? [...rooms, ...result.items] : result.items;
      total = result.total;
      page = next;
    } catch (e) {
      error = e.toString();
      if (!more) rooms = [];
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }
}

abstract final class DateUtilsVN {
  static DateTime get today {
    final n = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(n.year, n.month, n.day);
  }
}

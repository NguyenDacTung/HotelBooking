import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/hotel_repository.dart';

class BookingProvider extends ChangeNotifier {
  final HotelRepository repository;
  BookingProvider(this.repository);
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Booking> items = [];
  bool loading = false;
  String? error, status;
  int page = 1, total = 0;
  String? from, to;
  Future<void> load(bool staff, {bool more = false}) async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = more ? page + 1 : 1;
      final result = await repository.bookings(staff, {
        'page': next,
        if (status != null) 'trang_thai': status,
        if (from != null) 'ngay_nhan_tu': from,
        if (to != null) 'ngay_nhan_den': to,
      });
      items = more ? [...items, ...result.items] : result.items;
      page = next;
      total = result.total;
    } catch (e) {
      error = e.toString();
      if (!more) items = [];
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }
}

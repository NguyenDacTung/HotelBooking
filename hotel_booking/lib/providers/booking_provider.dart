import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/hotel_repository.dart';

class BookingProvider extends ChangeNotifier {
  final HotelRepository repository;
  BookingProvider(this.repository);
  bool _disposed = false;
  int _loadVersion = 0;
  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }

  List<Booking> items = [];
  bool loading = false;
  String? error, status;
  int page = 1, total = 0;
  String? from, to;
  Future<void> load(bool staff, {bool more = false}) async {
    if (_disposed) return;
    // Pagination is sequential. Refreshes/changed filters may supersede a
    // pending request, whose result must then be ignored.
    if (more && (loading || items.length >= total)) return;
    final version = ++_loadVersion;
    final next = more ? page + 1 : 1;
    final requestedStatus = status;
    final requestedFrom = from;
    final requestedTo = to;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.bookings(staff, {
        'page': next,
        if (requestedStatus != null) 'trang_thai': requestedStatus,
        if (requestedFrom != null) 'ngay_nhan_tu': requestedFrom,
        if (requestedTo != null) 'ngay_nhan_den': requestedTo,
      });
      if (_disposed || version != _loadVersion) return;
      items = more ? [...items, ...result.items] : result.items;
      page = next;
      total = result.total;
    } catch (e) {
      if (_disposed || version != _loadVersion) return;
      error = e.toString();
      if (!more) {
        items = [];
        total = 0;
        page = 1;
      }
    } finally {
      if (!_disposed && version == _loadVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }
}

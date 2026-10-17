import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../core/config.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService api;
  AdminProvider(this.api);
  DateTime start = DateTime.now().subtract(const Duration(days: 6)),
      end = DateTime.now();
  String mode = 'day';
  Json? report;
  String? error;
  bool loading = false, _disposed = false;
  Json get query => {
    'tu_ngay': dateOnly(start),
    'den_ngay': dateOnly(end),
    'mode': mode,
  };
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    report = null;
    notifyListeners();
    try {
      report = await api.request(
        'GET',
        '/admin/reports/revenue',
        query: query,
      ) as Json;
    } catch (e) {
      error = '$e';
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }
}

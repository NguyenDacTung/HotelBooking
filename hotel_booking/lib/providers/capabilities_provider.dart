import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class CapabilitiesProvider extends ChangeNotifier {
  final ApiService api;
  Json? data;
  String? error;
  bool loading = false, _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  CapabilitiesProvider(this.api) {
    load();
  }
  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await api.request('GET', '/app/capabilities') as Json;
    } catch (e) {
      error = '$e';
      data = null;
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  bool ready(String group, [String? key]) {
    final groupData = data == null ? null : data![group];
    final feature = key == null
        ? groupData
        : (groupData is Map ? groupData[key] : null);
    return feature is Map &&
        feature['enabled'] == true &&
        feature['configured'] == true;
  }

  String get unavailable => loading
      ? 'Đang kiểm tra cấu hình…'
      : error != null
      ? 'Chưa tải được cấu hình. Hãy thử lại.'
      : 'Dịch vụ chưa được cấu hình';
}

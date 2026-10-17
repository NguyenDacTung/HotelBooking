import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

class SessionProvider extends ChangeNotifier {
  final ApiService api;
  final TokenStorage storage;
  Json? user;
  bool restoring = true;
  String? restoreError;
  SessionProvider(this.api, this.storage) {
    api.onUnauthorized = logout;
  }
  bool get staff => user != null && user!['ma_quyen'] != 'KHACH_HANG';
  bool get manager => user?['ma_quyen'] == 'QUAN_LY';
  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    notifyListeners();
    try {
      api.token = await storage.read();
      if (api.token != null) {
        user = await api.request('GET', '/users/me') as Json;
      }
    } catch (e) {
      restoreError = e.toString();
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authenticate('/auth/login', {
      'email': email.trim(),
      'mat_khau': password,
    });
  }

  Future<void> _authenticate(String path, Json body) async {
    final result = await api.request('POST', path, body: body);
    if (result is! Json ||
        result['access_token'] is! String ||
        (result['access_token'] as String).isEmpty) {
      throw ApiError(
        'Máy chủ trả phiên đăng nhập không hợp lệ.',
        200,
        'INVALID_RESPONSE',
        null,
        'POST',
        path,
      );
    }
    api.token = result['access_token'] as String;
    try {
      final profile = await api.request('GET', '/users/me');
      if (profile is! Json ||
          profile['id'] is! String ||
          profile['ma_quyen'] is! String) {
        throw const ApiError(
          'Máy chủ trả hồ sơ không hợp lệ.',
          200,
          'INVALID_RESPONSE',
          null,
          'GET',
          '/users/me',
        );
      }
      user = profile;
      await storage.write(api.token!);
    } catch (_) {
      api.token = null;
      user = null;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    notifyListeners();
    await storage.clear();
  }

  Future<void> social(String provider, String credential) async {
    await _authenticate('/auth/$provider', {'credential': credential});
  }

  Future<void> profile(Json body) async {
    user = await api.request('PATCH', '/users/me', body: body) as Json;
    notifyListeners();
  }
}

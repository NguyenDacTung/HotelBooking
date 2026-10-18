import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';
import '../services/push_service.dart';
import '../services/biometric_login_service.dart';

class SessionProvider extends ChangeNotifier {
  final ApiService api;
  final TokenStorage storage;
  final Future<void> Function()? clearPrivateFiles;
  final BiometricLoginService? biometric;
  VoidCallback? onSignedOut;
  Json? user;
  bool restoring = true;
  String? restoreError;
  SessionProvider(
    this.api,
    this.storage, {
    this.clearPrivateFiles,
    this.biometric,
  }) {
    api.onUnauthorized = logout;
  }
  bool get staff => user != null && user!['ma_quyen'] != 'KHACH_HANG';
  bool get manager => user?['ma_quyen'] == 'QUAN_LY';
  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    notifyListeners();
    try {
      if (biometric != null && await biometric!.registration() != null) {
        // Opted-in devices sign in from the fingerprint button, never silently
        // restore an access token before biometric verification.
        await storage.clear();
        api.token = null;
        user = null;
        return;
      }
      api.token = await storage.read();
      if (api.token != null) {
        user = await api.request('GET', '/users/me') as Json;
      }
    } catch (e) {
      restoreError = e.toString();
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> loginWithBiometric() async {
    final service = biometric ?? const BiometricLoginService();
    try {
      await _authenticate('/auth/biometric/login', await service.proof(api));
    } on ApiError catch (e) {
      if (e.status == 401) await service.forget();
      rethrow;
    }
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
    await PushService.instance.disable(api);
    api.token = null;
    user = null;
    onSignedOut?.call();
    notifyListeners();
    await storage.clear();
    await clearPrivateFiles?.call();
  }

  Future<void> social(String provider, String credential) async {
    await _authenticate('/auth/$provider', {'credential': credential});
  }

  Future<void> refreshProfile() async {
    user = await api.request('GET', '/users/me') as Json;
    notifyListeners();
  }

  Future<void> profile(Json body) async {
    user = await api.request('PATCH', '/users/me', body: body) as Json;
    notifyListeners();
  }
}

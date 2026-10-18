import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';

/// Firebase is opt-in; builds without service credentials work normally.
class PushService {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static bool get configured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty;
  static final instance = PushService();
  String? _token;
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _foreground;
  static Future<void> initialize() async {
    if (!configured) return;
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
      ),
    );
  }

  Future<void> enable(
    ApiService api,
    void Function(String) onTap, {
    Future<void> Function()? refresh,
  }) async {
    if (!configured) throw StateError('Thông báo đẩy chưa được cấu hình');
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final result = await FirebaseMessaging.instance.requestPermission();
    if (result.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Chưa được cấp quyền thông báo');
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) throw StateError('Chưa đăng ký được thiết bị');
    await api.request('POST', '/devices', body: {'token': token});
    _token = token;
    await _refresh?.cancel();
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((value) async {
      if (api.token == null) return;
      try {
        await api.request('POST', '/devices', body: {'token': value});
        _token = value;
      } catch (_) {
        /* Retry on next opt-in/session. */
      }
    });
    await _opened?.cancel();
    await _foreground?.cancel();
    _foreground = FirebaseMessaging.onMessage.listen((_) async {
      try {
        await refresh?.call();
      } catch (_) {
        /* In-app polling will retry. */
      }
    });
    _opened = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final id = m.data['booking_id'];
      if (id is String) onTap(id);
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial?.data['booking_id'] case final String id) {
      onTap(id);
    }
  }

  Future<void> disable(ApiService api) async {
    await _refresh?.cancel();
    await _opened?.cancel();
    await _foreground?.cancel();
    _refresh = null;
    _opened = null;
    _foreground = null;
    final token = _token;
    _token = null;
    if (token != null && api.token != null) {
      try {
        await api.request('DELETE', '/devices', body: {'token': token});
      } catch (_) {}
    }
    if (configured) {
      try {
        await FirebaseMessaging.instance.deleteToken();
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
      } catch (_) {}
    }
  }
}

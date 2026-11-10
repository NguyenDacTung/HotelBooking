import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/core/client_config.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/push_service.dart';
import 'package:hotel_booking/services/social_login_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(ClientConfig.channel, (_) async => '{}');
    await ClientConfig.initialize();
    messenger.setMockMethodCallHandler(ClientConfig.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('startup settings reach API, social login and push', () async {
    messenger.setMockMethodCallHandler(ClientConfig.channel, (call) async {
      expect(call.method, 'load');
      return jsonEncode({
        'API_BASE_URL': 'http://127.0.0.1:8000',
        'GOOGLE_SERVER_CLIENT_ID': 'test-client.apps.googleusercontent.com',
        'FACEBOOK_ENABLED': true,
        'FIREBASE_API_KEY': 'test-public-setting',
        'FIREBASE_APP_ID': 'test-app',
        'FIREBASE_MESSAGING_SENDER_ID': '123456',
        'FIREBASE_PROJECT_ID': 'test-project',
      });
    });
    await ClientConfig.initialize();
    const apiOverride = String.fromEnvironment('API_BASE_URL');
    expect(
      ApiService().baseUrl,
      apiOverride.isEmpty ? 'http://127.0.0.1:8000' : apiOverride,
    );
    expect(
      ApiService(baseUrl: 'https://override.example.org').baseUrl,
      'https://override.example.org',
    );
    expect(
      SocialLoginService.googleClientId,
      const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: 'test-client.apps.googleusercontent.com',
      ),
    );
    expect(
      SocialLoginService.facebookEnabled,
      const bool.fromEnvironment('FACEBOOK_ENABLED', defaultValue: true),
    );
    expect(PushService.configured, isTrue);
    expect(
      PushService.projectId,
      const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'test-project',
      ),
    );
  });

  test('empty settings keep optional services disabled', () async {
    messenger.setMockMethodCallHandler(ClientConfig.channel, (_) async => '{}');
    await ClientConfig.initialize();
    expect(ApiService().baseUrl, 'http://10.0.2.2:8000');
    expect(SocialLoginService.googleClientId, isEmpty);
    expect(SocialLoginService.facebookEnabled, isFalse);
    expect(PushService.configured, isFalse);
  });

  test(
    'unsupported platforms retain explicit-build configuration path',
    () async {
      var called = false;
      messenger.setMockMethodCallHandler(ClientConfig.channel, (_) async {
        called = true;
        return '{}';
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      await ClientConfig.initialize();
      expect(called, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_booking/models/models.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/screens/shared/profile_screen.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/biometric_login_service.dart';
import 'package:hotel_booking/services/token_storage.dart';
import 'package:hotel_booking/widgets/auth_form.dart';
import 'package:hotel_booking/widgets/image_crop.dart';

const profile = {
  'id': 'qa-account',
  'ho_ten': 'Khách QA',
  'email': 'qa@example.com',
  'ma_quyen': 'KHACH_HANG',
};

class Tokens extends TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

class Fingerprint extends BiometricLoginService {
  bool registered = true;
  int signed = 0, forgotten = 0;
  @override
  Future<Json?> registration() async =>
      registered ? {'account_id': 'qa-account', 'device_id': 'device'} : null;
  @override
  Future<Json> proof(ApiService api) async {
    signed++;
    return {'challenge_id': 'one-use', 'signature': 'signed-proof'};
  }

  @override
  Future<void> forget() async {
    forgotten++;
    registered = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'fingerprint signs in without email/password and obtains current profile',
    () async {
      final native = Fingerprint();
      final storage = Tokens();
      final api = ApiService(
        client: MockClient((r) async {
          if (r.url.path == '/auth/biometric/login') {
            final body = jsonDecode(r.body) as Map;
            expect(body.keys, unorderedEquals(['challenge_id', 'signature']));
            return http.Response('{"access_token":"new-qa-session"}', 200);
          }
          expect(r.url.path, '/users/me');
          return http.Response(
            jsonEncode(profile),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final s = SessionProvider(api, storage, biometric: native);
      await s.loginWithBiometric();
      expect(native.signed, 1);
      expect(s.user?['id'], 'qa-account');
      expect(storage.value, 'new-qa-session');
    },
  );

  test(
    'registered fingerprint does not silently restore cached access token',
    () async {
      final storage = Tokens()..value = 'cached-token';
      final api = ApiService(
        client: MockClient(
          (_) async => throw StateError('Must not silently call profile'),
        ),
      );
      final s = SessionProvider(api, storage, biometric: Fingerprint());
      await s.restore();
      expect(s.restoring, false);
      expect(s.user, isNull);
      expect(api.token, isNull);
      expect(storage.value, isNull);
    },
  );

  test('server revocation forgets the biometric registration and keeps user signed out', () async {
    final native = Fingerprint();
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"BIOMETRIC_INVALID","message":"Revoked"}}',
          401,
        ),
      ),
    );
    final s = SessionProvider(api, Tokens(), biometric: native);
    await expectLater(s.loginWithBiometric(), throwsA(isA<ApiError>()));
    expect(native.forgotten, 1);
    expect(s.user, isNull);
  });

  testWidgets(
    'fingerprint button accepts empty email/password without a second session gate',
    (t) async {
      final native = Fingerprint();
      final api = ApiService(
        client: MockClient(
          (r) async => r.url.path == '/auth/biometric/login'
              ? http.Response('{"access_token":"qa"}', 200)
              : http.Response(
                  jsonEncode(profile),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                ),
        ),
      );
      final s = SessionProvider(api, Tokens(), biometric: native);
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: s),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    c,
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: SingleChildScrollView(child: AuthForm()),
                      ),
                    ),
                  ),
                  child: const Text('Mở đăng nhập'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Mở đăng nhập'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Đăng nhập bằng vân tay'));
      await t.tap(find.text('Đăng nhập bằng vân tay'));
      await t.pumpAndSettle();
      expect(native.signed, 1);
      expect(find.text('Email không hợp lệ'), findsNothing);
      expect(find.text('Mở khóa TETRA'), findsNothing);
      expect(find.text('Mở đăng nhập'), findsOneWidget);
    },
  );

  testWidgets(
    'profile has one avatar and readable identity on narrow large-text screen',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final api = ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final s = SessionProvider(api, Tokens())..user = profile;
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: s),
          ],
          child: MaterialApp(
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Đổi ảnh đại diện'), findsOneWidget);
      expect(find.text('qa@example.com'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'avatar crop uses fixed circle, drag/pinch instructions, reset and confirmed preview',
    (t) async {
      final bytes = File('test/fixtures/avatar_qa.png').readAsBytesSync();
      await t.pumpWidget(
        MaterialApp(home: ImageCropScreen(bytes, avatar: true)),
      );
      await t.pumpAndSettle();
      var crop = t.widget<Crop>(find.byType(Crop));
      expect(crop.interactive, true);
      expect(crop.fixCropRect, true);
      expect(crop.withCircleUi, true);
      expect(find.textContaining('Kéo ảnh'), findsOneWidget);
      await t.tap(find.text('Đặt lại vị trí ảnh'));
      await t.pumpAndSettle();
      crop = t.widget<Crop>(find.byType(Crop));
      crop.onCropped(CropSuccess(bytes));
      await t.pumpAndSettle();
      expect(find.text('Dùng ảnh này'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
      await t.tap(find.text('Căn lại'));
      await t.pumpAndSettle();
      expect(find.byType(Crop), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  test('setup cancel removes pending device and never persists password or enrollment', () async {
    const service = BiometricLoginService();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(service.channel, (c) async {
          calls.add(c.method);
          if (c.method == 'available') return true;
          if (c.method == 'create') return 'public-key';
          if (c.method == 'sign') {
            throw PlatformException(code: 'BIOMETRIC_CANCELLED');
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(service.channel, null),
    );
    var revoked = false;
    final api = ApiService(
      client: MockClient((r) async {
        if (r.method == 'DELETE') {
          revoked = true;
          return http.Response('{}', 200);
        }
        if (r.url.path == '/users/me/biometric') {
          return http.Response(
            '{"challenge_id":"challenge","message":"test"}',
            201,
          );
        }
        throw StateError('Cancelled setup must not confirm enrollment');
      }),
    );
    await expectLater(
      service.enable(api, profile, 'setup-password'),
      throwsA(isA<ApiError>()),
    );
    expect(revoked, true);
    expect(await service.registration(), isNull);
    expect(calls, contains('delete'));
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}

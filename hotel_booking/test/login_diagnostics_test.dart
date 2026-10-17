import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';

class _Tokens extends TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  test(
    'logout then login and new app session restore persisted identity',
    () async {
      var logins = 0;
      final storage = _Tokens();
      final api = ApiService(
        client: MockClient((r) async {
          if (r.url.path == '/auth/login') {
            logins++;
            return http.Response('{"access_token":"test-session"}', 200);
          }
          return http.Response(
            '{"id":"test-account","ma_quyen":"KHACH_HANG"}',
            200,
          );
        }),
      );
      final first = SessionProvider(api, storage);
      await first.login('customer@example.com', 'test-password');
      await first.logout();
      expect(storage.value, isNull);
      expect(first.user, isNull);
      await first.login('customer@example.com', 'test-password');
      final reopened = SessionProvider(api, storage);
      await reopened.restore();
      expect(logins, 2);
      expect(reopened.user?['id'], 'test-account');
      expect(reopened.restoreError, isNull);
    },
  );

  test(
    'expired session 401 clears persisted token and user on reopen',
    () async {
      final storage = _Tokens()..value = 'expired-test-session';
      final api = ApiService(
        client: MockClient(
          (_) async => http.Response(
            '{"error":{"code":"UNAUTHENTICATED","message":"Expired session"}}',
            401,
          ),
        ),
      );
      final session = SessionProvider(api, storage);
      await session.restore();
      expect(storage.value, isNull);
      expect(api.token, isNull);
      expect(session.user, isNull);
      expect(session.restoring, isFalse);
      expect(session.restoreError, 'Expired session');
    },
  );

  test(
    'transport failure identifies login; profile is never requested',
    () async {
      final paths = <String>[];
      final log = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) log.add(message);
      };
      addTearDown(() => debugPrint = previous);
      final api = ApiService(
        client: MockClient((r) async {
          paths.add(r.url.path);
          throw http.ClientException('connection refused');
        }),
      );
      final session = SessionProvider(api, _Tokens());
      await expectLater(
        session.login('admin@tttp.test', 'private-password'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.path, 'path', '/auth/login')
              .having((e) => e.status, 'no HTTP response', isNull)
              .having((e) => e.code, 'category', 'TRANSPORT_ERROR'),
        ),
      );
      expect(paths, ['/auth/login']);
      expect(log.join(), contains('POST /auth/login'));
      expect(log.join(), isNot(contains('private-password')));
      expect(log.join(), isNot(contains('admin@tttp.test')));
    },
  );

  test('profile HTTP failure retains status and rolls back login', () async {
    final paths = <String>[];
    final tokens = _Tokens();
    final api = ApiService(
      client: MockClient((r) async {
        paths.add(r.url.path);
        return r.url.path == '/auth/login'
            ? http.Response('{"access_token":"private-token"}', 200)
            : http.Response(
                '{"error":{"code":"INTERNAL_ERROR","message":"Server failed"}}',
                500,
              );
      }),
    );
    final session = SessionProvider(api, tokens);
    await expectLater(
      session.login('admin@tttp.test', 'private-password'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.path, 'path', '/users/me')
            .having((e) => e.status, 'HTTP', 500)
            .having((e) => e.code, 'code', 'INTERNAL_ERROR'),
      ),
    );
    expect(paths, ['/auth/login', '/users/me']);
    expect(session.user, isNull);
    expect(api.token, isNull);
    expect(tokens.value, isNull);
  });

  for (final entry in [
    (502, '<html>Bad gateway</html>', 'HTTP_ERROR'),
    (200, 'not json', 'INVALID_RESPONSE'),
    (500, '{"error":"unexpected string"}', 'HTTP_ERROR'),
  ]) {
    test(
      'HTTP ${entry.$1} with malformed response remains distinct from network',
      () async {
        final api = ApiService(
          client: MockClient((_) async => http.Response(entry.$2, entry.$1)),
        );
        await expectLater(
          api.request('POST', '/auth/login'),
          throwsA(
            isA<ApiError>()
                .having((e) => e.status, 'HTTP', entry.$1)
                .having((e) => e.code, 'code', entry.$3),
          ),
        );
      },
    );
  }

  test(
    'post-login data failure does not revoke authenticated session',
    () async {
      final tokens = _Tokens();
      final api = ApiService(
        client: MockClient(
          (r) async => switch (r.url.path) {
            '/auth/login' => http.Response(
              '{"access_token":"private-token"}',
              200,
            ),
            '/users/me' => http.Response(
              '{"id":"account-id","ma_quyen":"QUAN_LY"}',
              200,
            ),
            _ => http.Response(
              '{"error":{"message":"Report unavailable"}}',
              503,
            ),
          },
        ),
      );
      final session = SessionProvider(api, tokens);
      await session.login('admin@tttp.test', 'private-password');
      await expectLater(
        api.request('GET', '/admin/reports/revenue'),
        throwsA(isA<ApiError>().having((e) => e.status, 'HTTP', 503)),
      );
      expect(session.manager, isTrue);
      expect(tokens.value, 'private-token');
    },
  );
}

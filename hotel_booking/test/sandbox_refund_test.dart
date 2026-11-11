import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_booking/providers/capabilities_provider.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/screens/staff/sandbox_refund_screen.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';

void main() {
  testWidgets(
    'uncertain refund retries preserve the request ID and never send a client amount',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requestIds = <String>[];
      var succeeded = false;
      final api = ApiService(
        client: MockClient((request) async {
          final feature = {'enabled': true, 'configured': true};
          Object data;
          if (request.url.path == '/app/capabilities') {
            data = {
              'online_refund': feature,
              'payments': {'momo': feature},
            };
          } else if (request.url.path.endsWith('/online-payments')) {
            data = {
              'items': [
                {
                  'id': 'attempt',
                  'provider': 'MOMO',
                  'amount': 1000000,
                  'state': 'SUCCEEDED',
                  'environment': 'sandbox',
                },
              ],
            };
          } else if (request.url.path.endsWith('/online-refunds')) {
            data = {
              'items': succeeded
                  ? [
                      {
                        'id': 'refund',
                        'attempt_id': 'attempt',
                        'amount': 1000000,
                        'state': 'SUCCEEDED',
                      },
                    ]
                  : [],
            };
          } else if (request.url.path ==
              '/admin/online-payments/attempt/refunds') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body.keys, ['request_id']);
            requestIds.add(body['request_id'] as String);
            if (requestIds.length == 1) {
              return http.Response(
                jsonEncode({
                  'error': {
                    'code': 'REFUND_UNCERTAIN',
                    'message': 'Chưa xác định kết quả',
                  },
                }),
                503,
              );
            }
            succeeded = true;
            data = {'state': 'SUCCEEDED'};
          } else {
            throw StateError('Unexpected request');
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final session = SessionProvider(api, const TokenStorage())
        ..user = {'id': 'manager', 'ma_quyen': 'QUAN_LY'};
      final caps = CapabilitiesProvider(api);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: caps),
          ],
          child: const MaterialApp(
            home: SandboxRefundScreen(bookingId: 'booking'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Hoàn sandbox'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gửi yêu cầu hoàn'));
        await tester.pumpAndSettle();
      }
      expect(requestIds, hasLength(2));
      expect(requestIds[0], requestIds[1]);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey('tetra-sandbox-refund-manager-attempt'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('non-manager cannot load refund data', (tester) async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final session = SessionProvider(api, const TokenStorage())
      ..user = {'id': 'customer', 'ma_quyen': 'KHACH_HANG'};
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: api),
          ChangeNotifierProvider.value(value: session),
        ],
        child: const MaterialApp(
          home: SandboxRefundScreen(bookingId: 'booking'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets(
    'pending sandbox refund reserves the payment and can be reconciled',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var state = 'PENDING';
      var queryCount = 0;
      final api = ApiService(
        client: MockClient((request) async {
          final feature = {'enabled': true, 'configured': true};
          Object data;
          if (request.url.path == '/app/capabilities') {
            data = {
              'online_refund': feature,
              'payments': {'momo': feature},
            };
          } else if (request.url.path.endsWith('/online-payments')) {
            data = {
              'items': [
                {
                  'id': 'attempt',
                  'provider': 'MOMO',
                  'amount': 1000000,
                  'state': 'SUCCEEDED',
                  'environment': 'sandbox',
                },
                {
                  'id': 'production',
                  'provider': 'MOMO',
                  'amount': 1000000,
                  'state': 'SUCCEEDED',
                  'environment': 'production',
                },
              ],
            };
          } else if (request.url.path.endsWith('/online-refunds')) {
            data = {
              'items': [
                {
                  'id': 'refund',
                  'attempt_id': 'attempt',
                  'amount': 1000000,
                  'state': state,
                },
              ],
            };
          } else if (request.url.path == '/admin/online-refunds/refund/query') {
            queryCount++;
            state = 'SUCCEEDED';
            data = {'state': state};
          } else {
            throw StateError('Unexpected request');
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final session = SessionProvider(api, const TokenStorage())
        ..user = {'id': 'manager', 'ma_quyen': 'QUAN_LY'};
      final caps = CapabilitiesProvider(api);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: caps),
          ],
          child: const MaterialApp(
            home: SandboxRefundScreen(bookingId: 'booking'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('production •'), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Hoàn sandbox'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Đối soát'));
      await tester.pumpAndSettle();
      expect(queryCount, 1);
      expect(find.textContaining('SUCCEEDED'), findsOneWidget);
      expect(find.text('Đối soát'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

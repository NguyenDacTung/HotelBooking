import 'package:hotel_booking/screens/shared/feedback_screen.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/providers/capabilities_provider.dart';
import 'package:hotel_booking/widgets/app_drawer.dart';
import 'package:hotel_booking/screens/shared/reviews_screen.dart';
import 'package:hotel_booking/app/app_router.dart';
import 'package:hotel_booking/services/reminder_service.dart';

void main() {
  testWidgets(
    'feedback capture is scoped and uses Vietnamese annotation controls',
    (t) async {
      final api = ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await t.pumpWidget(
        Provider.value(
          value: api,
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );
      final button = find.text('Chụp và chú thích màn hình góp ý');
      await t.ensureVisible(button);
      await t.tap(button);
      await t.pumpAndSettle();
      expect(find.text('Di chuyển'), findsOneWidget);
      expect(find.text('Đánh dấu'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );

  test('capabilities distinguishes unavailable from unconfigured and survives disposal', () async {
    final done = Completer<http.Response>();
    final api = ApiService(client: MockClient((_) => done.future));
    final caps = CapabilitiesProvider(api);
    expect(caps.loading, true);
    caps.dispose();
    done.complete(http.Response('{}', 503));
    await Future<void>.delayed(Duration.zero);
    final disabled = CapabilitiesProvider(
      ApiService(
        client: MockClient(
          (_) async => http.Response(
            '{"payments":{"momo":{"enabled":false,"configured":false}}}',
            200,
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(disabled.loading, false);
    expect(disabled.error, isNull);
    expect(disabled.ready('payments', 'momo'), false);
    disabled.dispose();
  });
  test('reminder ID is stable for a booking and independent of list order', () {
    final a = ReminderService.stableId('aa-bb-01'),
        b = ReminderService.stableId('aa-bb-02');
    expect(a, ReminderService.stableId('aa-bb-01'));
    expect(a, isNot(b));
    expect(a, greaterThanOrEqualTo(0));
  });
  testWidgets(
    'review has no default stars and sends exactly the selected score',
    (t) async {
      var sent = 0;
      final api = ApiService(
        client: MockClient((r) async {
          sent++;
          expect(r.url.path, '/bookings/stay/review');
          expect(jsonDecode(r.body)['so_sao'], 2);
          return http.Response('{}', 201);
        }),
      );
      await t.pumpWidget(
        Provider.value(
          value: api,
          child: const MaterialApp(home: ReviewEditor(bookingId: 'stay')),
        ),
      );
      var button = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Gửi đánh giá'),
      );
      expect(button.onPressed, isNull);
      await t.tap(find.byTooltip('2 sao'));
      await t.pump();
      button = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Gửi đánh giá'),
      );
      expect(button.onPressed, isNotNull);
      await t.tap(find.text('Gửi đánh giá'));
      await t.pumpAndSettle();
      expect(sent, 1);
    },
  );
  for (final role in ['guest', 'KHACH_HANG', 'LE_TAN', 'QUAN_LY']) {
    testWidgets('drawer $role fits large text and only exposes role menus', (
      t,
    ) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final api = ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final session = SessionProvider(api, const TokenStorage());
      if (role != 'guest') {
        session.user = {
          'id': 'account',
          'email': 'someone@example.test',
          'ho_ten': 'Khách TETRA',
          'ma_quyen': role,
        };
      }
      await t.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: Provider.value(
            value: api,
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  size: Size(360, 800),
                ),
                child: const Scaffold(body: AppDrawer()),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      if (role == 'QUAN_LY') {
        await t.scrollUntilVisible(
          find.text('Quản lý tài khoản'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(
        find.text('Quản lý tài khoản'),
        role == 'QUAN_LY' ? findsOneWidget : findsNothing,
      );
      if (['LE_TAN', 'QUAN_LY'].contains(role)) {
        await t.scrollUntilVisible(
          find.text('Lịch phòng'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(
        find.text('Lịch phòng'),
        ['LE_TAN', 'QUAN_LY'].contains(role) ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Đánh giá của tôi'),
        role == 'KHACH_HANG' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Đăng xuất'),
        role == 'guest' ? findsNothing : findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
  testWidgets('customer deep route to admin is denied before any request', (
    t,
  ) async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final session = SessionProvider(api, const TokenStorage())
      ..user = {'id': 'customer', 'ma_quyen': 'KHACH_HANG'};
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: Provider.value(
          value: api,
          child: MaterialApp(
            routes: AppRouter.routes,
            initialRoute: '/admin/reviews',
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Tài khoản không có quyền mở mục này'), findsOneWidget);
    expect(calls, 0);
  });
}

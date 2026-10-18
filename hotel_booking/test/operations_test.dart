import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/providers/search_provider.dart';
import 'package:hotel_booking/models/search_criteria.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/widgets/search_form.dart';
import 'package:hotel_booking/widgets/common.dart';
import 'package:hotel_booking/screens/staff/payments_screen.dart';
import 'package:hotel_booking/providers/notifications_provider.dart';
import 'package:hotel_booking/services/reminder_service.dart';
import 'package:hotel_booking/screens/shared/notification_settings_screen.dart';
import 'package:hotel_booking/widgets/booking_operations.dart';
import 'package:hotel_booking/core/config.dart';

void main() {
  testWidgets(
    'check-in sends directly without asking for an unnecessary reason',
    (tester) async {
      final api = ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final session = SessionProvider(api, const TokenStorage())
        ..user = {'id': 'staff', 'ma_quyen': 'LE_TAN'};
      var state = 'DA_XAC_NHAN';
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: session),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (c, set) => SingleChildScrollView(
                  child: BookingOperations(
                    booking: {
                      'ma_pdp': 'test',
                      'trang_thai': state,
                      'tong_tien': 500000,
                      'ngay_nhan': dateOnly(
                        DateTime.now().toUtc().add(const Duration(hours: 7)),
                      ),
                    },
                    reload: () async {
                      set(() => state = 'DANG_O');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Nhận phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.text('Yêu cầu trả phòng'), findsOneWidget);
    },
  );
  testWidgets('notification settings fit narrow display at double text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    final session = SessionProvider(api, const TokenStorage());
    final notices = NotificationsProvider(
      session,
      api,
      ReminderService(),
      (_) {},
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notices,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: const NotificationSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    notices.dispose();
    session.dispose();
  });
  test(
    'phones reject arbitrary text and accept normalized Vietnam/international',
    () {
      for (final phone in ['abc', '123', '0123456789', '']) {
        expect(phoneText(phone), isNotNull);
      }
      for (final phone in ['0901234567', '(+84) 901-234-567', '+12025550123']) {
        expect(phoneText(phone), isNull);
      }
    },
  );
  testWidgets('existing search form follows shared guest changes', (
    tester,
  ) async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response('{"items":[],"total":0}', 200),
      ),
    );
    final search = SearchProvider(HotelRepository(api));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: search,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SearchForm(onSearch: () {})),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '2',
    );
    search.setCriteria(
      SearchCriteria(
        start: DateUtilsVN.today,
        end: DateUtilsVN.today.add(const Duration(days: 2)),
        guests: 4,
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '4',
    );
    await tester.pumpWidget(const SizedBox());
    search.dispose();
  });
  testWidgets(
    'uncertain payment persists exact request across reopening and clears after replay',
    (tester) async {
      const id = 'booking-test';
      final pending = {
        'path': '/staff/bookings/$id/payments',
        'body': {
          'request_id': 'same-request-id',
          'so_tien': 200000,
          'phuong_thuc': 'TIEN_MAT',
        },
      };
      SharedPreferences.setMockInitialValues({
        'tttp_payment_staff_$id': jsonEncode(pending),
      });
      var posts = 0;
      final api = ApiService(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posts++;
            expect(jsonDecode(r.body), pending['body']);
            // The first successful HTTP response is malformed: keep the pending
            // request because the server may already have committed the payment.
            if (posts == 1) {
              return http.Response('<invalid-json>', 200);
            }
            return http.Response('{"id":"recorded"}', 201);
          }
          if (r.url.path.endsWith('/payments')) {
            return http.Response(
              '{"items":[],"total":0,"da_thu":200000,"da_hoan":0,"thu_rong":200000,"con_phai_thu":800000,"can_hoan_tien":0}',
              200,
            );
          }
          return http.Response(
            '{"ma_pdp":"booking-test","trang_thai":"DA_XAC_NHAN"}',
            200,
          );
        }),
      );
      final session = SessionProvider(api, const TokenStorage())
        ..user = {'id': 'staff', 'ma_quyen': 'LE_TAN'};
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: api),
            ChangeNotifierProvider.value(value: session),
          ],
          child: const MaterialApp(home: PaymentsScreen(bookingId: id)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra / thử lại giao dịch cũ'), findsOneWidget);
      await tester.tap(find.text('Kiểm tra / thử lại giao dịch cũ'));
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'tttp_payment_staff_$id',
        ),
        isNotNull,
      );
      await tester.tap(find.text('Kiểm tra / thử lại giao dịch cũ'));
      await tester.pumpAndSettle();
      expect(posts, 2);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'tttp_payment_staff_$id',
        ),
        isNull,
      );
      expect(find.text('Kiểm tra / thử lại giao dịch cũ'), findsNothing);
    },
  );
}

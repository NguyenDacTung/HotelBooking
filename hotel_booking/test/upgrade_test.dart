import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking/providers/search_provider.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/screens/customer/home_screen.dart';
import 'package:hotel_booking/models/search_criteria.dart';
import 'package:hotel_booking/app/app_theme.dart';

void main() {
  test('invalid stay blocks search before network', () async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 500);
      }),
    );
    final state = SearchProvider(HotelRepository(api));
    state.setCriteria(
      SearchCriteria(
        start: DateUtilsVN.today,
        end: DateUtilsVN.today,
        guests: 2,
      ),
    );
    await state.search();
    expect(calls, 0);
    expect(state.error, isNotNull);
    expect(state.loading, isFalse);
    state.dispose();
  });

  test('price conflict preserves replacement quote and sends once', () async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'PRICE_CHANGED',
              'message': 'Price changed',
              'details': {'don_gia_moi_dem': 700000, 'tong_tien': 1400000},
            },
          }),
          409,
        );
      }),
    );
    await expectLater(
      api.request(
        'POST',
        '/bookings',
        body: {'expected_don_gia_moi_dem': 500000},
      ),
      throwsA(
        isA<ApiError>()
            .having((e) => e.code, 'code', 'PRICE_CHANGED')
            .having((e) => e.details['tong_tien'], 'new total', 1400000),
      ),
    );
    expect(calls, 1);
  });

  testWidgets('home search fits 360px with larger text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response('{"items":[],"total":0}', 200),
      ),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: api),
          ChangeNotifierProvider(
            create: (_) => SearchProvider(HotelRepository(api)),
          ),
        ],
        child: MaterialApp(
          theme: TttpTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: Scaffold(body: HomeScreen(onSearch: () {})),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

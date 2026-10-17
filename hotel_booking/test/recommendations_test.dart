import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking/app/app_theme.dart';
import 'package:hotel_booking/providers/search_provider.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/widgets/recommended_rooms.dart';

void main() {
  testWidgets(
    'public recommendations show two columns and hide after API disconnect',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var connected = true;
      final api = ApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/rooms/recommended');
          if (!connected) throw http.ClientException('offline');
          return http.Response(
            jsonEncode({
              'items': [
                for (int i = 1; i <= 4; i++)
                  {
                    'ma_phong': i,
                    'ma_lp': 1,
                    'gia_co_ban': 500000,
                    'suc_chua': 2,
                    'so_phong': '10$i',
                    'ten_loai': 'Standard',
                    'trang_thai_su_dung': i == 4 ? 'DANG_SU_DUNG' : 'CON_TRONG',
                  },
              ],
            }),
            200,
          );
        }),
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
              ),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: RecommendedRooms(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Phòng đề xuất'), findsOneWidget);
      expect(find.byKey(const ValueKey('recommended-room-4')), findsNothing);
      final one = tester.getTopLeft(
        find.byKey(const ValueKey('recommended-room-1')),
      );
      final two = tester.getTopLeft(
        find.byKey(const ValueKey('recommended-room-2')),
      );
      final three = tester.getTopLeft(
        find.byKey(const ValueKey('recommended-room-3')),
      );
      expect(one.dy, two.dy);
      expect(two.dx, greaterThan(one.dx));
      expect(three.dy, greaterThan(one.dy));
      expect(tester.takeException(), isNull);
      connected = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Phòng đề xuất'), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

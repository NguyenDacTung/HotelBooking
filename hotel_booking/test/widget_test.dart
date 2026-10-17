import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking/models/models.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/providers/search_provider.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/screens/auth/account.dart';
import 'package:hotel_booking/screens/demo.dart';

class MemoryTokens extends TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  test(
    'search completing after logout disposal does not notify disposed provider',
    () async {
      final response = Completer<http.Response>();
      final api = ApiService(client: MockClient((_) => response.future));
      final provider = SearchProvider(HotelRepository(api));
      final pending = provider.search();
      provider.dispose();
      response.complete(http.Response('{"items":[],"total":0,"page":1}', 200));
      await expectLater(pending, completes);
    },
  );
  test('timeout after POST is uncertain and never retries', () async {
    var sends = 0;
    final api = ApiService(
      requestTimeout: const Duration(milliseconds: 5),
      client: MockClient((_) async {
        sends++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 201);
      }),
    );
    await expectLater(
      api.request('POST', '/bookings', body: {'ma_phong': 1}),
      throwsA(
        isA<ApiError>().having(
          (e) => e.message,
          'message',
          contains('Chưa xác định'),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sends, 1);
  });
  test(
    'JSON list reads items and booking request excludes server-owned values',
    () {
      final page = PageData<Room>.fromJson(
        jsonDecode(
          '{"items":[{"ma_phong":21,"ma_lp":2,"so_phong":"101","ten_loai":"Deluxe","gia_co_ban":850000,"suc_chua":2}],"page":1,"total":1}',
        ) as Json,
        Room.fromJson,
      );
      expect(page.items.single.id, 21);
      expect(Room.fromJson(page.items.single.toJson()).number, '101');
      final request = BookingRequest(
        roomId: 21,
        guests: 2,
        start: '2027-01-01',
        end: '2027-01-02',
        name: ' A ',
        phone: '0900000000',
      ).toJson();
      expect(request['ten_lien_he'], 'A');
      expect(request.keys, isNot(contains('tong_tien')));
      expect(request.keys, isNot(contains('ma_kh')));
    },
  );
  test('HTTP serializes JSON and bearer, preserves API error', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token');
        expect(jsonDecode(request.body)['ma_phong'], 1);
        return http.Response(
          '{"error":{"code":"ROOM_UNAVAILABLE","message":"Phòng đã có người đặt"}}',
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    )..token = 'token';
    await expectLater(
      api.request('POST', '/bookings', body: {'ma_phong': 1}),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 409)),
    );
  });
  test('401 clears stored token; no staff privilege remains', () async {
    final storage = MemoryTokens()..value = 'expired';
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"message":"Hết phiên"}}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final session = SessionProvider(api, storage);
    await session.restore();
    expect(api.token, isNull);
    expect(storage.value, isNull);
    expect(session.staff, isFalse);
  });
  test('search error resets loading and surfaces server failure', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"message":"Ngày không hợp lệ"}}',
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final provider = SearchProvider(HotelRepository(api));
    final pending = provider.search();
    expect(provider.loading, isTrue);
    await pending;
    expect(provider.loading, isFalse);
    expect(provider.error, 'Ngày không hợp lệ');
    expect(provider.rooms, isEmpty);
  });
  testWidgets('offline demo is clearly marked and cannot place bookings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DemoScreen()));
    expect(find.textContaining('DEMO NGOẠI TUYẾN'), findsOneWidget);
    expect(find.textContaining('không gửi đặt phòng'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
  testWidgets('login validates before making a request', (tester) async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 500);
      }),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: api),
          ChangeNotifierProvider(
            create: (_) => SessionProvider(api, MemoryTokens()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(calls, 0);
  });
}

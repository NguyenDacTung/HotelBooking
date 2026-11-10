import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_booking/providers/booking_provider.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('anonymous 401 never logs out a user', () async {
    var callbackCount = 0;
    final api = ApiService(client: MockClient((_) async => http.Response(
          '{"error":{"message":"Unauthorized"}}', 401,
        )));
    api.onUnauthorized = () async {
      callbackCount++;
    };
    await expectLater(api.request('GET', '/bookings/my'), throwsA(isA<ApiError>()));
    expect(callbackCount, 0);
  });

  test('parallel expired-token replies trigger logout only once', () async {
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    var calls = 0;
    final api = ApiService(client: MockClient((_) => ++calls == 1
        ? first.future : second.future));
    api.token = 'expired';
    var callbackCount = 0;
    api.onUnauthorized = () async {
      callbackCount++;
    };
    final a = api.request('GET', '/users/me');
    final b = api.request('GET', '/bookings/my');
    first.complete(http.Response('{"error":{"message":"Expired"}}', 401));
    await expectLater(a, throwsA(isA<ApiError>()));
    second.complete(http.Response('{"error":{"message":"Expired"}}', 401));
    await expectLater(b, throwsA(isA<ApiError>()));
    expect(callbackCount, 1);
    expect(api.token, isNull);
  });

  test('old booking-filter response cannot overwrite new results', () async {
    final first = Completer<http.Response>();
    var calls = 0;
    final api = ApiService(client: MockClient((request) async {
      if (++calls == 1) return first.future;
      expect(request.url.queryParameters['trang_thai'], 'DA_XAC_NHAN');
      return http.Response('{"items":[],"total":0,"page":1}', 200);
    }));
    final bookings = BookingProvider(HotelRepository(api));
    final oldLoad = bookings.load(false);
    bookings.status = 'DA_XAC_NHAN';
    await bookings.load(false);
    first.complete(http.Response('{"items":[],"total":13,"page":1}', 200));
    await oldLoad;
    expect(bookings.total, 0);
    expect(bookings.status, 'DA_XAC_NHAN');
    expect(bookings.loading, false);
    bookings.dispose();
  });
}

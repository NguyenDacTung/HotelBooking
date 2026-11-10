import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hotel_booking/providers/search_provider.dart';
import 'package:hotel_booking/providers/session_provider.dart';
import 'package:hotel_booking/repositories/hotel_repository.dart';
import 'package:hotel_booking/models/search_criteria.dart';
import 'package:hotel_booking/services/api_service.dart';
import 'package:hotel_booking/services/token_storage.dart';

class _MemoryTokens extends TokenStorage {
  String? current;
  @override
  Future<String?> read() async => current;
  @override
  Future<void> write(String token) async => current = token;
  @override
  Future<void> clear() async => current = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing customer search filters ignores an older server response', () async {
    final first = Completer<http.Response>();
    var count = 0;
    final api = ApiService(client: MockClient((request) async {
      if (++count == 1) return first.future;
      return http.Response('{"items":[],"total":0}', 200);
    }));
    final provider = SearchProvider(HotelRepository(api));
    final pending = provider.search();
    provider.setCriteria(SearchCriteria(
      start: DateUtilsVN.today,
      end: DateUtilsVN.today.add(const Duration(days: 2)),
      guests: 3,
    ));
    await provider.search();
    first.complete(http.Response('{"items":[],"total":999}', 200));
    await pending;
    expect(provider.total, 0);
    expect(provider.guests, 3);
    expect(provider.loading, isFalse);
    provider.dispose();
  });

  test('customer logout clears local login even with no server connection', () async {
    final tokens = _MemoryTokens()..current = 'saved-token';
    final api = ApiService(client: MockClient((_) async =>
      throw http.ClientException('offline')));
    final session = SessionProvider(api, tokens)
      ..user = {'id':'customer-1','ma_quyen':'KHACH_HANG'};
    api.token = 'saved-token';
    await session.logout();
    expect(session.user, isNull);
    expect(api.token, isNull);
    expect(tokens.current, isNull);
  });
}

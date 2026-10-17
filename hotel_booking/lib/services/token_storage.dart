import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage storage;
  const TokenStorage({this.storage = const FlutterSecureStorage()});
  Future<String?> read() => storage.read(key: 'access_token');
  Future<void> write(String token) =>
      storage.write(key: 'access_token', value: token);
  Future<void> clear() => storage.delete(key: 'access_token');
}

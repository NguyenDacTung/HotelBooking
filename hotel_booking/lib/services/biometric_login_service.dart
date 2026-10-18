import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'api_service.dart';

/// Only public device metadata is stored here. The signing key never leaves
/// Android Keystore and requires a fresh biometric CryptoObject operation.
class BiometricLoginService {
  static const preferenceKey = 'tetra-biometric-login-v1';
  final MethodChannel channel;
  const BiometricLoginService({
    this.channel = const MethodChannel('tetra/biometric-login'),
  });

  Future<Json?> registration() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(preferenceKey);
    if (value == null) return null;
    try {
      final data = jsonDecode(value);
      if (data is! Json ||
          data['account_id'] is! String ||
          data['device_id'] is! String) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> available() async {
    try {
      return await channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> enable(ApiService api, Json user, String password) async {
    if (!await available()) {
      throw const ApiError(
        'Hãy đăng ký vân tay trong cài đặt điện thoại trước khi bật chức năng này.',
      );
    }
    final previous = await registration();
    final id = const Uuid().v4();
    var created = false;
    try {
      final public = await channel.invokeMethod<String>('create', {
        'device_id': id,
      });
      if (public == null) {
        throw const ApiError('Không tạo được khóa đăng nhập trên thiết bị.');
      }
      final challenge = await api.request(
        'POST',
        '/users/me/biometric',
        body: {'device_id': id, 'public_key': public, 'mat_khau': password},
      ) as Json;
      created = true;
      final signed = await sign(id, challenge['message'] as String);
      await api.request(
        'POST',
        '/users/me/biometric/confirm',
        body: {'challenge_id': challenge['challenge_id'], 'signature': signed},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        preferenceKey,
        jsonEncode({'account_id': user['id'], 'device_id': id}),
      );
      if (previous != null) {
        // Never delete a key belonging to the newly enrolled device.
        if (previous['account_id'] == user['id']) {
          try {
            await api.request(
              'DELETE',
              '/users/me/biometric/${previous['device_id']}',
            );
          } catch (_) {
            /* old private key is destroyed below */
          }
        }
        try {
          await channel.invokeMethod<void>('delete', {
            'device_id': previous['device_id'],
          });
        } on PlatformException {
          /* the newly confirmed device remains valid */
        }
      }
    } catch (_) {
      if (created) {
        try {
          await api.request('DELETE', '/users/me/biometric/$id');
        } catch (_) {
          /* unconfirmed/unused device expires server-side */
        }
      }
      await channel.invokeMethod<void>('delete', {'device_id': id});
      rethrow;
    }
  }

  Future<void> disable(ApiService api, String accountId) async {
    final data = await registration();
    if (data == null || data['account_id'] != accountId) return;
    await api.request('DELETE', '/users/me/biometric/${data['device_id']}');
    await forget();
  }

  Future<void> forget() async {
    final data = await registration();
    if (data != null) {
      try {
        await channel.invokeMethod<void>('delete', {
          'device_id': data['device_id'],
        });
      } on PlatformException {
        /* metadata must still be removed */
      }
    }
    await (await SharedPreferences.getInstance()).remove(preferenceKey);
  }

  Future<String> sign(String id, String message) async {
    try {
      final value = await channel.invokeMethod<String>('sign', {
        'device_id': id,
        'message': message,
      });
      if (value == null) {
        throw const ApiError(
          'Chưa xác thực vân tay. Bạn vẫn có thể dùng mật khẩu.',
        );
      }
      return value;
    } on PlatformException catch (e) {
      if (e.code == 'KEY_INVALID') {
        if ((await registration())?['device_id'] == id) {
          await forget();
        }
        throw const ApiError(
          'Vân tay hoặc khóa thiết bị đã thay đổi. Đăng nhập bằng mật khẩu rồi bật lại vân tay.',
        );
      }
      throw const ApiError(
        'Chưa xác thực vân tay. Thử lại hoặc đăng nhập bằng mật khẩu.',
      );
    }
  }

  Future<Json> proof(ApiService api) async {
    final data = await registration();
    if (data == null) {
      throw const ApiError(
        'Đăng nhập bằng email/mật khẩu lần đầu, rồi bật Đăng nhập bằng vân tay trong Cài đặt.',
      );
    }
    if (!await available()) {
      throw const ApiError(
        'Vân tay chưa sẵn sàng. Bạn có thể đăng nhập bằng email và mật khẩu.',
      );
    }
    try {
      final challenge = await api.request(
        'POST',
        '/auth/biometric/challenge',
        body: {'device_id': data['device_id']},
      ) as Json;
      return {
        'challenge_id': challenge['challenge_id'],
        'signature': await sign(
          data['device_id'],
          challenge['message'] as String,
        ),
      };
    } on ApiError catch (e) {
      if (e.status == 401) await forget();
      rethrow;
    }
  }
}

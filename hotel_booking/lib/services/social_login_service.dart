import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'api_service.dart';

class SocialLoginService {
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const facebookEnabled = bool.fromEnvironment(
    'FACEBOOK_ENABLED',
    defaultValue: false,
  );
  static bool _initialized = false;
  Future<String> credential(String provider) async {
    if (provider == 'google') {
      if (googleClientId.isEmpty) {
        throw const ApiError('Google chưa được cấu hình');
      }
      if (!_initialized) {
        await GoogleSignIn.instance.initialize(serverClientId: googleClientId);
        _initialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const ApiError('Không nhận được xác minh Google');
      }
      return token;
    }
    if (!facebookEnabled) throw const ApiError('Facebook chưa được cấu hình');
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile'],
    );
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw const ApiError('Đăng nhập Facebook chưa hoàn tất');
    }
    return result.accessToken!.tokenString;
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Public settings supplied by Android at startup, before any services exist.
/// Backend credentials must never be included in this configuration.
class ClientConfig {
  static const channel = MethodChannel('tetra/client-config');
  static Map<String, dynamic> _settings = {};

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final encoded = await channel.invokeMethod<String>('load');
    _settings = jsonDecode(encoded!) as Map<String, dynamic>;
  }

  // Explicit build flags take precedence, including intentionally empty values.
  static const _overrides = <String, String>{
    // An empty API URL asks Android to choose USB/emulator automatically.
    if (bool.hasEnvironment('API_BASE_URL') &&
        String.fromEnvironment('API_BASE_URL') != '')
      'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    if (bool.hasEnvironment('GOOGLE_SERVER_CLIENT_ID'))
      'GOOGLE_SERVER_CLIENT_ID': String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ),
    if (bool.hasEnvironment('FACEBOOK_ENABLED'))
      'FACEBOOK_ENABLED': String.fromEnvironment('FACEBOOK_ENABLED'),
    if (bool.hasEnvironment('FIREBASE_API_KEY'))
      'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
    if (bool.hasEnvironment('FIREBASE_APP_ID'))
      'FIREBASE_APP_ID': String.fromEnvironment('FIREBASE_APP_ID'),
    if (bool.hasEnvironment('FIREBASE_MESSAGING_SENDER_ID'))
      'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
    if (bool.hasEnvironment('FIREBASE_PROJECT_ID'))
      'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
  };

  static String string(String key, {String fallback = ''}) =>
      _overrides[key] ?? _settings[key] as String? ?? fallback;

  static bool get facebookEnabled => _overrides.containsKey('FACEBOOK_ENABLED')
      ? _overrides['FACEBOOK_ENABLED'] == 'true'
      : _settings['FACEBOOK_ENABLED'] == true;
}

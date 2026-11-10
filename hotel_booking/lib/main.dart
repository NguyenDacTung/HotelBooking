import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/client_config.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClientConfig.initialize();
  try {
    await PushService.initialize();
  } catch (_) {
    /* App remains usable without Firebase. */
  }
  runApp(const HotelApp());
}

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await PushService.initialize();
  } catch (_) {
    /* App remains usable without Firebase. */
  }
  runApp(const HotelApp());
}

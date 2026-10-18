import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

abstract final class AppFeedback {
  static void configure() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = const Color(0xFF123A52)
      ..indicatorColor = const Color(0xFFF0CF93)
      ..textColor = Colors.white
      ..maskColor = Colors.black26
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  static Future<T> blocking<T>(String label, Future<T> Function() task) async {
    await EasyLoading.show(status: label, maskType: EasyLoadingMaskType.custom);
    try {
      return await task();
    } finally {
      await EasyLoading.dismiss();
    }
  }
}

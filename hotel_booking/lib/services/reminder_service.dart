import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> initialize(void Function(String) onTap) async {
    if (ready) return;
    tzdata.initializeTimeZones();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_tttp'),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) onTap(r.payload!);
      },
    );
    ready = true;
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload != null) {
      onTap(launch!.notificationResponse!.payload!);
    }
  }

  static int stableId(String booking) {
    var hash = 2166136261;
    for (final v in booking.codeUnits) {
      hash = ((hash ^ v) * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  Future<bool> requestPermission() async =>
      (await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission()) ??
      false;
  Future<void> clear() async {
    if (ready) await plugin.cancelAll();
  }

  Future<void> sync(
    List<Json> bookings, {
    int hour = 18,
    int minute = 0,
  }) async {
    if (!ready) return;
    await plugin.cancelAll();
    final zone = tz.getLocation('Asia/Ho_Chi_Minh');

    for (final b in bookings) {
      final day = DateTime.parse(b['ngay_nhan'] as String);
      final before = DateTime(
        day.year,
        day.month,
        day.day,
      ).subtract(const Duration(days: 1));
      final when = tz.TZDateTime(
        zone,
        before.year,
        before.month,
        before.day,
        hour,
        minute,
      );
      if (b['trang_thai'] != 'DA_XAC_NHAN' ||
          !when.isAfter(tz.TZDateTime.now(zone))) {
        continue;
      }
      await plugin.zonedSchedule(
        stableId(b['ma_pdp'] as String),
        'TETRA · Nhắc lịch nhận phòng',
        'Bạn có lịch nhận phòng sắp tới. Mở TETRA để xem chi tiết.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tttp_reminders',
            'Nhắc nhận phòng',
            channelDescription: 'Nhắc buổi tối trước ngày nhận phòng',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: b['ma_pdp'] as String,
      );
    }
  }
}

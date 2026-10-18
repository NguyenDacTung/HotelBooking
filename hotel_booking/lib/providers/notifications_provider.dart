import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/reminder_service.dart';
import '../services/push_service.dart';
import 'session_provider.dart';

class NotificationsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SessionProvider session;
  final ApiService api;
  final ReminderService reminders;
  final void Function(String) onTap;
  List<Json> items = [];
  int unread = 0, page = 1, total = 0, _epoch = 0;
  bool loading = false, enabled = false, _disposed = false, _foreground = true;
  String? error, _account;
  Timer? _timer;
  bool pushEnabled = false;
  int reminderHour = 18, reminderMinute = 0;
  Future<void> setReminderTime(int hour, int minute) async {
    if (_account == null) return;
    reminderHour = hour;
    reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tetra_reminder_minutes_$_account', hour * 60 + minute);
    await refresh();
    _notify();
  }

  Future<void> setPushEnabled(bool value) async {
    if (value) {
      await PushService.instance.enable(api, onTap, refresh: () => refresh());
    } else {
      await PushService.instance.disable(api);
    }
    pushEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    if (_account != null) await prefs.setBool('tttp_push_$_account', value);
    _notify();
  }

  NotificationsProvider(this.session, this.api, this.reminders, this.onTap) {
    WidgetsBinding.instance.addObserver(this);
    session.addListener(_sessionChanged);
    _sessionChanged();
  }
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    session.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _sessionChanged() {
    final account = session.user?['id'] as String?;
    if (account == _account) return;
    _account = account;
    _epoch++;
    _timer?.cancel();
    items = [];
    unread = 0;
    enabled = false;
    pushEnabled = false;
    loading = false;
    reminders.clear();
    if (account != null) {
      _initialize(account, _epoch);
      _poll();
    }
    _notify();
  }

  Future<void> _initialize(String account, int epoch) async {
    try {
      await reminders.initialize(onTap);
      final prefs = await SharedPreferences.getInstance();
      if (epoch != _epoch) return;
      enabled = prefs.getBool('tttp_reminders_$account') ?? false;
      final minutes = prefs.getInt('tetra_reminder_minutes_$account') ?? 1080;
      reminderHour = minutes ~/ 60;
      reminderMinute = minutes % 60;
      if (PushService.configured &&
          (prefs.getBool('tttp_push_$account') ?? false)) {
        try {
          await setPushEnabled(true);
        } catch (_) {
          pushEnabled = false;
        }
      }
      await refresh();
    } catch (e) {
      if (epoch == _epoch) {
        error = 'Không thể khởi tạo nhắc lịch trên thiết bị này.';
        _notify();
      }
    }
  }

  void _poll() {
    _timer?.cancel();
    if (_foreground && _account != null) {
      _timer = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _poll();
      refresh();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> refresh({bool more = false}) async {
    if (_account == null || loading || _disposed) return;
    final epoch = _epoch;
    loading = true;
    error = null;
    _notify();
    try {
      final next = more ? page + 1 : 1;
      final values = await Future.wait([
        api.request('GET', '/notifications', query: {'page': next}),
        api.request('GET', '/notifications/unread-count'),
      ]);
      if (epoch != _epoch || _disposed) return;
      final data = values[0] as Json;
      final rows = (data['items'] as List).cast<Json>();
      items = more ? [...items, ...rows] : rows;
      page = next;
      total = data['total'] as int;
      unread = (values[1] as Json)['count'] as int;
      if (enabled && !session.staff) {
        final bookings = <Json>[];
        int page = 1, count = 1;
        while (bookings.length < count) {
          final result = await api.request(
            'GET',
            '/bookings/my',
            query: {
              'trang_thai': 'DA_XAC_NHAN',
              'page_size': 100,
              'page': page++,
            },
          ) as Json;
          bookings.addAll((result['items'] as List).cast<Json>());
          count = result['total'] as int;
        }
        if (epoch == _epoch) {
          await reminders.sync(
            bookings,
            hour: reminderHour,
            minute: reminderMinute,
          );
          if (epoch != _epoch) await reminders.clear();
        }
      }
    } catch (e) {
      if (epoch == _epoch) error = '$e';
    } finally {
      if (epoch == _epoch) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_account == null) return;
    if (value) {
      await reminders.initialize(onTap);
      if (!await reminders.requestPermission()) {
        error = 'Quyền thông báo chưa được cấp. Bạn vẫn có thể dùng TETRA bình thường.';
        _notify();
        return;
      }
    }
    enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tttp_reminders_$_account', value);
    if (!value) {
      await reminders.clear();
    } else {
      await refresh();
    }
    _notify();
  }

  Future<void> read(Json item) async {
    await api.request('PATCH', '/notifications/${item['id']}/read');
    await refresh();
  }

  Future<void> readAll() async {
    await api.request('PATCH', '/notifications/read-all');
    await refresh();
  }
}

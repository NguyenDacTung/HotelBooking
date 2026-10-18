import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/shared/reviews_screen.dart';
import '../screens/shared/hotel_info_screen.dart';
import '../screens/shared/settings_screen.dart';
import '../screens/shared/feedback_screen.dart';
import '../screens/staff/room_calendar_screen.dart';
import '../screens/staff/booking_scanner_screen.dart';
import '../screens/admin/room_import_screen.dart';
import '../screens/admin/hotel_settings_screen.dart';
import '../screens/admin/feedback_admin_screen.dart';

import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/notification_settings_screen.dart';
import '../screens/admin/accounts_screen.dart';
import '../screens/admin/room_types_screen.dart';
import '../screens/admin/rooms_screen.dart';
import '../screens/admin/amenities_screen.dart';
import '../screens/admin/room_closures_screen.dart';

class AppRouter {
  static final _screens = <String, WidgetBuilder>{
    '/login': (_) => const LoginScreen(),
    '/register': (_) => const RegisterScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/notifications': (_) => const NotificationsScreen(),
    '/notification-settings': (_) => const NotificationSettingsScreen(),
    '/admin/accounts': (_) => const AccountsScreen(),
    '/admin/room-types': (_) => const RoomTypesScreen(),
    '/admin/rooms': (_) => const RoomsScreen(),
    '/admin/amenities': (_) => const AmenitiesScreen(),
    '/admin/closures': (_) => const RoomClosuresScreen(),
    '/hotel-info': (_) => const HotelInfoScreen(),
    '/settings': (_) => const SettingsScreen(),
    '/feedback': (_) => const FeedbackScreen(),
    '/my-reviews': (_) => const ReviewsScreen(),
    '/admin/reviews': (_) => const ReviewsScreen(admin: true),
    '/admin/room-import': (_) => const RoomImportScreen(),
    '/admin/hotel-settings': (_) => const HotelSettingsScreen(),
    '/admin/feedback': (_) => const FeedbackAdminScreen(),
    '/staff/calendar': (_) => const RoomCalendarScreen(),
    '/staff/scanner': (_) => const BookingScannerScreen(),
  };
  static final routes = <String, WidgetBuilder>{
    for (final e in _screens.entries)
      e.key: (context) {
        final s = context.watch<SessionProvider>();
        final admin = e.key.startsWith('/admin/'),
            staff = e.key.startsWith('/staff/');
        final private =
            admin ||
            staff ||
            {
              '/profile',
              '/notifications',
              '/notification-settings',
              '/feedback',
              '/my-reviews',
            }.contains(e.key);
        if (private && s.user == null) return const LoginScreen();
        if ((admin && !s.manager) || (staff && !s.staff)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quyền truy cập')),
            body: const Center(
              child: Text('Tài khoản không có quyền mở mục này'),
            ),
          );
        }
        final screen = e.value(context);
        return e.key == '/profile'
            ? Scaffold(
                appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
                body: screen,
              )
            : screen;
      },
  };
}

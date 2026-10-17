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
  static final routes = <String, WidgetBuilder>{
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
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';
import '../services/reminder_service.dart';
import '../repositories/hotel_repository.dart';
import '../providers/session_provider.dart';
import '../providers/search_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/notifications_provider.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/search_screen.dart';
import '../screens/customer/my_bookings_screen.dart';
import '../screens/customer/booking_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/staff/booking_list_screen.dart';
import '../screens/staff/room_status_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/revenue_report_screen.dart';
import '../screens/demo.dart';
import '../widgets/connectivity_banner.dart';
import 'app_theme.dart';
import 'app_router.dart';

final hotelNavigatorKey = GlobalKey<NavigatorState>();
Future<void> openNotificationBooking(String id) async {
  final nav = hotelNavigatorKey.currentState;
  if (nav == null) return;
  final session = nav.context.read<SessionProvider>();
  if (session.user == null) {
    await nav.push(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
    if (session.user == null) return;
  }
  nav.push(
    MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: id)),
  );
}

class HotelApp extends StatelessWidget {
  const HotelApp({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider(create: (_) => ApiService()),
      Provider(create: (c) => HotelRepository(c.read<ApiService>())),
      ChangeNotifierProvider(
        create: (c) {
          final api = c.read<ApiService>();
          final session = SessionProvider(api, const TokenStorage());
          api.onUnauthorized = () async {
            await session.logout();
            final nav = hotelNavigatorKey.currentState;
            if (nav != null) {
              nav.popUntil((r) => r.isFirst);
              nav.push(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              );
            }
          };
          if (!demoMode) session.restore();
          return session;
        },
      ),
      ChangeNotifierProvider(
        create: (c) => SearchProvider(c.read<HotelRepository>()),
      ),
      ChangeNotifierProvider(
        create: (c) => NotificationsProvider(
          c.read<SessionProvider>(),
          c.read<ApiService>(),
          ReminderService(),
          openNotificationBooking,
        ),
      ),
    ],
    child: MaterialApp(
      navigatorKey: hotelNavigatorKey,
      title: 'TTTP · Đặt phòng',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: TttpTheme.light,
      routes: AppRouter.routes,
      home: demoMode ? const DemoScreen() : const SessionShell(),
    ),
  );
}

class SessionShell extends StatelessWidget {
  const SessionShell({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionProvider>();
    if (s.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MultiProvider(
      key: ValueKey(s.user?['id']),
      providers: [
        ChangeNotifierProvider(
          create: (c) => BookingProvider(c.read<HotelRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AdminProvider(c.read<ApiService>()),
        ),
      ],
      child: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final tabs = <int, Widget>{};
  void select(int value) {
    setState(() => index = value);
    final s = context.read<SessionProvider>();
    if (s.user != null) context.read<NotificationsProvider>().refresh();
    if ((!s.staff && value == 2) ||
        (s.staff && !s.manager && value == 0) ||
        (s.manager && value == 1)) {
      context.read<BookingProvider>().load(s.staff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionProvider>();
    final n = context.watch<NotificationsProvider>();
    final factories = s.manager
        ? <Widget Function()>[
            () => const DashboardScreen(),
            () => const StaffBookingListScreen(),
            () => const RevenueReportScreen(),
            () => const ProfileScreen(),
          ]
        : s.staff
        ? <Widget Function()>[
            () => const StaffBookingListScreen(),
            () => const RoomStatusScreen(),
            () => const ProfileScreen(),
          ]
        : <Widget Function()>[
            () => HomeScreen(onSearch: () => select(1)),
            () => const SearchScreen(),
            () => const MyBookingsScreen(),
            () => const ProfileScreen(),
          ];
    final labels = s.manager
        ? ['Tổng quan', 'Đặt phòng', 'Báo cáo', 'Tài khoản']
        : s.staff
        ? ['Yêu cầu đặt phòng', 'Tình trạng phòng', 'Tài khoản']
        : ['Trang chủ', 'Tìm phòng', 'Lịch sử', 'Tài khoản'];
    final icons = s.manager
        ? [
            Icons.dashboard_outlined,
            Icons.receipt_long_outlined,
            Icons.bar_chart_outlined,
            Icons.person_outline,
          ]
        : s.staff
        ? [
            Icons.receipt_long_outlined,
            Icons.meeting_room_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.hotel_outlined,
            Icons.search,
            Icons.receipt_long_outlined,
            Icons.person_outline,
          ];
    index = index.clamp(0, factories.length - 1);
    tabs.putIfAbsent(index, factories[index]);

    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 && !s.staff ? 'Khách sạn TTTP' : labels[index]),
        actions: [
          if (s.user != null)
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
              icon: Badge(
                isLabelVisible: n.unread > 0,
                label: Text('${n.unread}'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
        ],
      ),
      drawer: s.manager
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      child: Text(
                        'TTTP\nQuản trị khách sạn',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final entry in {
                      '/admin/room-types': 'Loại phòng và ảnh',
                      '/admin/rooms': 'Phòng',
                      '/admin/amenities': 'Tiện nghi',
                      '/admin/closures': 'Lịch tạm ngừng',
                      '/admin/accounts': 'Quản lý tài khoản',
                    }.entries)
                      ListTile(
                        title: Text(entry.value),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, entry.key);
                        },
                      ),
                    ListTile(
                      title: const Text('Tình trạng phòng'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Tình trạng phòng'),
                              ),
                              body: const RoomStatusScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                for (int i = 0; i < factories.length; i++)
                  tabs[i] ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
      // CẢI TIẾN: Biến thanh điều hướng dưới thành dạng nổi bo tròn (Floating & Rounded) phong cách iPhone
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF123A52),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF123A52).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              elevation: 0,
              backgroundColor: const Color(0xFF123A52),
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFB58A45),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? const Color(0xFFF0CF93)
                      : const Color(0xFFE1EAF0),
                  fontSize: 12,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              selectedIndex: index,
              onDestinationSelected: select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (int i = 0; i < labels.length; i++)
                  NavigationDestination(
                    icon: Icon(icons[i], color: const Color(0xFFE1EAF0)),
                    selectedIcon: Icon(
                      icons[i],
                      color: const Color(0xFF152536),
                    ),
                    label: labels[i],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../core/strings.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final u = session.user;
    void open(String route) {
      Navigator.pop(context);
      Navigator.pushNamed(context, route);
    }

    final menus = <String, String>{
      if (session.manager) ...{
        '/admin/room-types': 'Loại phòng',
        '/admin/rooms': 'Phòng',
        '/admin/amenities': 'Tiện nghi',
        '/admin/closures': 'Lịch tạm ngừng',
        '/admin/accounts': 'Quản lý tài khoản',
        '/admin/reviews': 'Quản lý đánh giá',
        '/admin/feedback': 'Phản hồi khách hàng',
        '/admin/room-import': 'Nhập phòng từ CSV',
      },
      if (session.staff) ...{
        '/staff/calendar': 'Lịch phòng',
        '/staff/scanner': 'Quét mã đặt phòng',
      },
      if (u != null && !session.staff) '/my-reviews': 'Đánh giá của tôi',
      '/hotel-info': 'Thông tin khách sạn',
      if (u != null) '/feedback': 'Góp ý và báo lỗi',
      '/settings': 'Cài đặt',
    };
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  InkWell(
                    onTap: () => open(u == null ? '/login' : '/profile'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: u?['avatar_url'] != null
                                ? CachedNetworkImageProvider(
                                    context.read<ApiService>().imageUrl(
                                      u!['avatar_url'],
                                    ),
                                  )
                                : null,
                            child: u?['avatar_url'] == null
                                ? const Icon(Icons.person_outline, size: 36)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            u?['ho_ten'] ?? 'Chào mừng đến TETRA',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (u != null) ...[
                            Text(u['email'] ?? ''),
                            Text(
                              TttpStrings.roleNames[u['ma_quyen']] ??
                                  'Tài khoản',
                            ),
                          ] else
                            const Text('Đăng nhập / Đăng ký'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  for (final e in menus.entries)
                    ListTile(
                      title: Text(e.value),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => open(e.key),
                    ),
                ],
              ),
            ),
            if (u != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  Navigator.pop(context);
                  await session.logout();
                },
              ),
          ],
        ),
      ),
    );
  }
}

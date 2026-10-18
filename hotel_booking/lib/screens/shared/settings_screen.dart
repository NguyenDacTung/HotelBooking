import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../providers/capabilities_provider.dart';
import '../../services/biometric_login_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import 'change_password_screen.dart';
import 'linked_accounts_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool bio = false, busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final id = context.read<SessionProvider>().user?['id'];
    if (id == null) return;
    final registration = await const BiometricLoginService().registration();
    if (mounted) setState(() => bio = registration?['account_id'] == id);
  }

  void open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  Future<String?> enrollmentPassword() async {
    final controller = TextEditingController();
    final accepted = await formDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bật đăng nhập bằng vân tay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xác nhận mật khẩu một lần để đăng ký điện thoại. Những lần đăng nhập sau chỉ cần vân tay.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu tài khoản',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    final value = controller.text;
    controller.dispose();
    return accepted == true && value.isNotEmpty ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionProvider>();
    final caps = context.watch<CapabilitiesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          if (s.user != null) ...[
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Đổi mật khẩu'),
              onTap: () => open(const ChangePasswordScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Tài khoản liên kết'),
              onTap: () => open(const LinkedAccountsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Thông báo và nhắc lịch'),
              onTap: () => open(const NotificationSettingsScreen()),
            ),
            SwitchListTile(
              value: bio,
              onChanged: busy
                  ? null
                  : (v) async {
                      setState(() => busy = true);
                      try {
                        final api = context.read<ApiService>();
                        const service = BiometricLoginService();
                        if (v) {
                          final password = await enrollmentPassword();
                          if (password == null || !mounted) return;
                          await service.enable(api, s.user!, password);
                        } else {
                          await service.disable(api, s.user!['id']);
                        }
                        if (mounted && context.mounted) {
                          setState(() => bio = v);
                          message(
                            context,
                            v
                                ? 'Đã bật. Lần sau bấm vân tay ở màn đăng nhập.'
                                : 'Đã tắt đăng nhập bằng vân tay.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          message(context, e);
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              title: const Text('Đăng nhập bằng vân tay'),
              subtitle: const Text(
                'Bật một lần cho tài khoản này. Lần sau bấm vân tay ở màn đăng nhập, không cần nhập email/mật khẩu. Mỗi điện thoại lưu một tài khoản; đăng xuất vẫn giữ lựa chọn này. Tắt tại đây nếu dùng máy chung.',
              ),
            ),
          ],
          const Divider(),
          const ListTile(
            title: Text('Kết nối dịch vụ'),
            subtitle: Text(
              'Chỉ hiển thị trạng thái cấu hình; không hiển thị khóa bí mật.',
            ),
          ),
          if (caps.loading) const LinearProgressIndicator(),
          if (caps.error != null) ErrorPanel(caps.unavailable, caps.load),
          for (final e in {
            'MoMo': caps.ready('payments', 'momo'),
            'VNPAY': caps.ready('payments', 'vnpay'),
            'Email khôi phục': caps.ready('recovery'),
            'Push': caps.ready('push'),
          }.entries)
            ListTile(
              title: Text(e.key),
              subtitle: Text(
                caps.data == null
                    ? caps.unavailable
                    : e.value
                    ? 'Đã có cấu hình máy chủ; còn cần kiểm tra thiết bị/dịch vụ'
                    : 'Chưa cấu hình',
              ),
            ),
          if (s.manager)
            ListTile(
              leading: const Icon(Icons.settings_applications_outlined),
              title: const Text('Thông tin công khai khách sạn'),
              onTap: () =>
                  Navigator.pushNamed(context, '/admin/hotel-settings'),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('TETRA'),
            subtitle: const Text('Ứng dụng quản lý và đặt phòng khách sạn'),
          ),
        ],
      ),
    );
  }
}

import '../../providers/capabilities_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/notifications_provider.dart';
import '../../widgets/common.dart';
import '../../services/push_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationsProvider>();
    final caps = context.watch<CapabilitiesProvider?>();
    final pushReady = PushService.configured && (caps?.ready('push') ?? false);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Thông báo đẩy'),
              subtitle: Text(
                pushReady
                    ? 'Nhận thông báo khi có thay đổi đặt phòng'
                    : 'Chưa cấu hình dịch vụ thông báo',
              ),
              value: n.pushEnabled,
              onChanged: !pushReady
                  ? null
                  : (v) async {
                      try {
                        await n.setPushEnabled(v);
                      } catch (e) {
                        if (context.mounted) message(context, e);
                      }
                    },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF123A52).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                activeThumbColor: const Color(
                  0xFF237A57,
                ), // Đã cập nhật từ activeColor
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB58A45).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFFB58A45),
                  ),
                ),
                title: const Text(
                  'Nhắc lịch nhận phòng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152536),
                    fontSize: 16,
                  ),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Nhắc ngày trước khi nhận phòng theo giờ bạn chọn (giờ Việt Nam), chỉ cho đơn đã xác nhận.',
                    style: TextStyle(
                      color: Color(0xFF5C6875),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                value: n.enabled,
                onChanged: (v) async {
                  try {
                    await n.setEnabled(v);
                  } catch (e) {
                    if (context.mounted) message(context, e);
                  }
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Giờ nhắc ngày trước khi đến'),
            subtitle: Text(
              '${n.reminderHour.toString().padLeft(2, '0')}:${n.reminderMinute.toString().padLeft(2, '0')} • giờ Việt Nam',
            ),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: n.reminderHour,
                  minute: n.reminderMinute,
                ),
              );
              if (time != null) await n.setReminderTime(time.hour, time.minute);
            },
          ),
          if (n.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB42318).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                n.error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync_outlined,
                      size: 18,
                      color: Color(0xFF123A52),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý đồng bộ & Quyền hệ thống',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF123A52),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Mở lại ứng dụng để đồng bộ các thay đổi và lịch nhắc mới nhất.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Bạn có thể quản lý quyền thông báo trong cài đặt của điện thoại.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

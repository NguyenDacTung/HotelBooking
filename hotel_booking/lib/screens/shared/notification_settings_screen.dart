import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/notifications_provider.dart';
import '../../widgets/common.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationsProvider>();
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              activeThumbColor: const Color(0xFF237A57), // Đã cập nhật từ activeColor
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
                  'Nhắc lúc 18:00 ngày trước khi nhận phòng (giờ Việt Nam) cho đặt phòng đã xác nhận.',
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
                    Text(
                      'Lưu ý đồng bộ & Quyền hệ thống',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF123A52),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'TTTP chỉ đồng bộ thông báo khi ứng dụng đang mở. Nhắc lịch cục bộ có thể chưa cập nhật nếu đặt phòng bị hủy trên thiết bị khác khi bạn chưa mở lại app. Đây không phải push khi app tắt.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Push: chưa cấu hình dịch vụ FCM. Từ chối quyền thông báo không ảnh hưởng việc tìm và đặt phòng.',
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
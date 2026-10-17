import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/notifications_provider.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';
import '../customer/booking_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<NotificationsProvider>().refresh();
    });
  }

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
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB58A45),
            ),
            onPressed: n.loading
                ? null
                : () async {
                    try {
                      await n.readAll();
                    } catch (e) {
                      if (context.mounted) message(context, e);
                    }
                  },
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: n.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (n.loading)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFFB58A45),
                ),
              ),
            if (n.error != null) ...[
              const SizedBox(height: 8),
              ErrorPanel(n.error!, n.refresh),
            ],
            if (!n.loading && n.items.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: Color(0xFF5C6875),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có thông báo.',
                      style: TextStyle(
                        color: Color(0xFF5C6875),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ...n.items.map((item) {
              final unread = item['ngay_doc'] == null;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: unread
                        ? const Color(0xFFB58A45).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: unread ? 1.4 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (unread
                              ? const Color(0xFFB58A45)
                              : const Color(0xFF123A52))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unread
                          ? Icons.mark_email_unread_outlined
                          : Icons.drafts_outlined,
                      color: unread
                          ? const Color(0xFFB58A45)
                          : const Color(0xFF5C6875),
                    ),
                  ),
                  title: Text(
                    item['tieu_de'] as String,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF152536),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${item['noi_dung']}\n${vietnamTime(item['ngay_tao'] as String)}',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    try {
                      await n.read(item);
                      if (!context.mounted) return;
                      if (item['ma_pdp'] != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => BookingDetailScreen(
                              id: item['ma_pdp'] as String,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) message(context, e);
                    }
                  },
                ),
              );
            }),
            if (n.items.length < n.total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: n.loading ? null : () => n.refresh(more: true),
                  child: const Text('Tải thêm'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
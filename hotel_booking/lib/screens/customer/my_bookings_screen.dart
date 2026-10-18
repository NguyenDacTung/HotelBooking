import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../providers/session_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common.dart';
import '../shared/profile_screen.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && context.read<SessionProvider>().user != null) load();
    });
  }

  Future<void> load() => context.read<BookingProvider>().load(
    context.read<SessionProvider>().staff,
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.user == null) return const ProfileScreen();
    final state = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF123A52).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.staff ? 'Yêu cầu đặt phòng' : 'Đặt phòng của tôi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF123A52),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: state.status,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      prefixIcon: const Icon(Icons.filter_list_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...statuses.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: state.loading
                        ? null
                        : (v) {
                            state.status = v;
                            load();
                          },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF123A52),
                        side: const BorderSide(color: Color(0xFF123A52)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: state.loading
                          ? null
                          : () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (range != null && mounted) {
                                state.from = dateOnly(range.start);
                                state.to = dateOnly(range.end);
                                load();
                              }
                            },
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        state.from == null
                            ? 'Lọc ngày nhận'
                            : '${localDate(state.from!)} → ${localDate(state.to!)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (state.from != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          state.from = null;
                          state.to = null;
                          load();
                        },
                        child: const Text('Bỏ lọc ngày'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.loading)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFFB58A45),
                ),
              ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              ErrorPanel(state.error!, load),
            ],
            if (!state.loading && state.error == null && state.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Chưa có đặt phòng nào phù hợp.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ...state.items.map(
              (b) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    'Phòng ${b.number} • ${statuses[b.status]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152536),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${localDate(b.data['ngay_nhan'] as String)} → ${localDate(b.data['ngay_tra'] as String)}\n${money(b.total)}',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5C6875),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BookingDetailScreen(id: b.id),
                      ),
                    );
                    if (mounted) load();
                  },
                ),
              ),
            ),
            if (state.items.length < state.total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: state.loading
                      ? null
                      : () => state.load(session.staff, more: true),
                  child: const Text('Tải thêm'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

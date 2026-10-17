import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AdminProvider>().load();
    });
  }

  Color _kpiColor(String key) {
    switch (key) {
      case 'thu_rong':
        return const Color(0xFF237A57);
      case 'gia_tri_dat':
        return const Color(0xFF123A52);
      case 'con_phai_thu':
        return const Color(0xFFB58A45);
      case 'can_hoan_tien':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF123A52);
    }
  }

  IconData _kpiIcon(String key) {
    switch (key) {
      case 'thu_rong':
        return Icons.trending_up_rounded;
      case 'gia_tri_dat':
        return Icons.account_balance_wallet_outlined;
      case 'con_phai_thu':
        return Icons.payments_outlined;
      case 'can_hoan_tien':
        return Icons.assignment_return_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    final k = a.report?['kpi'];
    return RefreshIndicator(
      color: const Color(0xFF123A52),
      onRefresh: a.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D2B3E),
                  Color(0xFF123A52),
                  Color(0xFF1B4D6B),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF123A52).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng quan TTTP',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${localDate(dateOnly(a.start))} → ${localDate(dateOnly(a.end))}',
                          style: const TextStyle(
                            color: Color(0xFFB58A45),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB58A45).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFFB58A45),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (a.loading)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: Color(0xFFB58A45),
              ),
            ),
          if (a.error != null) ...[
            const SizedBox(height: 8),
            ErrorPanel(a.error!, a.load),
          ],
          if (k != null) ...[
            for (final entry in {
              'thu_rong': 'Thực thu ròng trong kỳ',
              'gia_tri_dat': 'Giá trị đặt đã xác nhận',
              'con_phai_thu': 'Còn phải thu',
              'can_hoan_tien': 'Cần hoàn tiền',
            }.entries)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _kpiColor(entry.key).withValues(alpha: 0.25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kpiColor(entry.key).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _kpiIcon(entry.key),
                          color: _kpiColor(entry.key),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: Color(0xFF5C6875),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              money(k[entry.key] as num),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _kpiColor(entry.key),
                                    fontSize: 21,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB58A45).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFFB58A45),
                  ),
                ),
                title: const Text(
                  'Đặt phòng tạo trong kỳ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152536),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF123A52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${k['so_dat_phong']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF5C6875),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.report!['dinh_nghia'] as String,
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
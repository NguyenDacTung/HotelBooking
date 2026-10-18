import 'pdf_preview_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../services/export_service.dart';
import '../../models/models.dart';
import '../../core/config.dart';
import '../../app/app_theme.dart';
import '../../widgets/common.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});
  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  bool exporting = false;
  int page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AdminProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    final rows = (a.report?['series'] as List? ?? []).cast<Json>();
    final k = a.report?['kpi'];
    return RefreshIndicator(
      color: const Color(0xFF123A52),
      onRefresh: a.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
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
                  'Báo cáo thực thu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF123A52),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thu và hoàn tiền theo giao dịch đã ghi nhận. Không tính giao dịch sandbox.',
                  style: TextStyle(color: Color(0xFF5C6875), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final days in [7, 30])
                      ActionChip(
                        backgroundColor: const Color(0xFFF5F7FA),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        labelStyle: const TextStyle(
                          color: Color(0xFF123A52),
                          fontWeight: FontWeight.w600,
                        ),
                        label: Text('$days ngày'),
                        onPressed: a.loading
                            ? null
                            : () {
                                a.end = DateTime.now();
                                a.start = a.end.subtract(
                                  Duration(days: days - 1),
                                );
                                page = 0;
                                a.load();
                              },
                      ),
                    ActionChip(
                      backgroundColor: const Color(0xFFF5F7FA),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      labelStyle: const TextStyle(
                        color: Color(0xFF123A52),
                        fontWeight: FontWeight.w600,
                      ),
                      label: const Text('Tháng này'),
                      onPressed: a.loading
                          ? null
                          : () {
                              a.end = DateTime.now();
                              a.start = DateTime(a.end.year, a.end.month);
                              page = 0;
                              a.load();
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                    onPressed: a.loading
                        ? null
                        : () async {
                            final r = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 366),
                              ),
                              initialDateRange: DateTimeRange(
                                start: a.start,
                                end: a.end,
                              ),
                            );
                            if (r != null) {
                              a.start = r.start;
                              a.end = r.end;
                              page = 0;
                              a.load();
                            }
                          },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${localDate(dateOnly(a.start))} → ${localDate(dateOnly(a.end))}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('Theo ngày')),
                      ButtonSegment(value: 'month', label: Text('Theo tháng')),
                    ],
                    selected: {a.mode},
                    onSelectionChanged: a.loading
                        ? null
                        : (v) {
                            a.mode = v.first;
                            page = 0;
                            a.load();
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in {
                  'thu': 'Thu',
                  'hoan': 'Hoàn',
                  'thu_rong': 'Thu ròng',
                  'gia_tri_dat': 'Giá trị đặt xác nhận',
                  'con_phai_thu': 'Còn phải thu',
                  'can_hoan_tien': 'Cần hoàn',
                }.entries)
                  Chip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF152536),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    label: Text('${e.value}: ${money(k[e.key] as num)}'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          for (final entry in [
                            ('thu', const Color(0xFF237A57)),
                            ('hoan', const Color(0xFFB42318)),
                            ('thu_rong', TttpTheme.primary),
                          ])
                            LineChartBarData(
                              color: entry.$2,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              spots: [
                                for (int i = 0; i < rows.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    (rows[i][entry.$1] as num).toDouble(),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Xanh lá: Thu · Đỏ: Hoàn · Xanh đậm: Thu ròng. Trục Y: VND; trục X: thứ tự kỳ trong bảng.',
                    style: TextStyle(color: Color(0xFF5C6875), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đặt phòng theo trạng thái',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF123A52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if ((a.report!['trang_thai'] as Json).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 38,
                          sections: [
                            for (final e
                                in (a.report!['trang_thai'] as Json).entries)
                              PieChartSectionData(
                                value: (e.value as num).toDouble(),
                                title: '${e.value}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                radius: 48,
                                color: switch (e.key) {
                                  'CHO_XAC_NHAN' => const Color(0xFFB58A45),
                                  'DA_XAC_NHAN' => const Color(0xFF237A57),
                                  'DA_HUY' => const Color(0xFF5C6875),
                                  _ => const Color(0xFFB42318),
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (a.report!['trang_thai'] as Json).entries
                        .map(
                          (e) => Chip(
                            backgroundColor: const Color(0xFFF5F7FA),
                            side: BorderSide.none,
                            label: Text(
                              '${statuses[e.key] ?? e.key}: ${e.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...rows
                .skip(page * 20)
                .take(20)
                .map(
                  (r) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Text(
                        '${r['ngay']} · ${r['so_dat_phong']} đặt phòng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF152536),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Thu ${money(r['thu'] as num)} · Hoàn ${money(r['hoan'] as num)}\nThu ròng ${money(r['thu_rong'] as num)}',
                          style: const TextStyle(
                            color: Color(0xFF5C6875),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: page > 0 ? () => setState(() => page--) : null,
                    child: const Text('Trang trước'),
                  ),
                  Text(
                    '${page + 1} / ${(rows.length / 20).ceil().clamp(1, 999)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF123A52),
                    ),
                  ),
                  TextButton(
                    onPressed: (page + 1) * 20 < rows.length
                        ? () => setState(() => page++)
                        : null,
                    child: const Text('Trang sau'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              a.report!['dinh_nghia'] as String,
              style: const TextStyle(
                color: Color(0xFF5C6875),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final format in ['csv', 'pdf'])
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF123A52),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF123A52)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: exporting || a.loading
                        ? null
                        : () async {
                            setState(() => exporting = true);
                            try {
                              final service = ExportService(
                                context.read<ApiService>(),
                              );
                              if (format == 'pdf') {
                                final file = await service.create(
                                  a.query,
                                  format,
                                );
                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PdfPreviewScreen(file: file),
                                    ),
                                  );
                                }
                              } else {
                                await service.share(a.query, format);
                              }
                            } catch (e) {
                              if (context.mounted) message(context, e);
                            } finally {
                              if (mounted) setState(() => exporting = false);
                            }
                          },
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(
                      'Xuất ${format.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

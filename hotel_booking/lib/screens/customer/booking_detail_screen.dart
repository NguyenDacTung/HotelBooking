import '../staff/booking_scanner_screen.dart';
import '../shared/reviews_screen.dart';
import '../staff/payments_screen.dart';
import '../../providers/notifications_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../models/models.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import '../../widgets/booking_operations.dart';

class BookingDetailScreen extends StatefulWidget {
  final String id;
  const BookingDetailScreen({super.key, required this.id});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Json? data;
  bool loading = true, busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await context.read<ApiService>().request(
        'GET',
        '/bookings/${widget.id}',
      ) as Json;
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> act(String action) async {
    String? reason;
    if (action == 'reject' || action == 'cancel') {
      final controller = TextEditingController();
      final key = GlobalKey<FormState>();
      reason = await formDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            action == 'reject' ? 'Lý do từ chối' : 'Xác nhận hủy phiếu',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF152536),
              fontSize: 18,
            ),
          ),
          content: Form(
            key: key,
            child: TextFormField(
              controller: controller,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123A52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (key.currentState!.validate()) {
                  Navigator.pop(c, controller.text.trim());
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (reason == null || !mounted) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final prefix = action == 'cancel' ? '' : '/staff';
      await context.read<ApiService>().request(
        'PATCH',
        '$prefix/bookings/${widget.id}/$action',
        body: action == 'confirm' ? null : {'ly_do': reason},
      );
      if (mounted) {
        message(context, 'Đã cập nhật đặt phòng');
        await load();
        if (mounted) await context.read<NotificationsProvider>().refresh();
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final d = data;
    final beforeArrival =
        d != null &&
        dateOnly(DateTime.now().toUtc().add(const Duration(hours: 7)))
                .compareTo(d['ngay_nhan'] as String) <
            1;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Chi tiết đặt phòng',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (loading)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFFB58A45),
                ),
              ),
            if (error != null) ...[
              const SizedBox(height: 8),
              ErrorPanel(error!, load),
            ],
            if (d != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF123A52).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                'Mã: ${d['ma_pdp']}',
                                style: const TextStyle(
                                  color: Color(0xFF5C6875),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phòng ${d['so_phong']}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF123A52),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          backgroundColor: const Color(0xFFB58A45)
                              .withValues(alpha: 0.14),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            color: Color(0xFFB58A45),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          label: Text(
                            statuses[d['trang_thai']] ?? '${d['trang_thai']}',
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Color(0xFF5C6875),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${localDate(d['ngay_nhan'] as String)} → ${localDate(d['ngay_tra'] as String)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF152536),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: Color(0xFF5C6875),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${d['so_khach']} khách • ${d['so_dem']} đêm',
                          style: const TextStyle(
                            color: Color(0xFF5C6875),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Đơn giá chốt mỗi đêm',
                                style: TextStyle(
                                  color: Color(0xFF5C6875),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                money(d['don_gia_moi_dem'] as num),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF152536),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng thanh toán',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF123A52),
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                money(
                                  (d['tong_thanh_toan'] ?? d['tong_tien'])
                                      as num,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF123A52),
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đã thu: ${money((d['da_thu'] ?? 0) as num)} • Đã hoàn: ${money((d['da_hoan'] ?? 0) as num)}',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Còn phải thu: ${money((d['con_phai_thu'] ?? 0) as num)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152536),
                        fontSize: 13.5,
                      ),
                    ),
                    if ((d['can_hoan_tien'] as num? ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chờ hoàn: ${money(d['can_hoan_tien'] as num)}',
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                    if (session.staff) ...[
                      const SizedBox(height: 14),
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
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PaymentsScreen(bookingId: widget.id),
                              ),
                            );
                            if (mounted) await load();
                          },
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text(
                            'Thu / hoàn tiền',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Color(0xFF5C6875),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Liên hệ: ${d['ten_lien_he']} • ${d['sdt_lien_he']}',
                            style: const TextStyle(
                              color: Color(0xFF5C6875),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (d['ly_do_tu_choi'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lý do từ chối: ${d['ly_do_tu_choi']}',
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!loading && error == null)
                BookingOperations(booking: d, reload: load),
              if (!session.staff)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BookingQrScreen(id: widget.id),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Mã đặt phòng'),
                ),
              if (!session.staff &&
                  session.user?['id'] == d['ma_kh'] &&
                  d['trang_thai'] == 'DA_HOAN_TAT')
                BookingReviewTile(bookingId: widget.id),
              if (beforeArrival &&
                  !session.staff &&
                  session.user?['id'] == d['ma_kh'] &&
                  ['CHO_XAC_NHAN', 'DA_XAC_NHAN'].contains(d['trang_thai']))
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                      side: BorderSide(
                        color: const Color(0xFFB42318).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: busy || loading ? null : () => act('cancel'),
                    child: const Text(
                      'Hủy đặt phòng',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (beforeArrival &&
                  session.staff &&
                  d['trang_thai'] == 'CHO_XAC_NHAN') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF237A57),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: busy || loading ? null : () => act('confirm'),
                    child: const Text(
                      'Xác nhận đặt phòng',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                      side: BorderSide(
                        color: const Color(0xFFB42318).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: busy || loading ? null : () => act('reject'),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Lịch sử thay đổi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF123A52),
                ),
              ),
              const SizedBox(height: 12),
              ...(d['lich_su'] as List? ?? []).map(
                (h) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A52).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Color(0xFF123A52),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      statuses[h['den_trang_thai']] ?? '${h['den_trang_thai']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152536),
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${vietnamTime(h['thoi_diem'] as String)} (giờ Việt Nam)${h['ly_do'] == null ? '' : '\n${h['ly_do']}'}',
                        style: const TextStyle(
                          color: Color(0xFF5C6875),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

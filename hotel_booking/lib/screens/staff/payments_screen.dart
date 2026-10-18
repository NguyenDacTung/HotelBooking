import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/session_provider.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';

class PaymentsScreen extends StatefulWidget {
  final String bookingId;
  const PaymentsScreen({super.key, required this.bookingId});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Json> items = [];
  Json? totals, booking;
  String? error;
  bool busy = true;
  int page = 1, total = 0;
  Json? pending;
  late final String pendingKey;
  Future<void> persistPending(Json? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(pendingKey);
    } else {
      await prefs.setString(pendingKey, jsonEncode(value));
    }
    if (mounted) setState(() => pending = value);
  }

  Future<void> retryPending() async {
    final value = pending;
    if (value == null) return;
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'POST',
        value['path'] as String,
        body: value['body'] as Json,
      );
      await persistPending(null);
    } catch (e) {
      if (e is ApiError &&
          e.status != null &&
          e.status! >= 400 &&
          e.status! < 500) {
        await persistPending(null);
      }
      if (mounted) message(context, e);
    } finally {
      if (mounted) await load();
    }
  }

  @override
  void initState() {
    super.initState();
    pendingKey =
        'tttp_payment_${context.read<SessionProvider>().user?['id']}_${widget.bookingId}';
    load();
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        totals = null;
        booking = null;
        items = [];
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final stored = prefs.getString(pendingKey);
      if (stored != null) pending = jsonDecode(stored) as Json;
      final next = more ? page + 1 : 1;
      final api = context.read<ApiService>();
      final values = await Future.wait([
        api.request(
          'GET',
          '/staff/bookings/${widget.bookingId}/payments',
          query: {'page': next},
        ),
        api.request('GET', '/bookings/${widget.bookingId}'),
      ]);
      if (mounted) {
        setState(() {
          totals = values[0] as Json;
          booking = values[1] as Json;
          final rows = (totals!['items'] as List).cast<Json>();
          items = more ? [...items, ...rows] : rows;
          total = totals!['total'] as int;
          page = next;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> record([Json? original]) async {
    if (pending != null) {
      await retryPending();
      return;
    }
    final requestId = const Uuid().v4();
    final amount = TextEditingController(),
        note = TextEditingController(),
        reference = TextEditingController();
    final key = GlobalKey<FormState>();
    String method = 'TIEN_MAT';
    bool confirmed = false, sending = false;
    String? localError;
    await formDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (original == null
                              ? const Color(0xFF237A57)
                              : const Color(0xFFB42318))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  original == null
                      ? Icons.payments_outlined
                      : Icons.reply_rounded,
                  color: original == null
                      ? const Color(0xFF237A57)
                      : const Color(0xFFB42318),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  original == null ? 'Ghi nhận thu tiền' : 'Ghi nhận hoàn tiền',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152536),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF5C6875),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chỉ ghi nhận sau khi tiền đã được xử lý thực tế bên ngoài ứng dụng.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5C6875),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amount,
                    enabled: !sending,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền (VND)',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                        ? null
                        : 'Nhập số nguyên lớn hơn 0',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: InputDecoration(
                      labelText: 'Phương thức',
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TIEN_MAT',
                        child: Text('Tiền mặt'),
                      ),
                      DropdownMenuItem(
                        value: 'CHUYEN_KHOAN',
                        child: Text('Chuyển khoản'),
                      ),
                    ],
                    onChanged: sending ? null : (v) => method = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reference,
                    enabled: !sending,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Mã tham chiếu (tùy chọn)',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: note,
                    enabled: !sending,
                    maxLength: 2000,

                    decoration: InputDecoration(
                      labelText: original == null
                          ? 'Ghi chú'
                          : 'Ghi chú hoàn tiền (tùy chọn)',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF123A52),
                    title: Text(
                      original == null
                          ? 'Tôi đã nhận tiền thực tế'
                          : 'Tôi đã hoàn tiền thực tế',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152536),
                      ),
                    ),
                    value: confirmed,
                    onChanged: sending
                        ? null
                        : (v) => set(() => confirmed = v ?? false),
                  ),
                  if (localError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB42318).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        localError!,
                        style: TextStyle(
                          color: Theme.of(c).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(c),
              child: const Text('Đóng'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123A52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: sending || !confirmed
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      set(() => sending = true);
                      try {
                        final path = original == null
                            ? '/staff/bookings/${widget.bookingId}/payments'
                            : '/admin/payments/${original['id']}/refunds';
                        final body = <String, dynamic>{
                          'request_id': requestId,
                          'so_tien': int.parse(amount.text),
                          'phuong_thuc': method,
                          'ghi_chu': note.text.trim().isEmpty
                              ? null
                              : note.text.trim(),
                          'ma_tham_chieu': reference.text.trim().isEmpty
                              ? null
                              : reference.text.trim(),
                        };
                        await persistPending({'path': path, 'body': body});
                        if (!mounted) return;
                        await context.read<ApiService>().request(
                          'POST',
                          path,
                          body: body,
                        );
                        await persistPending(null);
                        if (c.mounted) Navigator.pop(c);
                      } catch (e) {
                        if (e is ApiError &&
                            e.status != null &&
                            e.status! >= 400 &&
                            e.status! < 500) {
                          await persistPending(null);
                        }
                        if (c.mounted) {
                          if (pending != null) {
                            Navigator.pop(c);
                            if (mounted) {
                              message(
                                context,
                                'Chưa xác định kết quả giao dịch. Dùng nút kiểm tra / thử lại để tránh ghi nhận trùng.',
                              );
                            }
                          } else {
                            set(() => localError = '$e');
                          }
                        }
                      } finally {
                        if (c.mounted) set(() => sending = false);
                      }
                    },
              child: Text(sending ? 'Đang ghi nhận…' : 'Xác nhận ghi nhận'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    note.dispose();
    reference.dispose();
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Sổ thu / hoàn tiền',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Có giao dịch chưa xác định kết quả. Không thu hoặc hoàn tiền lần nữa.',
                      ),
                      FilledButton(
                        onPressed: busy ? null : retryPending,
                        child: const Text('Kiểm tra / thử lại giao dịch cũ'),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF123A52).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF123A52).withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF123A52),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ghi nhận thu/hoàn thực tế. Giao dịch sandbox không tính vào số tiền đã thanh toán.',
                      style: TextStyle(
                        color: Color(0xFF123A52),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (busy)
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
            if (totals != null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF123A52).withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (final e in {
                      'da_thu': 'Đã thu',
                      'da_hoan': 'Đã hoàn',
                      'thu_rong': 'Thu ròng',
                      'con_phai_thu': 'Còn phải thu',
                      'can_hoan_tien': 'Cần hoàn tiền',
                    }.entries)
                      ListTile(
                        dense: true,
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: e.key == 'da_thu' || e.key == 'thu_rong'
                                ? const Color(0xFF237A57)
                                : e.key == 'da_hoan' || e.key == 'can_hoan_tien'
                                ? const Color(0xFFB42318)
                                : const Color(0xFFB58A45),
                          ),
                        ),
                        title: Text(
                          e.value,
                          style: const TextStyle(
                            color: Color(0xFF5C6875),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          money(totals![e.key] as num),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: e.key == 'thu_rong'
                                ? const Color(0xFF123A52)
                                : const Color(0xFF152536),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (error == null &&
                  !busy &&
                  [
                    'DA_XAC_NHAN',
                    'DANG_O',
                    'CHO_THANH_TOAN',
                    'DA_HUY',
                    'KHONG_DEN',
                  ].contains(booking?['trang_thai']) &&
                  (totals!['con_phai_thu'] as num) > 0)
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF123A52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: busy || pending != null ? null : () => record(),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text(
                      'Ghi nhận thu tiền',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            ...items.map((p) {
              final isThu = p['loai'] == 'THU';
              final sandbox = p['environment'] == 'sandbox';
              final statusColor = isThu
                  ? const Color(0xFF237A57)
                  : const Color(0xFFB42318);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isThu
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: statusColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${sandbox ? '[SANDBOX] ' : ''}${isThu ? 'Thu' : 'Hoàn'} · ${money(p['so_tien'] as num)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: statusColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: Color(0xFF5C6875),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vietnamTime(p['thoi_diem_giao_dich'] as String),
                            style: const TextStyle(
                              color: Color(0xFF5C6875),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 15,
                            color: Color(0xFF5C6875),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ({
                                  'TIEN_MAT': 'Tiền mặt',
                                  'CHUYEN_KHOAN': 'Chuyển khoản',
                                  'MOMO': 'MoMo',
                                  'VNPAY': 'VNPAY',
                                }[p['phuong_thuc']] ??
                                '${p['phuong_thuc']}'),
                            style: const TextStyle(
                              color: Color(0xFF152536),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (p['ghi_chu'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p['ghi_chu'] as String,
                            style: const TextStyle(
                              color: Color(0xFF152536),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      if (session.manager && isThu && !sandbox) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB42318),
                              side: BorderSide(
                                color: const Color(0xFFB42318)
                                    .withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: busy || pending != null
                                ? null
                                : () => record(p),
                            child: const Text(
                              'Ghi nhận hoàn cho khoản thu này',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            if (items.length < total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: busy ? null : () => load(more: true),
                  child: const Text('Tải thêm giao dịch'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

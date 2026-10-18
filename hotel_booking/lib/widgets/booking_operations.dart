import '../screens/customer/online_payment_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../core/config.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import 'common.dart';

class BookingOperations extends StatefulWidget {
  final Json booking;
  final Future<void> Function() reload;
  const BookingOperations({
    super.key,
    required this.booking,
    required this.reload,
  });
  @override
  State<BookingOperations> createState() => _BookingOperationsState();
}

class _BookingOperationsState extends State<BookingOperations> {
  bool busy = false;
  Json get d => widget.booking;
  String get id => d['ma_pdp'] as String;

  Future<void> send(String method, String path, [Json? body]) async {
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(method, path, body: body);
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) {
        await widget.reload();
        if (mounted) setState(() => busy = false);
      }
    }
  }

  Future<String?> reason(String title) async {
    final text = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await formDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Form(
          key: key,
          child: TextFormField(
            controller: text,
            decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
            maxLength: 2000,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(c, text.text.trim());
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    text.dispose();
    return result;
  }

  Future<void> act(String action, String label) async {
    if (action == 'check-in' || action == 'check-out') {
      await send('POST', '/staff/bookings/$id/$action', {});
      return;
    }
    final text = await reason(label);
    if (text == null || !mounted) return;
    await send(
      action == 'cancel' ? 'PATCH' : 'POST',
      '/staff/bookings/$id/$action',
      {'ly_do': text},
    );
  }

  Future<void> charge() async {
    final name = TextEditingController(),
        price = TextEditingController(),
        qty = TextEditingController(text: '1');
    final key = GlobalKey<FormState>();
    String kind = 'MINIBAR';
    final request = const Uuid().v4();
    final ok = await formDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Thêm phụ thu'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    decoration: const InputDecoration(
                      labelText: 'Khoản phát sinh',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'MINIBAR',
                        child: Text('Minibar'),
                      ),
                      DropdownMenuItem(
                        value: 'GIAT_LA',
                        child: Text('Giặt là'),
                      ),
                      DropdownMenuItem(
                        value: 'GIUONG_PHU',
                        child: Text('Giường phụ'),
                      ),
                      DropdownMenuItem(
                        value: 'HU_HONG',
                        child: Text('Hư hỏng'),
                      ),
                      DropdownMenuItem(value: 'KHAC', child: Text('Khác')),
                    ],
                    onChanged: (v) {
                      set(() => kind = v!);
                      if (v == 'GIUONG_PHU') {
                        price.text =
                            '${((d['chinh_sach'] as Map?)?['extra_bed_price'] as num? ?? 250000) * (d['so_dem'] as num)}';
                        name.text = 'Giường phụ ${d['so_dem']} đêm';
                      }
                    },
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung / căn cứ',
                    ),
                    validator: requiredText,
                    maxLength: 500,
                  ),
                  TextFormField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá (VND)',
                    ),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                        ? null
                        : 'Nhập số tiền > 0',
                  ),
                  TextFormField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                        ? null
                        : 'Nhập số lượng > 0',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Ghi nhận'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      await send('POST', '/staff/bookings/$id/charges', {
        'loai': kind,
        'noi_dung': name.text,
        'don_gia': int.parse(price.text),
        'so_luong': int.parse(qty.text),
        'request_id': request,
      });
    }
    name.dispose();
    price.dispose();
    qty.dispose();
  }

  Future<void> amend() async {
    try {
      final api = context.read<ApiService>();
      final rows = <Json>[];
      int page = 1, total = 1;
      while (rows.length < total) {
        final data = await api.request(
          'GET',
          '/staff/rooms/status',
          query: {'page': page++, 'page_size': 100},
        ) as Json;
        rows.addAll((data['items'] as List).cast<Json>());
        total = data['total'] as int;
      }
      if (!mounted) return;
      int room = d['ma_phong'] as int;
      DateTime start = DateTime.parse(d['ngay_nhan'] as String),
          end = DateTime.parse(d['ngay_tra'] as String);
      final why = TextEditingController(),
          guests = TextEditingController(text: '${d['so_khach']}');
      final key = GlobalKey<FormState>();
      final ok = await formDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, set) => AlertDialog(
            title: const Text('Đổi phòng / ngày'),
            content: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: room,
                      decoration: const InputDecoration(labelText: 'Phòng'),
                      isExpanded: true,
                      items: rows
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['ma_phong'] as int,
                              child: Text(
                                'Phòng ${r['so_phong']} · ${money(r['gia_co_ban'] as num)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => set(() => room = v!),
                    ),
                    TextButton(
                      onPressed: () async {
                        final today = DateUtils.dateOnly(DateTime.now());
                        final range = await showDateRangePicker(
                          context: c,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 730)),
                          initialDateRange: start.isBefore(today)
                              ? null
                              : DateTimeRange(start: start, end: end),
                        );
                        if (range != null) {
                          set(() {
                            start = range.start;
                            end = range.end;
                          });
                        }
                      },
                      child: Text(
                        '${localDate(dateOnly(start))} → ${localDate(dateOnly(end))}',
                      ),
                    ),
                    Text(
                      'Tiền phòng mới: ${money((rows.firstWhere((r) => r['ma_phong'] == room)['gia_co_ban'] as num) * end.difference(start).inDays)}',
                    ),
                    TextFormField(
                      controller: guests,
                      validator: (v) =>
                          int.tryParse(v ?? '') != null && int.parse(v!) > 0
                          ? null
                          : 'Số khách phải là số nguyên dương',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số khách'),
                    ),
                    TextFormField(
                      controller: why,
                      decoration: const InputDecoration(
                        labelText: 'Lý do đổi (tùy chọn)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  if (key.currentState!.validate()) Navigator.pop(c, true);
                },
                child: const Text('Xác nhận giá và lịch mới'),
              ),
            ],
          ),
        ),
      );
      if (ok == true && mounted) {
        await send('PATCH', '/staff/bookings/$id/amend', {
          'ma_phong': room,
          'ngay_nhan': dateOnly(start),
          'ngay_tra': dateOnly(end),
          'so_khach': int.tryParse(guests.text) ?? 0,
          'ly_do': why.text,
          'expected_don_gia_moi_dem': rows.firstWhere(
            (r) => r['ma_phong'] == room,
          )['gia_co_ban'],
        });
      }
      why.dispose();
      guests.dispose();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final state = d['trang_thai'];
    final staff = session.staff;
    final today = dateOnly(
      DateTime.now().toUtc().add(const Duration(hours: 7)),
    );
    final arrival = d['ngay_nhan'] as String?;
    final charges = (d['phu_thu'] as List? ?? []).cast<Json>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hóa đơn lưu trú',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Tiền phòng: ${money((d['tien_phong'] ?? d['tong_tien']) as num)}',
            ),
            for (final c in charges)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${c['noi_dung']}${c['da_huy'] == true ? ' · Đã hủy' : ''}',
                ),
                subtitle: Text(
                  '${c['so_luong']} × ${money(c['don_gia'] as num)}',
                ),
                trailing:
                    session.manager &&
                        c['da_huy'] != true &&
                        state != 'DA_HOAN_TAT'
                    ? IconButton(
                        tooltip: 'Hủy phụ thu',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: busy
                            ? null
                            : () async {
                                final why = await reason('Hủy khoản phụ thu');
                                if (why != null && mounted) {
                                  await send(
                                    'POST',
                                    '/admin/charges/${c['id']}/void',
                                    {'ly_do': why},
                                  );
                                }
                              },
                      )
                    : null,
              ),
            Text(
              'Tổng thanh toán: ${money((d['tong_thanh_toan'] ?? d['tong_tien']) as num)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (d['giu_cho_den'] != null && state == 'CHO_XAC_NHAN')
              Text('Giữ chỗ đến ${vietnamTime(d['giu_cho_den'] as String)}'),
            if (staff && ['CHO_XAC_NHAN', 'DA_XAC_NHAN'].contains(state)) ...[
              OutlinedButton(
                onPressed: busy ? null : amend,
                child: const Text('Đổi phòng / ngày'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => act('cancel', 'Hủy hộ khách'),
                child: const Text('Hủy hộ khách'),
              ),
            ],
            if (staff && state == 'DA_XAC_NHAN') ...[
              FilledButton(
                onPressed: busy || arrival != today
                    ? null
                    : () => act('check-in', 'Nhận phòng'),
                child: const Text('Nhận phòng'),
              ),
              if (arrival != null && arrival.compareTo(today) < 0)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => act('no-show', 'Khách không đến'),
                  child: const Text('Khách không đến'),
                ),
            ],
            if (['DANG_O', 'CHO_THANH_TOAN'].contains(state)) ...[
              if (staff)
                OutlinedButton(
                  onPressed: busy ? null : charge,
                  child: const Text('Thêm phụ thu'),
                ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => send('POST', '/bookings/$id/request-checkout'),
                child: Text(
                  state == 'DANG_O'
                      ? 'Yêu cầu trả phòng'
                      : 'Cập nhật hóa đơn trả phòng',
                ),
              ),

              if (staff && state == 'CHO_THANH_TOAN')
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => act('check-out', 'Hoàn tất trả phòng'),
                  child: const Text('Hoàn tất trả phòng'),
                ),
            ],
            if (!staff &&
                ['DA_XAC_NHAN', 'DANG_O', 'CHO_THANH_TOAN'].contains(state) &&
                ((d['con_phai_thu'] ?? 0) as num) > 0)
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => OnlinePaymentScreen(bookingId: id),
                          ),
                        );
                        if (mounted) widget.reload();
                      },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Thanh toán online'),
              ),
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

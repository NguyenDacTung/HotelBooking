import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../core/config.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import '../customer/booking_detail_screen.dart';

class FrontDeskScreen extends StatefulWidget {
  const FrontDeskScreen({super.key});
  @override
  State<FrontDeskScreen> createState() => _FrontDeskScreenState();
}

class _FrontDeskScreenState extends State<FrontDeskScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      name = TextEditingController(),
      phone = TextEditingController(),
      guests = TextEditingController(text: '1');
  DateTimeRange? dates;
  List<Json> rooms = [];
  int? room;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [email, name, phone, guests]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> find() async {
    if (dates == null) {
      message(context, 'Chọn ngày lưu trú');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      rooms = [];
      room = null;
    });
    try {
      final result = await context.read<ApiService>().request(
        'GET',
        '/rooms/available',
        query: {
          'ngay_nhan': dateOnly(dates!.start),
          'ngay_tra': dateOnly(dates!.end),
          'so_khach': int.tryParse(guests.text) ?? 1,
          'page_size': 100,
        },
      ) as Json;
      if (mounted) {
        setState(() => rooms = (result['items'] as List).cast<Json>());
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || room == null || dates == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final b = await context.read<ApiService>().request(
        'POST',
        '/staff/bookings',
        body: {
          'email_khach': email.text.trim(),
          'ten_lien_he': name.text.trim(),
          'sdt_lien_he': phone.text.trim(),
          'ma_phong': room,
          'ngay_nhan': dateOnly(dates!.start),
          'ngay_tra': dateOnly(dates!.end),
          'so_khach': int.parse(guests.text),
          'expected_don_gia_moi_dem': rooms.firstWhere(
            (r) => r['ma_phong'] == room,
          )['gia_co_ban'],
        },
      ) as Json;
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BookingDetailScreen(id: b['ma_pdp'] as String),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt phòng hộ khách')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email khách hàng'),
              validator: requiredText,
            ),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên liên hệ'),
              validator: requiredText,
            ),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Điện thoại liên hệ',
              ),
              validator: phoneText,
            ),
            TextFormField(
              controller: guests,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số khách'),
              onChanged: (_) => setState(() {
                rooms = [];
                room = null;
              }),
              validator: (v) =>
                  (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nhập số khách > 0',
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      final today = DateUtils.dateOnly(DateTime.now());
                      final value = await showDateRangePicker(
                        context: context,
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 730)),
                      );
                      if (value != null) {
                        setState(() {
                          dates = value;
                          rooms = [];
                          room = null;
                        });
                      }
                    },
              child: Text(
                dates == null
                    ? 'Chọn ngày lưu trú'
                    : '${localDate(dateOnly(dates!.start))} → ${localDate(dateOnly(dates!.end))}',
              ),
            ),
            OutlinedButton(
              onPressed: busy ? null : find,
              child: const Text('Tìm phòng còn trống'),
            ),
            if (rooms.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey(rooms),
                initialValue: room,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chọn phòng'),
                items: rooms
                    .map(
                      (r) => DropdownMenuItem(
                        value: r['ma_phong'] as int,
                        child: Text(
                          '${r['so_phong']} · ${r['ten_loai']} · ${money(r['gia_co_ban'] as num)}/đêm',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => room = v),
              ),
            if (room != null)
              Text(
                'Tiền phòng: ${money((rooms.firstWhere((r) => r['ma_phong'] == room)['gia_co_ban'] as num) * dates!.duration.inDays)}',
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: busy || room == null ? null : save,
              child: const Text('Tạo yêu cầu đặt phòng'),
            ),
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
  );
}

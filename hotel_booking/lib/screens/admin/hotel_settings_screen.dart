import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class HotelSettingsScreen extends StatefulWidget {
  const HotelSettingsScreen({super.key});
  @override
  State<HotelSettingsScreen> createState() => _HotelSettingsState();
}

class _HotelSettingsState extends State<HotelSettingsScreen> {
  final fields = {
    for (final k in [
      'video_url',
      'video_caption',
      'hotel_phone',
      'hotel_email',
      'website',
    ])
      k: TextEditingController(),
  };
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/hotel/info',
      ) as Json;
      if (!mounted) return;
      for (final k in fields.keys) {
        fields[k]!.text = d[k] ?? '';
      }
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'PUT',
        '/admin/hotel/info',
        body: {for (final e in fields.entries) e.key: e.value.text.trim()},
      );
      if (mounted) message(context, 'Đã lưu thông tin công khai');
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cấu hình khách sạn')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Thông tin này khách vãng lai cũng xem được. Chỉ điền thông tin thật. Để trống nếu chưa có. Khóa thanh toán, SMTP, Firebase được cấu hình ở máy chủ.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ErrorPanel(error!, load),
        for (final e in {
          'video_url': 'URL video HTTPS trực tiếp',
          'video_caption': 'Chú thích video',
          'hotel_phone': 'Điện thoại liên hệ',
          'hotel_email': 'Email liên hệ',
          'website': 'Website HTTPS',
        }.entries)
          TextField(
            controller: fields[e.key],
            enabled: !busy,
            decoration: InputDecoration(labelText: e.value),
          ),
        FilledButton(onPressed: busy ? null : save, child: const Text('Lưu')),
      ],
    ),
  );
}

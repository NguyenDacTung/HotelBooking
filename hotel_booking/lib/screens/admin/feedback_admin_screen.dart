import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class FeedbackAdminScreen extends StatefulWidget {
  const FeedbackAdminScreen({super.key});
  @override
  State<FeedbackAdminScreen> createState() => _FeedbackAdminState();
}

class _FeedbackAdminState extends State<FeedbackAdminScreen> {
  Json? data;
  String? error;
  int page = 1;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/admin/feedback',
        query: {'page': page, 'page_size': 20},
      ) as Json;
      if (mounted) {
        setState(() {
          data = d;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> update(Json r, String state) async {
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'PATCH',
        '/admin/feedback/${r['id']}',
        body: {'trang_thai': state},
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> image(Json r) async {
    try {
      final raw = await context.read<ApiService>().download(
        '/feedback/${r['id']}/attachment',
        {},
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(Uint8List.fromList(raw)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Đóng ảnh riêng tư'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phản hồi khách hàng')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (error != null) ErrorPanel(error!, load),
          if (data == null && error == null) const LinearProgressIndicator(),
          if (data != null) ...[
            if ((data!['items'] as List).isEmpty)
              const Text('Chưa có phản hồi'),
            for (final raw in data!['items'] as List)
              Builder(
                builder: (c) {
                  final r = raw as Json;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['noi_dung']),
                          Text('${r['ngay_tao']}'),
                          Text('${r['thiet_bi']}'),
                          if (r['anh'] != null)
                            TextButton(
                              onPressed: () => image(r),
                              child: const Text('Xem ảnh đính kèm riêng tư'),
                            ),
                          DropdownButton<String>(
                            value: r['trang_thai'],
                            items: const [
                              DropdownMenuItem(
                                value: 'TIEP_NHAN',
                                child: Text('Tiếp nhận'),
                              ),
                              DropdownMenuItem(
                                value: 'DANG_XU_LY',
                                child: Text('Đang xử lý'),
                              ),
                              DropdownMenuItem(
                                value: 'DA_XU_LY',
                                child: Text('Đã xử lý'),
                              ),
                            ],
                            onChanged: busy ? null : (v) => update(r, v!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: page > 1
                      ? () {
                          page--;
                          load();
                        }
                      : null,
                  child: const Text('Trước'),
                ),
                Text('Trang $page'),
                TextButton(
                  onPressed: page * 20 < (data!['total'] as int)
                      ? () {
                          page++;
                          load();
                        }
                      : null,
                  child: const Text('Sau'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

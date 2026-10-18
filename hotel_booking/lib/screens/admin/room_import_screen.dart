import '../../services/app_feedback.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class RoomImportScreen extends StatefulWidget {
  const RoomImportScreen({super.key});
  @override
  State<RoomImportScreen> createState() => _ImportState();
}

class _ImportState extends State<RoomImportScreen> {
  Json? preview;
  bool busy = false;
  String? error;
  Future<void> choose() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      if (file.size > 2 * 1024 * 1024) {
        message(context, 'CSV tối đa 2 MiB');
        return;
      }
      setState(() {
        busy = true;
        error = null;
        preview = null;
      });
      final d = await context.read<ApiService>().upload(
        '/admin/room-import/preview',
        file.bytes!,
        file.name,
      ) as Json;
      if (mounted) setState(() => preview = d);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirm() async {
    setState(() => busy = true);
    try {
      final api = context.read<ApiService>();
      final r = await AppFeedback.blocking(
        'Đang nhập phòng…',
        () =>
            api.request('POST', '/admin/room-import/${preview!['id']}/confirm'),
      ) as Json;
      if (mounted) {
        message(context, 'Đã nhập ${r['imported']} phòng');
        setState(() => preview = null);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nhập phòng từ CSV')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SelectableText(
          'CSV UTF-8, tối đa 1.000 dòng / 2 MiB. Dòng đầu: so_phong,ma_lp,tang,ghi_chu\nMã loại phòng lấy từ danh mục hiện có. Mỗi dòng là phòng mới; không cập nhật hoặc ghi đè phòng cũ. Không nhập cột giá hoặc ảnh.',
        ),
        FilledButton.icon(
          onPressed: busy ? null : choose,
          icon: const Icon(Icons.upload_file),
          label: const Text('Chọn CSV và xem trước'),
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ErrorPanel(error!, choose),
        if (preview != null) ...[
          Text(
            '${(preview!['rows'] as List).length} dòng • ${(preview!['errors'] as List).length} lỗi',
          ),
          for (final e in preview!['errors'] as List)
            Text(
              'Dòng ${e['line']}: ${e['message']}',
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Số phòng')),
                DataColumn(label: Text('Mã loại')),
                DataColumn(label: Text('Tầng')),
                DataColumn(label: Text('Ghi chú')),
              ],
              rows: [
                for (final r in (preview!['rows'] as List).take(100))
                  DataRow(
                    cells: [
                      for (final key in [
                        'so_phong',
                        'ma_lp',
                        'tang',
                        'ghi_chu',
                      ])
                        DataCell(Text('${r[key] ?? ''}')),
                    ],
                  ),
              ],
            ),
          ),
          if ((preview!['rows'] as List).length > 100)
            const Text(
              'Bảng hiển thị 100 dòng đầu; kiểm tra lỗi áp dụng cho toàn bộ file.',
            ),
          FilledButton(
            onPressed: busy || preview!['can_import'] != true ? null : confirm,
            child: const Text('Xác nhận nhập toàn bộ'),
          ),
        ],
      ],
    ),
  );
}

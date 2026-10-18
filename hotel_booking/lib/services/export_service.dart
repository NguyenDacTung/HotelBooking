import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'api_service.dart';

class ExportService {
  final ApiService api;
  ExportService(this.api);
  Future<File> create(Json filters, String format) async {
    final bytes = await api.download('/admin/reports/revenue/export', {
      ...filters,
      'format': format,
    });
    final directory = await getTemporaryDirectory();
    final privateDirectory = Directory('${directory.path}/tetra-exports');
    await privateDirectory.create(recursive: true);
    final file = File(
      '${privateDirectory.path}/TETRA-thuc-thu-${filters['tu_ngay']}-${filters['den_ngay']}.$format',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> clear() async {
    final d = await getTemporaryDirectory();
    final folder = Directory('${d.path}/tetra-exports');
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  Future<void> share(Json filters, String format) async {
    final file = await create(filters, format);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: format == 'pdf' ? 'application/pdf' : 'text/csv',
          ),
        ],
        subject: 'TETRA · Báo cáo thực thu',
      ),
    );
  }
}

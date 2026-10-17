import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'api_service.dart';

class ExportService {
  final ApiService api;
  ExportService(this.api);
  Future<void> share(Json filters, String format) async {
    final bytes = await api.download('/admin/reports/revenue/export', {
      ...filters,
      'format': format,
    });
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/TTTP-thuc-thu-${filters['tu_ngay']}-${filters['den_ngay']}.$format',
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: format == 'pdf' ? 'application/pdf' : 'text/csv',
          ),
        ],
        subject: 'TTTP · Báo cáo thực thu',
      ),
    );
  }
}

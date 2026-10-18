import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/common.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File file;
  const PdfPreviewScreen({super.key, required this.file});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Xem trước báo cáo PDF'),
      actions: [
        IconButton(
          tooltip: 'Lưu hoặc chia sẻ',
          icon: const Icon(Icons.ios_share),
          onPressed: () async {
            try {
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(file.path, mimeType: 'application/pdf')],
                  subject: 'TETRA • Báo cáo',
                ),
              );
            } catch (e) {
              if (context.mounted) message(context, e);
            }
          },
        ),
      ],
    ),
    body: PdfViewer.file(file.path),
  );
}

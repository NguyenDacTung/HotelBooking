import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image_picker/image_picker.dart';

import 'common.dart';

Future<Uint8List?> chooseCroppedImage(
  BuildContext context, {
  bool avatar = false,
}) async {
  // Recover Android picker data only after an explicit new image action.
  // Every recovered image still requires crop + preview confirmation for this target.
  final recovered = await ImagePicker().retrieveLostData();
  if (!context.mounted) return null;
  if (recovered.files?.isNotEmpty == true) {
    final old = recovered.files!.first;
    final reuse = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ảnh chưa lưu từ lần trước'),
        content: const Text(
          'Bạn muốn xem và căn lại ảnh vừa khôi phục trước khi dùng ở đây?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Chọn ảnh khác'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xem ảnh khôi phục'),
          ),
        ],
      ),
    );
    if (!context.mounted) return null;
    if (reuse == true) {
      if (await old.length() > 5 * 1024 * 1024) {
        if (context.mounted) message(context, 'Ảnh tối đa 5 MiB');
        return null;
      }
      final bytes = await old.readAsBytes();
      if (!context.mounted) return null;
      return Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(bytes, avatar: avatar),
        ),
      );
    }
  }
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (c) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Thư viện ảnh'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Chụp ảnh'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2400,
    maxHeight: 2400,
    imageQuality: 90,
  );
  if (file == null || !context.mounted) return null;
  if (await file.length() > 5 * 1024 * 1024) {
    if (context.mounted) message(context, 'Ảnh tối đa 5 MiB');
    return null;
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(builder: (_) => ImageCropScreen(bytes, avatar: avatar)),
  );
}

class ImageCropScreen extends StatefulWidget {
  final Uint8List bytes;
  final bool avatar;
  const ImageCropScreen(this.bytes, {super.key, this.avatar = false});
  @override
  State<ImageCropScreen> createState() => _CropState();
}

class _CropState extends State<ImageCropScreen> {
  final controller = CropController();
  bool busy = false, ready = false;
  Uint8List? preview;
  int revision = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        preview == null
            ? (widget.avatar ? 'Căn ảnh đại diện' : 'Căn ảnh phòng')
            : 'Xác nhận ảnh',
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                preview == null
                    ? Icons.pinch_outlined
                    : Icons.check_circle_outline,
                color: const Color(0xFF123A52),
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                preview != null
                    ? 'Ảnh sẽ hiển thị như bên dưới. Bấm Dùng ảnh này để lưu.'
                    : widget.avatar
                    ? 'Kéo ảnh để đưa khuôn mặt vào giữa vòng tròn. Chụm hoặc mở hai ngón để thu/phóng ảnh.'
                    : 'Kéo ảnh và dùng hai ngón để thu/phóng. Kéo các góc để đổi vùng ảnh.',
                textAlign: TextAlign.center,
              ),
              if (preview == null)
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          revision++;
                          ready = false;
                        }),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Đặt lại vị trí ảnh'),
                ),
            ],
          ),
        ),
        Expanded(
          child: preview != null
              ? Center(
                  child: widget.avatar
                      ? ClipOval(
                          child: Image.memory(
                            preview!,
                            width: 240,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.memory(preview!, fit: BoxFit.contain),
                )
              : Crop(
                  key: ValueKey(revision),
                  image: widget.bytes,
                  controller: controller,
                  interactive: true,
                  fixCropRect: widget.avatar,
                  cornerDotBuilder: widget.avatar
                      ? (_, _) => const SizedBox.shrink()
                      : null,
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: .78,
                    aspectRatio: widget.avatar ? 1 : null,
                  ),
                  aspectRatio: widget.avatar ? 1 : null,
                  withCircleUi: widget.avatar,
                  onStatusChanged: (s) {
                    if (mounted) setState(() => ready = s == CropStatus.ready);
                  },
                  onCropped: (result) {
                    if (!mounted) return;
                    setState(() => busy = false);
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        setState(() => preview = croppedImage);
                      case CropFailure():
                        message(
                          context,
                          'Không xử lý được ảnh, hãy chọn ảnh khác',
                        );
                    }
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (preview != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        preview = null;
                        ready = false;
                        revision++;
                      });
                    },
                    child: const Text('Căn lại'),
                  ),
                Expanded(
                  child: FilledButton(
                    onPressed: busy || (preview == null && !ready)
                        ? null
                        : () {
                            if (preview != null) {
                              Navigator.pop(context, preview);
                              return;
                            }
                            setState(() => busy = true);
                            controller.crop();
                          },
                    child: Text(
                      busy
                          ? 'Đang xử lý…'
                          : preview == null
                          ? 'Xem ảnh đã căn'
                          : 'Dùng ảnh này',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:feedback/feedback.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

// Feedback capture is deliberately scoped here, never around auth/payment screens.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) => BetterFeedback(
    localeOverride: const Locale('vi'),
    localizationsDelegates: const [_ViFeedbackDelegate()],
    themeMode: ThemeMode.light,
    theme: FeedbackThemeData(
      background: const Color(0xFF123A52),
      feedbackSheetColor: const Color(0xFFF5F7FA),
      activeFeedbackModeColor: const Color(0xFFB58A45),
      colorScheme: Theme.of(context).colorScheme,
    ),
    child: const _FeedbackForm(),
  );
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm();
  @override
  State<_FeedbackForm> createState() => _FeedbackState();
}

class _FeedbackState extends State<_FeedbackForm> {
  final text = TextEditingController();
  Uint8List? screenshot;
  Json device = {};
  bool busy = false, deviceAllowed = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> describe() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final pkg = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => device = {
            'model': info.model,
            'os': 'Android ${info.version.release}',
            'app_version': '${pkg.version}+${pkg.buildNumber}',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        message(
          context,
          'Không đọc được thông tin thiết bị; vẫn có thể gửi nội dung',
        );
      }
    }
  }

  Future<void> send() async {
    if (text.text.trim().isEmpty) {
      message(context, 'Nhập nội dung phản hồi');
      return;
    }
    setState(() => busy = true);
    try {
      final api = context.read<ApiService>();
      final metadata = deviceAllowed ? device : <String, dynamic>{};
      if (screenshot != null) {
        await api.upload(
          '/feedback',
          screenshot!,
          'feedback.png',
          fields: {
            'noi_dung': text.text.trim(),
            'thiet_bi': jsonEncode(metadata),
          },
        );
      } else {
        await api.feedbackText(text.text.trim(), metadata);
      }
      if (mounted) {
        message(context, 'Đã gửi phản hồi riêng đến quản trị viên');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Góp ý và báo lỗi')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Mô tả thao tác và kết quả bạn gặp. Không gửi mật khẩu, mã xác minh, token hoặc thông tin thanh toán.',
        ),
        TextField(
          controller: text,
          maxLength: 4000,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Nội dung phản hồi'),
        ),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => BetterFeedback.of(context).show((f) {
                  if (mounted) {
                    setState(() {
                      screenshot = f.screenshot;
                      if (f.text.trim().isNotEmpty) text.text = f.text;
                    });
                  }
                }),
          icon: const Icon(Icons.draw_outlined),
          label: const Text('Chụp và chú thích màn hình góp ý'),
        ),
        const Text(
          'Chỉ chụp màn hình góp ý này. Xem và xóa ảnh nếu có thông tin riêng tư trước khi gửi.',
        ),
        if (screenshot != null) ...[
          Image.memory(screenshot!, height: 240),
          TextButton(
            onPressed: () => setState(() => screenshot = null),
            child: const Text('Bỏ ảnh đính kèm'),
          ),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: deviceAllowed,
          onChanged: busy
              ? null
              : (v) async {
                  setState(() => deviceAllowed = v!);
                  if (v!) await describe();
                },
          title: const Text('Đính kèm model, phiên bản Android và ứng dụng'),
        ),
        if (deviceAllowed)
          SelectableText(
            device.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
          ),
        FilledButton(
          onPressed: busy ? null : send,
          child: Text(busy ? 'Đang gửi…' : 'Gửi phản hồi'),
        ),
      ],
    ),
  );
}

class _ViFeedback extends FeedbackLocalizations {
  const _ViFeedback();
  @override
  String get submitButtonText => 'Xem lại ảnh đính kèm';
  @override
  String get feedbackDescriptionText =>
      'Mô tả lỗi (không nhập thông tin bí mật)';
  @override
  String get navigate => 'Di chuyển';
  @override
  String get draw => 'Đánh dấu';
}

class _ViFeedbackDelegate extends LocalizationsDelegate<FeedbackLocalizations> {
  const _ViFeedbackDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi';
  @override
  Future<FeedbackLocalizations> load(Locale locale) =>
      SynchronousFuture(const _ViFeedback());
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<FeedbackLocalizations> old,
  ) => false;
}

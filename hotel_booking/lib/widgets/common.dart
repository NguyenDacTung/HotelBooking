import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/api_service.dart';

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorPanel(this.message, this.retry, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB42318).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
              side: const BorderSide(color: Color(0xFFB42318)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: retry,
            child: const Text(
              'Thử lại',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomPhoto extends StatelessWidget {
  final String? path;
  final double height;
  const RoomPhoto(this.path, {super.key, this.height = 150});
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      color: const Color(0xFF123A52).withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(Icons.bed_outlined, size: 54, color: Color(0xFF123A52)),
    );
    return path == null
        ? placeholder
        : CachedNetworkImage(
            imageUrl: context.read<ApiService>().imageUrl(path!),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, e, s) => placeholder,
          );
  }
}

void message(BuildContext context, Object text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Text('$text'),
      backgroundColor: const Color(0xFF123A52),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Vui lòng nhập thông tin' : null;

/// Wait for the route to finish its dismissal animation before a caller
/// disposes form controllers or replaces the booking widget underneath it.
Future<T?> formDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );
  final result = await Navigator.of(context).push(route);
  await route.completed;
  return result;
}

String? phoneText(String? value) {
  final v = (value ?? '').replaceAll(RegExp(r'[\s().-]'), '');
  return RegExp(r'^(?:0[35789]\d{8}|\+[1-9]\d{7,14})$').hasMatch(v)
      ? null
      : 'Nhập số Việt Nam 10 chữ số hoặc số quốc tế có +';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});
  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<List<ConnectivityResult>>? subscription;
  bool offline = false;

  @override
  void initState() {
    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) {
        setState(() => offline = r.every((v) => v == ConnectivityResult.none));
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return offline
        ? MaterialBanner(
            backgroundColor: const Color(0xFFB58A45),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            content: const Text(
              'Không phát hiện Wi-Fi/di động. Nếu dùng USB, hãy kiểm tra chuyển tiếp cổng. TTTP vẫn kiểm tra từng yêu cầu tới máy chủ.',
            ),
            leading: const Icon(Icons.wifi_off, color: Colors.white),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => setState(() => offline = false),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import '../customer/booking_detail_screen.dart';

class BookingQrScreen extends StatelessWidget {
  final String id;
  const BookingQrScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mã đặt phòng')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Xuất trình mã cho lễ tân. Mã chỉ chứa mã tham chiếu; không chứa thông tin cá nhân hoặc quyền truy cập.',
          ),
          Center(
            child: QrImageView(
              data: 'TETRA:1:$id',
              size: 260,
              backgroundColor: Colors.white,
            ),
          ),
          SelectableText(id, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class BookingScannerScreen extends StatefulWidget {
  const BookingScannerScreen({super.key});
  @override
  State<BookingScannerScreen> createState() => _ScannerState();
}

class _ScannerState extends State<BookingScannerScreen>
    with WidgetsBindingObserver {
  final scanner = MobileScannerController(autoStart: false);
  final input = TextEditingController();
  bool camera = false, busy = false;
  String? lastScan;
  DateTime? lastTime;
  Future<void> startCamera() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && camera && !busy) await scanner.start();
    } catch (_) {
      if (mounted) {
        message(context, 'Không mở được camera. Bạn có thể nhập mã thủ công.');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scanner.dispose();
    input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      scanner.stop();
    } else if (camera && !busy) {
      startCamera();
    }
  }

  Future<void> resolve(String raw) async {
    if (busy) return;
    final value = raw.trim();
    if (!RegExp(r'^(?:(?:TETRA|TTTP):1:)?[0-9a-fA-F]{8}-[0-9a-fA-F-]{27}$')
        .hasMatch(value)) {
      message(context, 'Mã đặt phòng không hợp lệ');
      return;
    }
    setState(() => busy = true);
    await scanner.stop();
    if (!mounted) return;
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/staff/booking-reference/${Uri.encodeComponent(value)}',
      ) as Json;
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BookingDetailScreen(id: d['ma_pdp']),
          ),
        );
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        if (camera) await startCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tra cứu mã đặt phòng')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (camera)
          SizedBox(
            height: 300,
            child: MobileScanner(
              controller: scanner,
              onDetect: (capture) {
                if (capture.barcodes.isNotEmpty) {
                  final value = capture.barcodes.first.rawValue;
                  if (value != null) {
                    final t = DateTime.now();
                    if (value != lastScan ||
                        lastTime == null ||
                        t.difference(lastTime!).inSeconds >= 3) {
                      lastScan = value;
                      lastTime = t;
                      resolve(value);
                    }
                  }
                }
              },
              errorBuilder: (c, error) => const Center(
                child: Text('Không mở được camera. Có thể nhập mã bên dưới.'),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  setState(() => camera = !camera);
                  if (camera) {
                    await startCamera();
                  } else {
                    await scanner.stop();
                  }
                },
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(camera ? 'Tắt camera' : 'Mở camera quét mã'),
        ),
        if (camera)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              IconButton(
                tooltip: 'Đèn pin',
                onPressed: () => scanner.toggleTorch(),
                icon: const Icon(Icons.flash_on),
              ),
              IconButton(
                tooltip: 'Đổi camera',
                onPressed: () => scanner.switchCamera(),
                icon: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ),
        TextField(
          controller: input,
          decoration: const InputDecoration(
            labelText: 'Mã tham chiếu đặt phòng',
          ),
        ),
        FilledButton(
          onPressed: busy ? null : () => resolve(input.text),
          child: Text(busy ? 'Đang tra cứu…' : 'Tra cứu'),
        ),
        const Text(
          'Tra cứu không tự xác nhận, nhận phòng hay thu tiền. Kiểm tra đơn trước khi thực hiện nghiệp vụ.',
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/capabilities_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common.dart';
import '../shared/hotel_info_screen.dart';

class OnlinePaymentScreen extends StatefulWidget {
  final String bookingId;
  const OnlinePaymentScreen({super.key, required this.bookingId});
  @override
  State<OnlinePaymentScreen> createState() => _OnlineState();
}

class _OnlineState extends State<OnlinePaymentScreen>
    with WidgetsBindingObserver {
  List<Json> attempts = [];
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) load();
  }

  Future<void> load() async {
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/bookings/${widget.bookingId}/online-payments',
      ) as Json;
      if (mounted) {
        setState(() {
          attempts = (d['items'] as List).cast<Json>();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> create(String provider) async {
    setState(() => busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final key =
          'tetra-payment-${context.read<SessionProvider>().user!['id']}-${widget.bookingId}-$provider';
      final request = prefs.getString(key) ?? const Uuid().v4();
      await prefs.setString(key, request);
      if (!mounted) return;
      final a = await context.read<ApiService>().request(
        'POST',
        '/bookings/${widget.bookingId}/online-payments',
        body: {'provider': provider, 'request_id': request},
      ) as Json;
      if (a['state'] == 'FAILED') await prefs.remove(key);
      if (mounted) {
        await load();
        if (mounted &&
            a['payment_url'] != null &&
            ['CREATED', 'PENDING'].contains(a['state'])) {
          await launch(a);
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> launch(Json a) async {
    final uri = Uri.tryParse(a['payment_url'] ?? '');
    final hosts = a['provider'] == 'MOMO'
        ? {'test-payment.momo.vn', 'payment.momo.vn'}
        : {'sandbox.vnpayment.vn', 'pay.vnpay.vn'};
    if (uri == null ||
        uri.scheme != 'https' ||
        !hosts.contains(uri.host) ||
        uri.userInfo.isNotEmpty) {
      message(context, 'Địa chỉ thanh toán không hợp lệ');
      return;
    }
    await openTrusted(context, uri);
  }

  Future<void> check(Json a) async {
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'POST',
        '/online-payments/${a['id']}/query',
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = context.watch<CapabilitiesProvider>();
    final pending = attempts.any(
      (a) => ['CREATED', 'PENDING'].contains(a['state']),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán online')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Số tiền lấy từ hóa đơn trên máy chủ. Quay về từ trình duyệt không đồng nghĩa đã thanh toán; hãy kiểm tra kết quả.',
          ),
          if (caps.loading) const LinearProgressIndicator(),
          if (caps.error != null) ErrorPanel(caps.unavailable, caps.load),
          for (final provider in ['MOMO', 'VNPAY']) ...[
            FilledButton.icon(
              onPressed:
                  busy ||
                      pending ||
                      !caps.ready('payments', provider.toLowerCase())
                  ? null
                  : () => create(provider),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                '$provider${caps.ready('payments', provider.toLowerCase()) ? '' : ' • ${caps.unavailable}'}',
              ),
            ),
            if (caps.data?['payments']?[provider
                    .toLowerCase()]?['environment'] ==
                'sandbox')
              const Text(
                'Môi trường sandbox: tiền thử nghiệm không thanh toán công nợ thật.',
              ),
          ],
          if (error != null) ErrorPanel(error!, load),
          if (busy) const LinearProgressIndicator(),
          for (final a in attempts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['provider']} • ${a['amount']} VND • ${a['environment']}',
                    ),
                    Text('Trạng thái: ${a['state']}'),
                    if (a['note'] != null) Text(a['note']),
                    if (['CREATED', 'PENDING'].contains(a['state'])) ...[
                      const Text(
                        'Đang chờ xác minh. Không thu lại bằng phương thức khác. Hết thời gian mở cổng vẫn cần đối soát kết quả.',
                      ),
                      if (a['payment_url'] != null)
                        TextButton(
                          onPressed: busy ? null : () => launch(a),
                          child: const Text('Mở lại cổng thanh toán'),
                        ),
                      OutlinedButton(
                        onPressed: busy ? null : () => check(a),
                        child: const Text('Kiểm tra kết quả'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: busy ? null : load,
            child: const Text('Làm mới danh sách'),
          ),
        ],
      ),
    );
  }
}

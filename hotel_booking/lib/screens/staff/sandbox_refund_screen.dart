import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../providers/capabilities_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class SandboxRefundScreen extends StatefulWidget {
  final String bookingId;
  const SandboxRefundScreen({super.key, required this.bookingId});

  @override
  State<SandboxRefundScreen> createState() => _SandboxRefundState();
}

class _SandboxRefundState extends State<SandboxRefundScreen> {
  List<Json> attempts = [], refunds = [];
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (context.read<SessionProvider>().manager) load();
  }

  Future<void> load() async {
    if (busy || !context.read<SessionProvider>().manager) return;
    setState(() => busy = true);
    try {
      final api = context.read<ApiService>();
      final rows = await Future.wait([
        api.request('GET', '/bookings/${widget.bookingId}/online-payments'),
        api.request('GET', '/bookings/${widget.bookingId}/online-refunds'),
      ]);
      if (mounted) {
        setState(() {
          attempts = ((rows[0] as Json)['items'] as List).cast<Json>();
          refunds = ((rows[1] as Json)['items'] as List).cast<Json>();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refund(Json attempt) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hoàn toàn phần sandbox'),
        content: Text(
          'Gửi yêu cầu hoàn ${attempt['amount']} VND tiền thử nghiệm qua ${attempt['provider']}? Công nợ thật không thay đổi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Gửi yêu cầu hoàn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      final account = context.read<SessionProvider>().user!['id'];
      final prefs = await SharedPreferences.getInstance();
      final key = 'tetra-sandbox-refund-$account-${attempt['id']}';
      final request = prefs.getString(key) ?? const Uuid().v4();
      await prefs.setString(key, request);
      if (!mounted) return;
      final result = await context.read<ApiService>().request(
        'POST',
        '/admin/online-payments/${attempt['id']}/refunds',
        body: {'request_id': request},
      ) as Json;
      if (['SUCCEEDED', 'FAILED'].contains(result['state'])) {
        await prefs.remove(key);
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
      }
    }
  }

  Future<void> query(Json row) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await context.read<ApiService>().request(
        'POST',
        '/admin/online-refunds/${row['id']}/query',
      ) as Json;
      if (['SUCCEEDED', 'FAILED'].contains(result['state']) && mounted) {
        final account = context.read<SessionProvider>().user!['id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(
          'tetra-sandbox-refund-$account-${row['attempt_id']}',
        );
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SessionProvider>().manager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hoàn sandbox')),
        body: const Center(child: Text('Bạn không có quyền truy cập')),
      );
    }
    final caps = context.watch<CapabilitiesProvider>();
    final eligible = attempts.where(
      (a) => a['environment'] == 'sandbox' && a['state'] == 'SUCCEEDED',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn tiền sandbox')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chỉ hoàn toàn phần giao dịch thử nghiệm đã thành công. Đây không phải hoàn tiền production. Khi chưa xác định kết quả, hãy đối soát trước khi thử lại.',
          ),
          if (busy || caps.loading) const LinearProgressIndicator(),
          if (caps.error != null) ErrorPanel(caps.unavailable, caps.load),
          if (!caps.loading && !caps.ready('online_refund'))
            Text(caps.unavailable),
          if (error != null) ErrorPanel(error!, load),
          for (final a in eligible)
            Card(
              child: ListTile(
                title: Text('${a['provider']} • ${a['amount']} VND • sandbox'),
                subtitle: const Text('Khoản thanh toán thử nghiệm thành công'),
                trailing: TextButton(
                  onPressed:
                      busy ||
                          !caps.ready(
                            'payments',
                            (a['provider'] as String).toLowerCase(),
                          ) ||
                          !caps.ready('online_refund') ||
                          refunds.any(
                            (r) =>
                                r['attempt_id'] == a['id'] &&
                                r['state'] != 'FAILED',
                          )
                      ? null
                      : () => refund(a),
                  child: const Text('Hoàn sandbox'),
                ),
              ),
            ),
          if (!busy && eligible.isEmpty)
            const Text('Chưa có khoản thanh toán sandbox thành công.'),
          for (final row in refunds)
            Card(
              child: ListTile(
                title: Text('${row['amount']} VND • ${row['state']}'),
                subtitle: Text(row['note'] as String? ?? 'Hoàn sandbox'),
                trailing: ['CREATED', 'PENDING'].contains(row['state'])
                    ? TextButton(
                        onPressed: busy ? null : () => query(row),
                        child: const Text('Đối soát'),
                      )
                    : null,
              ),
            ),
          TextButton(
            onPressed: busy ? null : load,
            child: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }
}

import '../../providers/capabilities_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../widgets/common.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final email = TextEditingController(),
      code = TextEditingController(),
      password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool sent = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<ApiService>().request(
        'POST',
        sent ? '/auth/reset-password' : '/auth/forgot-password',
        body: {
          'email': email.text.trim(),
          if (sent) ...{
            'ma_xac_nhan': code.text.trim(),
            'mat_khau': password.text,
          },
        },
      );
      if (!mounted) return;
      if (sent) {
        message(context, 'Đã đổi mật khẩu. Vui lòng đăng nhập lại.');
        Navigator.pop(context);
      } else {
        setState(() => sent = true);
        message(
          context,
          'Nếu tài khoản tồn tại, mã xác nhận sẽ được gửi qua email.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = context.watch<CapabilitiesProvider?>();
    final available = caps?.ready('recovery') ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (caps?.loading == true) const LinearProgressIndicator(),
              if (caps?.error != null) ErrorPanel(caps!.unavailable, caps.load),
              if (caps?.loading != true && caps?.error == null && !available)
                const Text(
                  'Email khôi phục chưa được cấu hình. Vui lòng liên hệ quản trị viên.',
                ),
              TextFormField(
                controller: email,
                enabled: !busy && !sent,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email tài khoản'),
                validator: requiredText,
              ),
              if (sent) ...[
                TextFormField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã xác nhận trong email',
                  ),
                  validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                      ? null
                      : 'Nhập mã gồm 6 chữ số',
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                  validator: (v) =>
                      (v?.length ?? 0) >= 8 && (v?.length ?? 0) <= 128
                      ? null
                      : 'Mật khẩu từ 8 đến 128 ký tự',
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu mới',
                  ),
                  validator: (v) =>
                      v == password.text ? null : 'Mật khẩu không khớp',
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy || !available ? null : submit,
                child: Text(
                  busy
                      ? 'Đang xử lý…'
                      : sent
                      ? 'Đổi mật khẩu'
                      : 'Gửi mã xác nhận',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

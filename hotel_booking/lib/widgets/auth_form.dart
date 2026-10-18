import '../providers/capabilities_provider.dart';

import 'package:flutter/material.dart';

import '../screens/auth/recovery_screen.dart';

import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../services/social_login_service.dart';
import '../screens/auth/register_screen.dart';
import 'common.dart';

class AuthForm extends StatefulWidget {
  final bool register;
  const AuthForm({super.key, this.register = false});
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      phone = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false, hidden = true;
  String? error;

  @override
  void dispose() {
    for (final c in [email, password, name, phone, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.register) {
        await context.read<ApiService>().request(
          'POST',
          '/auth/register',
          body: {
            'email': email.text.trim(),
            'mat_khau': password.text,
            'ho_ten': name.text.trim(),
            if (phone.text.trim().isNotEmpty)
              'so_dien_thoai': phone.text.trim(),
          },
        );
        if (mounted) {
          message(context, 'Đăng ký thành công. Vui lòng đăng nhập.');
          Navigator.pop(context);
        }
      } else {
        await context.read<SessionProvider>().login(email.text, password.text);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> social(String provider) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final credential = await SocialLoginService().credential(provider);
      if (!mounted) return;
      await context.read<SessionProvider>().social(provider, credential);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> fingerprint() async {
    // Deliberately do not validate email/password for biometric sign-in.
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<SessionProvider>().loginWithBiometric();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = context.watch<CapabilitiesProvider?>();
    final googleReady =
        SocialLoginService.googleClientId.isNotEmpty &&
        (caps?.ready('social_login', 'google') ?? false);
    final facebookReady =
        SocialLoginService.facebookEnabled &&
        (caps?.ready('social_login', 'facebook') ?? false);
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.register ? 'Tạo tài khoản' : 'Chào mừng trở lại',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF123A52),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.register) ...[
            TextFormField(
              controller: name,
              maxLength: 120,
              validator: requiredText,
              decoration: InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phone,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? null : phoneText(v),
              maxLength: 20,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Điện thoại (tùy chọn)',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) =>
                v != null &&
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? null
                : 'Email không hợp lệ',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: hidden,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) =>
                v == null ||
                    v.isEmpty ||
                    v.length > 128 ||
                    (widget.register && v.length < 8)
                ? (widget.register
                      ? 'Mật khẩu từ 8 đến 128 ký tự'
                      : 'Vui lòng nhập mật khẩu')
                : null,
          ),
          if (widget.register) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  v == password.text ? null : 'Mật khẩu không khớp',
            ),
          ],
          if (error != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB42318).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123A52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: busy ? null : submit,
              child: Text(
                busy
                    ? 'Đang xử lý…'
                    : widget.register
                    ? 'Đăng ký'
                    : 'Đăng nhập',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (!widget.register) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : fingerprint,
              icon: const Icon(Icons.fingerprint, size: 30),
              label: const Text('Đăng nhập bằng vân tay'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Dùng tài khoản đã bật vân tay trong Cài đặt trên điện thoại này.',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RecoveryScreen(),
                      ),
                    ),
              child: const Text('Quên mật khẩu?'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB58A45),
              ),
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
              child: const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (caps?.error != null) ErrorPanel(caps!.unavailable, caps.load),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF152536),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: busy || !googleReady ? null : () => social('google'),
              icon: const Icon(Icons.g_mobiledata, color: Color(0xFFB58A45)),
              label: Text(
                !googleReady ? 'Google · Chưa cấu hình' : 'Tiếp tục với Google',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF152536),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: busy || !facebookReady
                  ? null
                  : () => social('facebook'),
              icon: const Icon(Icons.facebook, color: Color(0xFF123A52)),
              label: Text(
                facebookReady
                    ? 'Tiếp tục với Facebook'
                    : 'Facebook · Chưa cấu hình',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

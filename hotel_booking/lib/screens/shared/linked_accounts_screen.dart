import '../../providers/capabilities_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/social_login_service.dart';
import '../../providers/session_provider.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});
  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  List<Json> items = [];
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await context.read<ApiService>().request(
        'GET',
        '/users/me/identities',
      ) as Json;
      if (mounted) setState(() => items = (data['items'] as List).cast<Json>());
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> act(String provider, bool linked) async {
    setState(() => busy = true);
    try {
      if (linked) {
        await context.read<ApiService>().request(
          'DELETE',
          '/users/me/identities/$provider',
        );
        if (!mounted) return;
        await context.read<SessionProvider>().logout();
        if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        final credential = await SocialLoginService().credential(
          provider.toLowerCase(),
        );
        if (!mounted) return;
        await context.read<ApiService>().request(
          'POST',
          '/users/me/identities/$provider',
          body: {'credential': credential},
        );
        if (mounted) await load();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Phương thức đăng nhập',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (busy)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: Color(0xFFB58A45),
              ),
            ),
          if (error != null) ...[
            const SizedBox(height: 8),
            ErrorPanel(error!, load),
          ],
          const SizedBox(height: 8),
          for (final provider in ['GOOGLE', 'FACEBOOK'])
            Builder(
              builder: (context) {
                final linked = items.any((i) => i['provider'] == provider);
                final configured =
                    (caps?.ready('social_login', provider.toLowerCase()) ??
                        false) &&
                    (provider == 'GOOGLE'
                        ? SocialLoginService.googleClientId.isNotEmpty
                        : SocialLoginService.facebookEnabled);
                final isGoogle = provider == 'GOOGLE';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: linked
                          ? const Color(0xFF237A57).withValues(alpha: 0.35)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isGoogle
                                    ? const Color(0xFFB58A45)
                                    : const Color(0xFF123A52))
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGoogle
                            ? Icons.g_mobiledata_rounded
                            : Icons.facebook_rounded,
                        color: isGoogle
                            ? const Color(0xFFB58A45)
                            : const Color(0xFF123A52),
                        size: 26,
                      ),
                    ),
                    title: Text(
                      isGoogle ? 'Google' : 'Facebook',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152536),
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        linked
                            ? 'Đã liên kết'
                            : configured
                            ? 'Chưa liên kết'
                            : 'Chưa cấu hình',
                        style: TextStyle(
                          color: linked
                              ? const Color(0xFF237A57)
                              : const Color(0xFF5C6875),
                          fontWeight: linked
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: linked
                            ? const Color(0xFFB42318)
                            : const Color(0xFF123A52),
                        backgroundColor:
                            (linked
                                    ? const Color(0xFFB42318)
                                    : const Color(0xFF123A52))
                                .withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: busy || !configured
                          ? null
                          : () => act(provider, linked),
                      child: Text(
                        linked ? 'Hủy liên kết' : 'Liên kết',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: Color(0xFF123A52)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TETRA không tự liên kết tài khoản chỉ vì trùng email. Hủy liên kết sẽ yêu cầu đăng nhập lại; không thể bỏ phương thức đăng nhập cuối cùng.',
                    style: TextStyle(
                      color: Color(0xFF5C6875),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

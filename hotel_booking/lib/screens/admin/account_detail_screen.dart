import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../core/strings.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';

class AccountDetailScreen extends StatefulWidget {
  final String? id;
  const AccountDetailScreen({super.key, this.id});
  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      phone = TextEditingController();
  Json? account;
  String role = 'LE_TAN';
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) load();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final data = await context.read<ApiService>().request(
        'GET',
        '/admin/accounts/${widget.id}',
      ) as Json;
      if (mounted) {
        setState(() {
          account = data;
          name.text = data['ho_ten'] as String;
          phone.text = data['so_dien_thoai'] as String? ?? '';
          role = data['ma_quyen'] as String;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final isNew = widget.id == null;
      await context.read<ApiService>().request(
        isNew ? 'POST' : 'PATCH',
        isNew ? '/admin/accounts' : '/admin/accounts/${widget.id}',
        body: isNew
            ? {
                'ho_ten': name.text.trim(),
                'email': email.text.trim(),
                'mat_khau': password.text,
                'ma_quyen': role,
              }
            : {
                'ho_ten': name.text.trim(),
                if (role == 'KHACH_HANG')
                  'so_dien_thoai': phone.text.trim().isEmpty
                      ? null
                      : phone.text.trim(),
              },
      );
      if (mounted) {
        message(context, 'Đã lưu tài khoản');
        if (isNew) {
          Navigator.pop(context);
        } else {
          await load();
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> access(bool changeRole) async {
    final reason = TextEditingController();
    final key = GlobalKey<FormState>();
    String next = role == 'QUAN_LY' ? 'LE_TAN' : 'QUAN_LY';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          changeRole
              ? 'Đổi vai trò thành ${TttpStrings.roleNames[next]}?'
              : account!['dang_hoat_dong'] == true
              ? 'Khóa tài khoản?'
              : 'Mở khóa tài khoản?',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF152536),
            fontSize: 18,
          ),
        ),
        content: Form(
          key: key,
          child: TextFormField(
            controller: reason,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'Lý do (tùy chọn)',
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF123A52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'PATCH',
        '/admin/accounts/${widget.id}/${changeRole ? 'role' : 'status'}',
        body: {
          if (changeRole)
            'ma_quyen': next
          else
            'dang_hoat_dong': account!['dang_hoat_dong'] != true,
          'ly_do': reason.text.trim(),
        },
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
    final isActive = account?['dang_hoat_dong'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          widget.id == null ? 'Tạo tài khoản nội bộ' : 'Chi tiết tài khoản',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB42318).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB42318).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            if (widget.id == null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF123A52).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      validator: requiredText,
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 8 && v.length <= 128
                          ? null
                          : 'Mật khẩu từ 8 đến 128 ký tự',
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu ban đầu',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(
                        labelText: 'Vai trò nội bộ',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: ['LE_TAN', 'QUAN_LY']
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(TttpStrings.roleNames[r]!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => role = v!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (account != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D2B3E),
                      Color(0xFF123A52),
                      Color(0xFF1B4D6B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF123A52).withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB58A45)
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB58A45)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_outlined,
                            color: Color(0xFFB58A45),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account!['email'] as String? ?? 'Chưa có email',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB58A45),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  TttpStrings.roleNames[role]!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Đăng nhập: ${(account!['cach_dang_nhap'] as List).join(', ')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tạo ngày ${vietnamTime(account!['ngay_tao'] as String)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF123A52).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  if (role == 'KHACH_HANG') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phone,
                      maxLength: 20,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF123A52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: busy ? null : save,
                      child: const Text(
                        'Lưu hồ sơ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (account != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (role != 'KHACH_HANG') ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF123A52),
                          side: const BorderSide(color: Color(0xFF123A52)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: busy ? null : () => access(true),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        label: const Text(
                          'Đổi quyền nội bộ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive
                            ? const Color(0xFFB42318)
                            : const Color(0xFF237A57),
                        side: BorderSide(
                          color:
                              (isActive
                                      ? const Color(0xFFB42318)
                                      : const Color(0xFF237A57))
                                  .withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy ? null : () => access(false),
                      icon: Icon(
                        isActive
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (role == 'KHACH_HANG') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tài khoản khách không thể chuyển trực tiếp thành nhân viên hoặc quản trị viên.',
                          style: TextStyle(
                            color: Color(0xFF5C6875),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              Text(
                'Lịch sử quản trị',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF123A52),
                ),
              ),
              const SizedBox(height: 12),
              ...(account!['lich_su'] as List? ?? []).map(
                (a) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A52).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Color(0xFF123A52),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${a['action']} · ${a['ly_do']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152536),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${vietnamTime(a['thoi_diem'] as String)}\n${a['before'] ?? ''} → ${a['after'] ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF5C6875),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

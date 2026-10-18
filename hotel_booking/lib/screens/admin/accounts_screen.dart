import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../core/strings.dart';
import '../../widgets/common.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final search = TextEditingController();
  List<Json> items = [];
  int page = 1, total = 0;
  bool busy = true;
  String? error, role;
  bool? active;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = more ? page + 1 : 1;
      final data = await context.read<ApiService>().request(
        'GET',
        '/admin/accounts',
        query: {
          'page': next,
          if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
          if (role != null) 'role': role,
          if (active != null) 'active': active,
        },
      ) as Json;
      if (mounted) {
        setState(() {
          final rows = (data['items'] as List).cast<Json>();
          items = more ? [...items, ...rows] : rows;
          page = next;
          total = data['total'] as int;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open([String? id]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AccountDetailScreen(id: id)),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Quản lý tài khoản',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo tài khoản nội bộ',
            onPressed: busy ? null : () => open(),
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF123A52).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: search,
                    decoration: InputDecoration(
                      labelText: 'Tìm tên hoặc email',
                      prefixIcon: const Icon(Icons.manage_search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: busy ? null : load,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    onSubmitted: (_) => load(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...TttpStrings.roleNames.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) {
                            role = v;
                            load();
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    initialValue: active,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái tài khoản',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      DropdownMenuItem(value: true, child: Text('Hoạt động')),
                      DropdownMenuItem(value: false, child: Text('Đã khóa')),
                    ],
                    onChanged: busy
                        ? null
                        : (v) {
                            active = v;
                            load();
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            if (!busy && items.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Không tìm thấy tài khoản phù hợp.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ...items.map((a) {
              final isActive = a['dang_hoat_dong'] == true;
              final statusColor = isActive
                  ? const Color(0xFF237A57)
                  : const Color(0xFFB42318);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFB42318).withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive
                          ? Icons.person_outline_rounded
                          : Icons.person_off_outlined,
                      color: statusColor,
                    ),
                  ),
                  title: Text(
                    a['ho_ten'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152536),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${a['email'] ?? 'Chưa có email'}\n${TttpStrings.roleNames[a['ma_quyen']]} · ${isActive ? 'Hoạt động' : 'Đã khóa'}',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5C6875),
                  ),
                  onTap: () => open(a['id'] as String),
                ),
              );
            }),
            if (items.length < total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: busy ? null : () => load(more: true),
                  child: const Text('Tải thêm'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

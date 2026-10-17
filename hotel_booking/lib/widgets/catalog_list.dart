import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../core/config.dart';

import 'catalog_edit.dart';

const sections = {
  'room-types': 'Loại phòng',
  'rooms': 'Phòng',
  'amenities': 'Tiện nghi',
  'room-closures': 'Lịch tạm ngừng',
};

class CatalogList extends StatefulWidget {
  final String section;
  const CatalogList({super.key, required this.section});
  @override
  State<CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends State<CatalogList> {
  List<Json> items = [];
  String? error;
  bool loading = true;
  int page = 1, total = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = more ? page + 1 : 1;
      final result = await context.read<ApiService>().request(
        'GET',
        '/staff/${widget.section}',
        query: {'page': next},
      ) as Json;
      if (mounted) {
        setState(() {
          final rows = (result['items'] as List).cast<Json>();
          items = more ? [...items, ...rows] : rows;
          total = result['total'] as int;
          page = next;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Json? item]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CatalogEdit(section: widget.section, item: item),
      ),
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
        title: Text(
          sections[widget.section]!,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm mới',
            onPressed: loading ? null : () => edit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFFB58A45),
                ),
              ),
            if (error != null) ErrorPanel(error!, load),
            if (!loading && items.isEmpty && error == null)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Chưa có dữ liệu.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ...items.map(
              (item) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    '${item['ten_loai'] ?? item['ten_tien_nghi'] ?? 'Phòng ${item['ma_phong']}'}${item['so_phong'] == null ? '' : ' • ${item['so_phong']}'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152536),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.section == 'room-closures'
                          ? '${localDate(item['tu_ngay'] as String)} → ${localDate(item['den_ngay'] as String)}\n${item['ly_do']} • ${item['dang_hieu_luc'] == true ? 'Hiệu lực' : 'Đã dừng'}'
                          : item['dang_kinh_doanh'] == false
                          ? 'Đang ẩn'
                          : widget.section == 'rooms'
                          ? item['trang_thai_su_dung'] == 'DANG_SU_DUNG'
                                ? 'Đang sử dụng'
                                : 'Còn trống'
                          : 'Đang sử dụng',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF5C6875),
                  ),
                  onTap: () => edit(item),
                ),
              ),
            ),
            if (items.length < total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: loading ? null : () => load(more: true),
                  child: const Text('Tải thêm'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

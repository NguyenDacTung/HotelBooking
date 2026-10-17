import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../core/config.dart';

import 'catalog_list.dart'; // Đã có sections
import '../screens/admin/room_images_screen.dart';

class FieldSpec {
  final String keyName, label, kind;
  final bool optional;
  const FieldSpec(
    this.keyName,
    this.label, [
    this.kind = 'text',
    this.optional = false,
  ]);
}

const fields = <String, List<FieldSpec>>{
  'room-types': [
    FieldSpec('ten_loai', 'Tên loại'),
    FieldSpec('gia_co_ban', 'Giá mỗi đêm (VND)', 'money'),
    FieldSpec('suc_chua', 'Sức chứa', 'positive'),
    FieldSpec('mo_ta', 'Mô tả', 'text', true),
    FieldSpec('dien_tich_m2', 'Diện tích (m²)', 'decimal', true),
    FieldSpec('so_giuong', 'Số giường', 'positive', true),
  ],
  'rooms': [
    FieldSpec('so_phong', 'Số phòng'),
    FieldSpec('ma_lp', 'Loại phòng', 'type'),
    FieldSpec('tang', 'Tầng', 'integer', true),
    FieldSpec('ghi_chu', 'Ghi chú nội bộ', 'text', true),
  ],
  'amenities': [
    FieldSpec('ten_tien_nghi', 'Tên tiện nghi'),
    FieldSpec('bieu_tuong', 'Tên biểu tượng', 'text', true),
  ],
  'room-closures': [
    FieldSpec('ma_phong', 'Phòng', 'room'),
    FieldSpec('tu_ngay', 'Từ ngày', 'date'),
    FieldSpec('den_ngay', 'Đến ngày (không chiếm ngày này)', 'date'),
    FieldSpec('ly_do', 'Lý do'),
  ],
};
const keys = {
  'room-types': 'ma_lp',
  'rooms': 'ma_phong',
  'amenities': 'ma_tn',
  'room-closures': 'ma_ngung',
};

class CatalogEdit extends StatefulWidget {
  final String section;
  final Json? item;
  const CatalogEdit({super.key, required this.section, this.item});
  @override
  State<CatalogEdit> createState() => _CatalogEditState();
}

class _CatalogEditState extends State<CatalogEdit> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  List<Json> choices = [];
  bool busy = false, active = true;
  String? error;

  @override
  void initState() {
    super.initState();
    for (final f in fields[widget.section]!) {
      controllers[f.keyName] = TextEditingController(
        text: '${widget.item?[f.keyName] ?? ''}',
      );
    }
    active =
        widget.item?[widget.section == 'room-closures'
                ? 'dang_hieu_luc'
                : 'dang_kinh_doanh']
            as bool? ??
        true;
    if (widget.section == 'rooms' || widget.section == 'room-closures') {
      loadChoices();
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadChoices() async {
    try {
      final api = context.read<ApiService>();
      final rows = <Json>[];
      int page = 1, total = 1;
      while (rows.length < total) {
        final result = await api.request(
          'GET',
          '/staff/${widget.section == 'rooms' ? 'room-types' : 'rooms'}',
          query: {'page': page++, 'page_size': 100},
        ) as Json;
        rows.addAll((result['items'] as List).cast<Json>());
        total = result['total'] as int;
      }
      if (mounted) setState(() => choices = rows);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  String? validate(FieldSpec f, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return f.optional ? null : 'Vui lòng nhập thông tin';
    if (f.kind == 'money' && ((int.tryParse(v) ?? -1) < 0)) {
      return 'Nhập số nguyên ≥ 0';
    }
    if (f.kind == 'positive' && ((int.tryParse(v) ?? 0) <= 0)) {
      return 'Nhập số nguyên > 0';
    }
    if (f.kind == 'decimal' && ((double.tryParse(v) ?? 0) <= 0)) {
      return 'Nhập số > 0';
    }
    if (f.kind == 'integer' && int.tryParse(v) == null) return 'Nhập số nguyên';
    if (f.kind == 'date' && DateTime.tryParse(v) == null) {
      return 'Ngày không hợp lệ';
    }
    return null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final body = <String, dynamic>{};
    for (final f in fields[widget.section]!) {
      if (widget.item != null &&
          widget.section == 'room-closures' &&
          f.keyName == 'ma_phong') {
        continue;
      }
      final value = controllers[f.keyName]!.text.trim();
      body[f.keyName] = value.isEmpty
          ? null
          : ['money', 'positive', 'integer', 'type', 'room'].contains(f.kind)
              ? int.parse(value)
              : f.kind == 'decimal'
                  ? double.parse(value)
                  : value;
    }
    if (widget.section != 'amenities') {
      body[widget.section == 'room-closures'
              ? 'dang_hieu_luc'
              : 'dang_kinh_doanh'] =
          active;
    }
    if (widget.section == 'room-closures' &&
        (body['den_ngay'] as String).compareTo(body['tu_ngay'] as String) <=
            0) {
      message(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<ApiService>().request(
        widget.item == null ? 'POST' : 'PATCH',
        '/staff/${widget.section}${widget.item == null ? '' : '/${widget.item![keys[widget.section]]}'}',
        body: body,
      );
      if (mounted) {
        message(context, 'Đã lưu');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
          '${widget.item == null ? 'Thêm' : 'Sửa'} ${sections[widget.section]!.toLowerCase()}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final f in fields[widget.section]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ['type', 'room'].contains(f.kind)
                    ? DropdownButtonFormField<int>(
                        initialValue: choices.any(
                              (e) =>
                                  '${e[f.kind == 'type' ? 'ma_lp' : 'ma_phong']}' ==
                                  controllers[f.keyName]!.text,
                            )
                            ? int.tryParse(controllers[f.keyName]!.text)
                            : null,
                        decoration: InputDecoration(
                          labelText: f.label,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: choices
                            .map(
                              (e) => DropdownMenuItem(
                                value: e[f.kind == 'type' ? 'ma_lp' : 'ma_phong']
                                    as int,
                                child: Text(
                                  '${e[f.kind == 'type' ? 'ten_loai' : 'so_phong']}',
                                ),
                              ),
                            )
                            .toList(),
                        validator: (v) =>
                            v == null && controllers[f.keyName]!.text.isEmpty
                                ? 'Chọn ${f.label.toLowerCase()}'
                                : null,
                        onChanged: busy ||
                                (widget.item != null &&
                                    widget.section == 'room-closures')
                            ? null
                            : (v) => controllers[f.keyName]!.text = '$v',
                      )
                    : TextFormField(
                        controller: controllers[f.keyName],
                        enabled: !busy,
                        readOnly: f.kind == 'date',
                        decoration: InputDecoration(
                          labelText: f.label,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          suffixIcon: f.kind == 'date'
                              ? const Icon(Icons.calendar_today, color: Color(0xFF123A52))
                              : null,
                        ),
                        keyboardType: [
                          'money',
                          'positive',
                          'integer',
                          'decimal',
                        ].contains(f.kind)
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              )
                            : TextInputType.text,
                        validator: (v) => validate(f, v),
                        onTap: f.kind == 'date'
                            ? () async {
                                final day = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                  initialDate: DateTime.tryParse(
                                        controllers[f.keyName]!.text,
                                      ) ??
                                      DateTime.now(),
                                );
                                if (day != null && mounted) {
                                  controllers[f.keyName]!.text = dateOnly(day);
                                }
                              }
                            : null,
                      ),
              ),
            if (widget.section != 'amenities') ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SwitchListTile(
                  activeThumbColor: const Color(0xFF237A57),
                  title: Text(
                    widget.section == 'room-closures'
                        ? 'Đang hiệu lực'
                        : 'Đang kinh doanh',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152536),
                    ),
                  ),
                  value: active,
                  onChanged: busy ? null : (v) => setState(() => active = v),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB42318).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                child: Text(
                  busy ? 'Đang lưu…' : 'Lưu',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            if (widget.section == 'room-types' && widget.item != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF123A52),
                    side: const BorderSide(color: Color(0xFF123A52)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: busy
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RoomImagesScreen(
                                typeId: widget.item!['ma_lp'] as int,
                              ),
                            ),
                          ),
                  child: const Text(
                    'Quản lý tiện nghi và ảnh',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
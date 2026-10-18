import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../core/config.dart';
import '../../core/strings.dart';
import '../../widgets/common.dart';

class RoomStatusScreen extends StatefulWidget {
  const RoomStatusScreen({super.key});
  @override
  State<RoomStatusScreen> createState() => _RoomStatusScreenState();
}

class _RoomStatusScreenState extends State<RoomStatusScreen> {
  List<Json> items = [], types = [];
  int? type;
  bool busy = true;
  String? error, status;
  int page = 1, total = 0;
  final floor = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    loadTypes();
  }

  Future<void> loadTypes() async {
    try {
      final data = await context.read<ApiService>().request(
        'GET',
        '/room-types',
        query: {'page_size': 100},
      ) as Json;
      if (mounted) setState(() => types = (data['items'] as List).cast<Json>());
    } catch (_) {
      /* Main list errors remain visible. */
    }
  }

  @override
  void dispose() {
    floor.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = more ? page + 1 : 1;
      final result = await context.read<ApiService>().request(
        'GET',
        '/staff/rooms/status',
        query: {
          'page': next,
          if (type != null) 'ma_lp': type,
          if (int.tryParse(floor.text) != null) 'tang': int.parse(floor.text),
          if (status != null) 'tinh_trang': status,
        },
      ) as Json;
      if (mounted) {
        setState(() {
          final rows = (result['items'] as List).cast<Json>();
          items = more ? [...items, ...rows] : rows;
          page = next;
          total = result['total'] as int;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Color _operationColor(String? op) {
    switch (op) {
      case 'SAN_SANG':
        return const Color(0xFF237A57);
      case 'CAN_DON_DEP':
        return const Color(0xFFB58A45);
      case 'DANG_DON_DEP':
        return const Color(0xFF123A52);
      case 'BAO_TRI':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF237A57);
    }
  }

  Future<void> change(Json room) async {
    final old = room['tinh_trang_van_hanh'] as String;
    final next = {
      'SAN_SANG': 'CAN_DON_DEP',
      'CAN_DON_DEP': 'DANG_DON_DEP',
      'DANG_DON_DEP': 'SAN_SANG',
      'BAO_TRI': 'SAN_SANG',
    }[old]!;
    String selected = next;
    DateTime start = DateTime.now(),
        end = DateTime.now().add(const Duration(days: 1));
    final reason = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF123A52).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: Color(0xFF123A52),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Phòng ${room['so_phong']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152536),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: next,
                    decoration: InputDecoration(
                      labelText: 'Tình trạng mới',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [next, if (old != 'BAO_TRI') 'BAO_TRI']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(TttpStrings.operationNames[v]!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => set(() => selected = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                  if (selected == 'BAO_TRI') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF123A52),
                          side: const BorderSide(color: Color(0xFF123A52)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final r = await showDateRangePicker(
                            context: c,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (r != null) {
                            set(() {
                              start = r.start;
                              end = r.end;
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          '${localDate(dateOnly(start))} → ${localDate(dateOnly(end))}',
                        ),
                      ),
                    ),
                  ],
                ],
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
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      await context.read<ApiService>().request(
        'PATCH',
        '/staff/rooms/${room['ma_phong']}/operational-status',
        body: {
          'tinh_trang_van_hanh': selected,
          'ly_do': reason.text.trim(),
          if (selected == 'BAO_TRI') 'tu_ngay': dateOnly(start),
          if (selected == 'BAO_TRI') 'den_ngay': dateOnly(end),
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
    return RefreshIndicator(
      color: const Color(0xFF123A52),
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header trang
          Container(
            padding: const EdgeInsets.all(18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB58A45).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cleaning_services_outlined,
                        color: Color(0xFFB58A45),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tình trạng phòng',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF123A52),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vệ sinh không thay thế khả dụng theo ngày. Bảo trì phải có lịch và không được giao đặt phòng.',
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Khu vực Bộ lọc gom vào Card gọn gàng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: floor,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Lọc tầng',
                    prefixIcon: const Icon(Icons.layers_outlined),
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
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(status),
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Tình trạng vận hành',
                    prefixIcon: const Icon(Icons.tune_rounded),
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
                    ...TttpStrings.operationNames.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          status = v;
                          load();
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(type),
                  initialValue: type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Loại phòng',
                    prefixIcon: const Icon(Icons.king_bed_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả loại phòng'),
                    ),
                    ...types.map(
                      (t) => DropdownMenuItem(
                        value: t['ma_lp'] as int,
                        child: Text(t['ten_loai'] as String),
                      ),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          setState(() => type = v);
                          load();
                        },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              floor.clear();
                              status = null;
                              type = null;
                            });
                            load();
                          },
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Xóa bộ lọc'),
                  ),
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
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Không có phòng phù hợp.',
                style: TextStyle(
                  color: Color(0xFF5C6875),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Danh sách thẻ phòng
          ...items.map((room) {
            final opCode = room['tinh_trang_van_hanh'] as String?;
            final opColor = _operationColor(opCode);
            final bookings = room['lich_dat'] as List;
            final closures = room['lich_tam_ngung'] as List;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 14),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: opColor.withValues(alpha: 0.28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng ${room['so_phong']} · ${room['ten_loai']}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: const Color(0xFF152536),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tầng ${room['tang'] ?? '—'}',
                                style: const TextStyle(
                                  color: Color(0xFF5C6875),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          backgroundColor: opColor.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: opColor.withValues(alpha: 0.3),
                          ),
                          labelStyle: TextStyle(
                            color: opColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          label: Text(
                            TttpStrings.operationNames[opCode] ?? 'Sẵn sàng',
                          ),
                        ),
                      ],
                    ),
                    if (room['trang_thai_su_dung'] == 'DANG_SU_DUNG')
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(label: Text('Đang sử dụng')),
                      ),
                    if (room['trang_thai_su_dung'] == 'DA_DAT_TRUOC')
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(label: Text('Đã đặt trước')),
                      ),
                    if (bookings.isNotEmpty || closures.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...bookings.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available_outlined,
                                      size: 15,
                                      color: Color(0xFF123A52),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Đặt phòng: ${localDate(b['ngay_nhan'] as String)} → ${localDate(b['ngay_tra'] as String)} · ${statuses[b['trang_thai']]}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF152536),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...closures.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_busy_outlined,
                                      size: 15,
                                      color: Color(0xFFB42318),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Tạm ngừng: ${localDate(b['tu_ngay'] as String)} → ${localDate(b['den_ngay'] as String)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFB42318),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF123A52),
                          side: const BorderSide(color: Color(0xFF123A52)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: busy ? null : () => change(room),
                        child: const Text(
                          'Cập nhật tình trạng',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../widgets/image_crop.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class RoomImagesScreen extends StatefulWidget {
  final int? typeId, roomId;
  const RoomImagesScreen({super.key, this.typeId, this.roomId});
  @override
  State<RoomImagesScreen> createState() => _RoomImagesScreenState();
}

class _RoomImagesScreenState extends State<RoomImagesScreen> {
  List<Json> amenities = [], images = [];
  Set<int> selected = {};
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<List<Json>> all(String path) async {
    final api = context.read<ApiService>();
    final rows = <Json>[];
    int page = 1, total = 1;
    while (rows.length < total) {
      final result = await api.request(
        'GET',
        path,
        query: {'page': page++, 'page_size': 100},
      ) as Json;
      rows.addAll((result['items'] as List).cast<Json>());
      total = result['total'] as int;
    }
    return rows;
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = await Future.wait([
        all(widget.roomId == null ? '/staff/room-types' : '/staff/rooms'),
        all('/staff/amenities'),
      ]);
      final type = values[0].firstWhere(
        (e) => widget.roomId == null
            ? e['ma_lp'] == widget.typeId
            : e['ma_phong'] == widget.roomId,
      );
      if (mounted) {
        setState(() {
          amenities = values[1];
          images = (type['hinh_anh'] as List? ?? []).cast<Json>();
          selected = (type['tien_nghi'] as List)
              .map((e) => e['ma_tn'] as int)
              .toSet();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> mutate(Future<void> Function(ApiService) operation) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await operation(context.read<ApiService>());
      if (mounted) await load();
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          widget.roomId == null ? 'Tiện nghi loại phòng' : 'Ảnh phòng',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
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
            const SizedBox(height: 8),
            ErrorPanel(error!, load),
          ],
          const SizedBox(height: 8),
          if (widget.roomId == null)
            Container(
              padding: const EdgeInsets.all(18),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB58A45)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFFB58A45),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tiện nghi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF123A52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...amenities.map(
                    (a) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF123A52),
                      title: Text(
                        a['ten_tien_nghi'] as String,
                        style: const TextStyle(
                          color: Color(0xFF152536),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: selected.contains(a['ma_tn']),
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              if (v == true) {
                                selected.add(a['ma_tn'] as int);
                              } else {
                                selected.remove(a['ma_tn']);
                              }
                            }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF123A52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: busy
                          ? null
                          : () => mutate((api) async {
                              await api.request(
                                'PUT',
                                '/staff/room-types/${widget.typeId}/amenities',
                                body: {'ma_tn': selected.toList()},
                              );
                            }),
                      child: const Text(
                        'Lưu tiện nghi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.roomId != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF123A52).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF123A52),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ảnh phòng',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF123A52),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF123A52),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF123A52)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final bytes = await chooseCroppedImage(context);
                        if (bytes == null || !mounted) return;
                        await mutate((api) async {
                          await api.upload(
                            '/staff/rooms/${widget.roomId}/images',
                            bytes,
                            'room.png',
                          );
                        });
                      },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text(
                  'Chọn ảnh JPEG / PNG / WebP',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...images.map(
              (i) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: (i['la_anh_bia'] as bool)
                        ? const Color(0xFFB58A45)
                        : const Color(0xFFE2E8F0),
                    width: (i['la_anh_bia'] as bool) ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    RoomPhoto(i['duong_dan'] as String),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFFB58A45),
                      title: const Text(
                        'Ảnh bìa',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF152536),
                        ),
                      ),
                      value: i['la_anh_bia'] as bool,
                      onChanged: busy
                          ? null
                          : (v) => mutate((api) async {
                              await api.request(
                                'PATCH',
                                '/staff/images/${i['ma_anh']}',
                                body: {'la_anh_bia': v},
                              );
                            }),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: const Color(0xFFF5F7FA),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thứ tự: ${i['thu_tu']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C6875),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Đưa lên trước',
                                onPressed: busy || (i['thu_tu'] as int) == 0
                                    ? null
                                    : () => mutate((api) async {
                                        await api.request(
                                          'PATCH',
                                          '/staff/images/${i['ma_anh']}',
                                          body: {
                                            'thu_tu': (i['thu_tu'] as int) - 1,
                                          },
                                        );
                                      }),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: 'Đưa xuống sau',
                                onPressed: busy
                                    ? null
                                    : () => mutate((api) async {
                                        await api.request(
                                          'PATCH',
                                          '/staff/images/${i['ma_anh']}',
                                          body: {
                                            'thu_tu': (i['thu_tu'] as int) + 1,
                                          },
                                        );
                                      }),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                tooltip: 'Xóa ảnh',
                                color: const Color(0xFFB42318),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final yes = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            surfaceTintColor:
                                                Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: const Text('Xóa ảnh này?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, false),
                                                child: const Text('Giữ lại'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFB42318,
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(c, true),
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (yes == true && mounted) {
                                          await mutate((api) async {
                                            await api.request(
                                              'DELETE',
                                              '/staff/images/${i['ma_anh']}',
                                            );
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

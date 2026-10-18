import '../../core/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class ReviewEditor extends StatefulWidget {
  final String bookingId;
  const ReviewEditor({super.key, required this.bookingId});
  @override
  State<ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<ReviewEditor> {
  int stars = 0;
  bool busy = false;
  final comment = TextEditingController();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đánh giá kỳ lưu trú')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Bạn đánh giá trải nghiệm phòng thế nào?'),
        Wrap(
          children: [
            for (int i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i sao',
                onPressed: busy ? null : () => setState(() => stars = i),
                icon: Icon(
                  i <= stars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFB58A45),
                  size: 36,
                ),
              ),
          ],
        ),
        Text(stars == 0 ? 'Chọn từ 1 đến 5 sao' : '$stars / 5 sao'),
        TextField(
          controller: comment,
          maxLength: 1000,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Nhận xét (tùy chọn)'),
        ),
        const Text(
          'Chỉ gửi một đánh giá cho mỗi lần lưu trú. Vui lòng không đưa thông tin riêng tư vào nhận xét.',
        ),
        FilledButton(
          onPressed: busy || stars == 0
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await context.read<ApiService>().request(
                      'POST',
                      '/bookings/${widget.bookingId}/review',
                      body: {'so_sao': stars, 'nhan_xet': comment.text.trim()},
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) message(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Đang gửi…' : 'Gửi đánh giá'),
        ),
      ],
    ),
  );
}

class BookingReviewTile extends StatefulWidget {
  final String bookingId;
  const BookingReviewTile({super.key, required this.bookingId});
  @override
  State<BookingReviewTile> createState() => _BookingReviewTileState();
}

class _BookingReviewTileState extends State<BookingReviewTile> {
  Json? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/bookings/${widget.bookingId}/review',
      ) as Json;
      if (mounted) {
        setState(() {
          data = d;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorPanel(error!, load);
    if (data == null) return const LinearProgressIndicator();
    final r = data!['review'];
    if (r != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.star, color: Color(0xFFB58A45)),
          title: Text('Đánh giá của bạn: ${r['so_sao']}/5'),
          subtitle: Text(
            '${r['nhan_xet'] ?? ''}${r['hien_thi'] == false ? '\nĐang ẩn${(r['ly_do_an'] ?? '').isEmpty ? '' : ': ${r['ly_do_an']}'}' : ''}',
          ),
        ),
      );
    }
    return data!['can_review'] == true
        ? OutlinedButton.icon(
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Đánh giá phòng'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => ReviewEditor(bookingId: widget.bookingId),
                ),
              );
              if (mounted) load();
            },
          )
        : const SizedBox.shrink();
  }
}

class ReviewsScreen extends StatefulWidget {
  final int? roomId;
  final bool admin;
  const ReviewsScreen({super.key, this.roomId, this.admin = false});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  Json? data;
  String? error;
  int page = 1;
  int? stars;
  String sort = 'newest';
  bool? visible;
  final roomFilter = TextEditingController(),
      typeFilter = TextEditingController();
  DateTimeRange? dates;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    roomFilter.dispose();
    typeFilter.dispose();
    super.dispose();
  }

  String get path => widget.admin
      ? '/admin/reviews'
      : widget.roomId != null
      ? '/rooms/${widget.roomId}/reviews'
      : '/users/me/reviews';
  Future<void> load() async {
    setState(() {
      data = null;
      error = null;
    });
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        path,
        query: {
          'page': page,
          'page_size': 10,
          if (stars != null) widget.admin ? 'so_sao' : 'stars': stars,
          if (widget.roomId != null) 'sort': sort,
          if (widget.admin && visible != null) 'hien_thi': visible,
          if (widget.admin && int.tryParse(roomFilter.text) != null)
            'ma_phong': int.parse(roomFilter.text),
          if (widget.admin && int.tryParse(typeFilter.text) != null)
            'ma_lp': int.parse(typeFilter.text),
          if (widget.admin && dates != null) ...{
            'tu_ngay': dates!.start.toIso8601String().substring(0, 10),
            'den_ngay': dates!.end.toIso8601String().substring(0, 10),
          },
        },
      ) as Json;
      if (mounted) setState(() => data = d);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> moderate(Json r) async {
    final reason = TextEditingController();
    final ok = await formDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(r['hien_thi'] == true ? 'Ẩn đánh giá' : 'Hiện đánh giá'),
        content: TextField(
          controller: reason,
          maxLength: 2000,
          decoration: const InputDecoration(labelText: 'Lý do (tùy chọn)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true || !mounted) return;
    try {
      await context.read<ApiService>().request(
        'PATCH',
        '/admin/reviews/${r['id']}/visibility',
        body: {'hien_thi': r['hien_thi'] != true, 'ly_do': text},
      );
      if (mounted) load();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.admin
            ? 'Quản lý đánh giá'
            : widget.roomId == null
            ? 'Đánh giá của tôi'
            : 'Đánh giá phòng',
      ),
    ),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.roomId != null || widget.admin)
            Wrap(
              spacing: 8,
              children: [
                DropdownButton<int>(
                  value: stars,
                  hint: const Text('Tất cả sao'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả sao'),
                    ),
                    for (int i = 1; i <= 5; i++)
                      DropdownMenuItem(value: i, child: Text('$i sao')),
                  ],
                  onChanged: (v) {
                    stars = v;
                    page = 1;
                    load();
                  },
                ),
                if (widget.roomId != null)
                  DropdownButton<String>(
                    value: sort,
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Mới nhất'),
                      ),
                      DropdownMenuItem(
                        value: 'highest',
                        child: Text('Điểm cao'),
                      ),
                      DropdownMenuItem(
                        value: 'lowest',
                        child: Text('Điểm thấp'),
                      ),
                    ],
                    onChanged: (v) {
                      sort = v!;
                      page = 1;
                      load();
                    },
                  ),
                if (widget.admin)
                  DropdownButton<bool>(
                    value: visible,
                    hint: const Text('Mọi trạng thái'),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: null,
                        child: Text('Mọi trạng thái'),
                      ),
                      DropdownMenuItem(value: true, child: Text('Đang hiện')),
                      DropdownMenuItem(value: false, child: Text('Đang ẩn')),
                    ],
                    onChanged: (v) {
                      visible = v;
                      page = 1;
                      load();
                    },
                  ),
              ],
            ),
          if (widget.admin) ...[
            TextField(
              controller: roomFilter,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mã phòng (tùy chọn)',
              ),
            ),
            TextField(
              controller: typeFilter,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mã loại phòng (tùy chọn)',
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final d = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  dates = d;
                  page = 1;
                  load();
                }
              },
              child: const Text('Lọc ngày đánh giá'),
            ),
            TextButton(
              onPressed: () {
                dates = null;
                roomFilter.clear();
                typeFilter.clear();
                stars = null;
                visible = null;
                page = 1;
                load();
              },
              child: const Text('Xóa bộ lọc'),
            ),
            FilledButton(
              onPressed: () {
                page = 1;
                load();
              },
              child: const Text('Áp dụng bộ lọc'),
            ),
          ],
          if (error != null) ErrorPanel(error!, load),
          if (data == null && error == null) const LinearProgressIndicator(),
          if (data != null) ...[
            if (widget.roomId != null) ...[
              Text(
                data!['so_danh_gia'] == 0
                    ? 'Chưa có đánh giá'
                    : '${data!['diem_trung_binh']}/5 • ${data!['so_danh_gia']} lượt đánh giá',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (int i = 5; i >= 1; i--)
                Text('$i sao: ${data!['phan_bo']?['$i'] ?? 0}'),
            ],
            if ((data!['items'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có đánh giá phù hợp'),
              ),
            for (final raw in data!['items'] as List)
              Builder(
                builder: (c) {
                  final r = raw as Json;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: r['avatar_url'] != null
                                    ? NetworkImage(
                                        c.read<ApiService>().imageUrl(
                                          r['avatar_url'],
                                        ),
                                      )
                                    : null,
                                child: r['avatar_url'] == null
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${r['ten_hien_thi']} • ${r['so_sao']}/5',
                                ),
                              ),
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                              ),
                            ],
                          ),
                          Text(
                            'Khách đã lưu trú • ${vietnamTime(r['ngay_tao'])} (giờ Việt Nam)',
                          ),
                          if (r['so_phong'] != null)
                            Text(
                              'Phòng ${r['so_phong']} • ${r['ngay_nhan']} – ${r['ngay_tra']}',
                            ),
                          if ((r['nhan_xet'] ?? '').isNotEmpty)
                            Text(r['nhan_xet']),
                          if (r['hien_thi'] == false)
                            Text(
                              'Đang ẩn${(r['ly_do_an'] ?? '').isEmpty ? '' : ': ${r['ly_do_an']}'}',
                            ),
                          if (widget.admin)
                            TextButton(
                              onPressed: () => moderate(r),
                              child: Text(
                                r['hien_thi'] == true
                                    ? 'Ẩn đánh giá'
                                    : 'Hiện lại đánh giá',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: page > 1
                      ? () {
                          page--;
                          load();
                        }
                      : null,
                  child: const Text('Trước'),
                ),
                Text('Trang $page'),
                TextButton(
                  onPressed: page * 10 < (data!['total'] as int)
                      ? () {
                          page++;
                          load();
                        }
                      : null,
                  child: const Text('Sau'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

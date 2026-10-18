import '../shared/reviews_screen.dart';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';

import 'booking_review_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final String start, end;
  final int guests;
  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.start,
    required this.end,
    required this.guests,
  });
  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Room room = widget.room;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await context.read<ApiService>().request(
        'GET',
        '/rooms/${room.id}',
      ) as Json;
      if (mounted) setState(() => room = Room.fromJson(result));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = DateTime.parse(widget.end)
        .difference(DateTime.parse(widget.start))
        .inDays;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Đánh giá phòng',
            icon: const Icon(Icons.star_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ReviewsScreen(roomId: room.id),
              ),
            ),
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF123A52),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Phòng ${room.number}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF123A52).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Giá tạm tính',
                    style: TextStyle(
                      color: Color(0xFF5C6875),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${money(room.price * nights)} dự kiến',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123A52),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${money(room.price)} / đêm',
                  style: const TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF123A52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: loading || error != null
                      ? null
                      : () async {
                          final session = context.read<SessionProvider>();
                          if (session.user == null) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                            if (!context.mounted || session.user == null) {
                              return;
                            }
                          }
                          if (session.staff) {
                            if (context.mounted) {
                              message(
                                context,
                                'Hãy sử dụng tài khoản khách hàng để đặt phòng',
                              );
                            }
                            return;
                          }
                          if (!context.mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => BookingReviewScreen(
                                room: room,
                                start: widget.start,
                                end: widget.end,
                                guests: widget.guests,
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    'Tiếp tục đặt phòng',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (loading)
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
          Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF123A52).withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: room.images.isEmpty
                  ? const RoomPhoto(null, height: 230)
                  : PageView(
                      children: room.images
                          .map(
                            (i) => GestureDetector(
                              onTap: () => showImageViewer(
                                context,
                                NetworkImage(
                                  context.read<ApiService>().imageUrl(
                                    i['duong_dan'] as String,
                                  ),
                                ),
                                swipeDismissible: true,
                                doubleTapZoomable: true,
                              ),
                              child: RoomPhoto(
                                i['duong_dan'] as String,
                                height: 230,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.inUse ? '${room.type} · Đang sử dụng' : room.type,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF123A52),
                    fontSize: 22,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReviewsScreen(roomId: room.id),
                    ),
                  ),
                  icon: const Icon(Icons.star_outline),
                  label: Text(
                    (room.rating['so_danh_gia'] ?? 0) == 0
                        ? 'Chưa có đánh giá • Xem đánh giá'
                        : '${room.rating['diem_trung_binh']}/5 • ${room.rating['so_danh_gia']} đánh giá',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  room.description,
                  style: const TextStyle(
                    color: Color(0xFF5C6875),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 18,
                      color: Color(0xFFB58A45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sức chứa: ${room.capacity} khách',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152536),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: Color(0xFFB58A45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${money(room.price)} / đêm',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF123A52),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (room.amenities.isNotEmpty) ...[
            Text(
              'Tiện nghi phòng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF123A52),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: room.amenities
                  .map(
                    (a) => Chip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      labelStyle: const TextStyle(
                        color: Color(0xFF152536),
                        fontWeight: FontWeight.w500,
                      ),
                      label: Text(a['ten_tien_nghi'] as String),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF123A52).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFF123A52),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${localDate(widget.start)} → ${localDate(widget.end)} • ${widget.guests} khách',
                    style: const TextStyle(
                      color: Color(0xFF123A52),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

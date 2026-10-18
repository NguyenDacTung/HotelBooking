import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/session_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../repositories/hotel_repository.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';
import 'my_bookings_screen.dart';

import 'booking_success_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final Room room;
  final String start, end;
  final int guests;
  const BookingReviewScreen({
    super.key,
    required this.room,
    required this.start,
    required this.end,
    required this.guests,
  });
  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, phone;
  final note = TextEditingController();
  late String start = widget.start, end = widget.end;
  late int guests = widget.guests;
  Json? quote;
  String? error;
  bool busy = false, quoting = true, uncertain = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionProvider>().user;
    name = TextEditingController(text: user?['ho_ten'] as String? ?? '');
    phone = TextEditingController(
      text: user?['so_dien_thoai'] as String? ?? '',
    );
    loadQuote();
  }

  @override
  void dispose() {
    note.dispose();
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> loadQuote() async {
    setState(() {
      quoting = true;
      error = null;
    });
    try {
      final result = await context.read<ApiService>().request(
        'POST',
        '/rooms/${widget.room.id}/quote',
        body: {'ngay_nhan': start, 'ngay_tra': end, 'so_khach': guests},
      ) as Json;
      if (mounted) setState(() => quote = result);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => quoting = false);
    }
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await context.read<HotelRepository>().book(
        BookingRequest(
          roomId: widget.room.id,
          guests: guests,
          start: start,
          end: end,
          name: name.text,
          phone: phone.text,
          expectedPrice: (quote!['don_gia_moi_dem'] as num).toInt(),
          note: note.text,
        ),
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => BookingSuccessScreen(booking: result),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          if (e is ApiError &&
              e.code == 'PRICE_CHANGED' &&
              e.details is Map &&
              quote != null) {
            quote = {...quote!, ...Map<String, dynamic>.from(e.details as Map)};
          }
          uncertain = e is ApiError && e.status == null;
        });
      }
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
        title: const Text(
          'Xác nhận đặt phòng',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF123A52).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RoomPhoto(
                  widget.room.images.isEmpty
                      ? null
                      : widget.room.images.first['duong_dan'] as String,
                  height: 130,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.room.type} • Phòng ${widget.room.number}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF123A52),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${localDate(start)} → ${localDate(end)} • $guests khách',
                    style: const TextStyle(
                      color: Color(0xFF5C6875),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF123A52),
                      side: const BorderSide(color: Color(0xFF123A52)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: busy || uncertain
                        ? null
                        : () async {
                            final now = DateTime.now().toUtc().add(
                              const Duration(hours: 7),
                            );
                            final first = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: first,
                              lastDate: first.add(const Duration(days: 730)),
                              initialDateRange: DateTimeRange(
                                start: DateTime.parse(start),
                                end: DateTime.parse(end),
                              ),
                            );
                            if (range == null || !context.mounted) return;
                            if (range.duration.inDays < 1 ||
                                range.duration.inDays > 30) {
                              message(context, 'Chọn từ 1 đến 30 đêm');
                              return;
                            }
                            setState(() {
                              start = dateOnly(range.start);
                              end = dateOnly(range.end);
                              quote = null;
                            });
                            await loadQuote();
                          },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Đổi ngày lưu trú'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: guests,
              decoration: InputDecoration(
                labelText: 'Số khách',
                prefixIcon: const Icon(Icons.group_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: [
                for (int i = 1; i <= widget.room.capacity; i++)
                  DropdownMenuItem(value: i, child: Text('$i khách')),
              ],
              onChanged: busy || quoting || uncertain
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        guests = v;
                        quote = null;
                      });
                      loadQuote();
                    },
            ),
            if (quoting) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFFB58A45),
                ),
              ),
            ],
            if (quote != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nhận phòng từ ${(quote!['chinh_sach'] as Map?)?['checkin_hour'] ?? 14}:00; trả phòng trước ${(quote!['chinh_sach'] as Map?)?['checkout_hour'] ?? 12}:00 (giờ Việt Nam). '
                    'Nhận sớm trước 06:00: 100%, trước giờ nhận: 50% giá một đêm. Trả muộn đến 15:00: 30%, đến 18:00: 50%, sau 18:00: 100%; quá ngày tính thêm đêm. '
                    'Giường phụ: ${money((quote!['chinh_sach'] as Map?)?['extra_bed_price'] as num? ?? 250000)}/đêm, tối đa một giường, cần xác nhận với lễ tân. '
                    'Đơn chờ xác nhận giữ chỗ tối đa ${(quote!['chinh_sach'] as Map?)?['hold_hours'] ?? 24} giờ, không quá cuối ngày đến. Hủy đơn đã xác nhận trong 24 giờ trước giờ nhận hoặc khách không đến: phí một đêm. '
                    'Minibar, giặt là và khoản phát sinh được đối chiếu theo sử dụng thực tế.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF123A52).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF123A52).withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quote!['so_dem']} đêm × ${money(quote!['don_gia_moi_dem'] as num)}',
                      style: const TextStyle(
                        color: Color(0xFF5C6875),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dự kiến: ${money(quote!['tong_tien'] as num)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF123A52),
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Báo giá không giữ phòng. Nếu giá thay đổi, bạn sẽ được yêu cầu xác nhận lại.',
                      style: TextStyle(
                        color: Color(0xFF5C6875),
                        fontSize: 12.5,
                      ),
                    ),
                    if (quote!['kha_dung'] != true) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Phòng không còn khả dụng.',
                        style: TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Có thể hủy trước 00:00 ngày nhận phòng, theo giờ Việt Nam.',
                style: TextStyle(color: Color(0xFF5C6875), fontSize: 13),
              ),
            ),
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
                children: [
                  TextFormField(
                    controller: note,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú (tùy chọn)',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: name,
                    maxLength: 120,
                    validator: requiredText,
                    decoration: InputDecoration(
                      labelText: 'Tên liên hệ',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    maxLength: 20,
                    validator: phoneText,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Điện thoại liên hệ',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
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
            ],
            const SizedBox(height: 20),
            if (uncertain) ...[
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider(
                      create: (c) => BookingProvider(c.read<HotelRepository>()),
                      child: const Scaffold(
                        body: SafeArea(child: MyBookingsScreen()),
                      ),
                    ),
                  ),
                ),
                child: const Text('Kiểm tra Đặt phòng của tôi'),
              ),
              const SizedBox(height: 12),
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
                onPressed:
                    busy || quoting || uncertain || quote?['kha_dung'] != true
                    ? null
                    : submit,
                child: Text(
                  busy ? 'Đang gửi…' : 'Xác nhận đặt phòng',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (!busy && !uncertain)
              TextButton(
                onPressed: loadQuote,
                child: const Text('Cập nhật báo giá'),
              ),
          ],
        ),
      ),
    );
  }
}

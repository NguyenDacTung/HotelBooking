import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../core/config.dart';
import '../../core/strings.dart';
import 'booking_detail_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Booking booking;
  const BookingSuccessScreen({super.key, required this.booking});

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
          'Đã gửi yêu cầu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: 76,
              color: Color(0xFF237A57),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            TttpStrings.sent,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF123A52),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    'Mã đặt phòng: ${booking.id}',
                    style: const TextStyle(
                      color: Color(0xFF5C6875),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    backgroundColor:
                        const Color(0xFFB58A45).withValues(alpha: 0.14),
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      color: Color(0xFFB58A45),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    label: Text(statuses[booking.status] ?? 'Chờ xác nhận'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phòng ${booking.number}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152536),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${localDate(booking.data['ngay_nhan'] as String)} → ${localDate(booking.data['ngay_tra'] as String)}',
                    style: const TextStyle(color: Color(0xFF5C6875)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    'Giá chốt: ${money(booking.total)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF123A52),
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123A52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BookingDetailScreen(id: booking.id),
                ),
              ),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF152536),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text(
                'Về trang chủ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
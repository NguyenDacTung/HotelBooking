import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';

/// Offline visual preview only. No token, API, booking, or database simulation.
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

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
          'An Nhiên • DEMO NGOẠI TUYẾN',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: const Color(0xFFB58A45).withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFFB58A45).withValues(alpha: 0.4),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB58A45),
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DỮ LIỆU MẪU • Chỉ xem giao diện, không gửi đặt phòng. Chạy lại không có DEMO_MODE để dùng API thật.',
                      style: TextStyle(
                        color: Color(0xFF152536),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Một kỳ nghỉ thật an yên',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF123A52),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn phòng phù hợp với kỳ nghỉ của bạn.',
            style: TextStyle(color: Color(0xFF5C6875), fontSize: 14),
          ),
          const SizedBox(height: 20),
          for (final room in [
            ('Standard', 500000, 2),
            ('Deluxe', 850000, 2),
            ('Family', 1200000, 4),
          ])
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF123A52).withValues(alpha: 0.9),
                          const Color(0xFF1B4D6B),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bed_outlined,
                      size: 70,
                      color: Color(0xFFB58A45),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              room.$1,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF152536),
                                  ),
                            ),
                            Chip(
                              backgroundColor: const Color(0xFFB58A45)
                                  .withValues(alpha: 0.14),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                color: Color(0xFFB58A45),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              label: const Text('Phòng mẫu'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${room.$3} khách • Wi-Fi • Điều hòa',
                          style: const TextStyle(
                            color: Color(0xFF5C6875),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${money(room.$2)} / đêm',
                          style: const TextStyle(
                            color: Color(0xFF123A52),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

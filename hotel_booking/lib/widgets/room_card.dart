import 'package:flutter/material.dart';

import '../models/models.dart';
import '../core/config.dart';
import 'common.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final int nights;
  final VoidCallback onTap;
  const RoomCard({
    super.key,
    required this.room,
    required this.nights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoomPhoto(
              room.images.isEmpty
                  ? null
                  : room.images.first['duong_dan'] as String,
              height: 190,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${room.type} · Phòng ${room.number}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF123A52),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: Color(0xFF5C6875),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        room.inUse
                            ? 'Đang sử dụng'
                            : 'Tối đa ${room.capacity} khách',
                        style: const TextStyle(
                          color: Color(0xFF5C6875),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (room.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: room.amenities
                          .take(3)
                          .map(
                            (a) => Chip(
                              backgroundColor: const Color(0xFFF5F7FA),
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF152536),
                              ),
                              label: Text(a['ten_tien_nghi'] as String),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${money(room.price)} /đêm',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF123A52),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dự kiến $nights đêm: ${money(room.price * nights)}',
                            style: const TextStyle(
                              color: Color(0xFF5C6875),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Xem phòng →',
                        style: TextStyle(
                          color: Color(0xFFB58A45),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/search_provider.dart';
import '../../widgets/search_form.dart';
import '../../widgets/room_card.dart';
import '../../widgets/common.dart';
import '../../core/config.dart';
import 'room_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool editing = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SearchProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: const Color(0xFF123A52),
        onRefresh: s.search,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tìm căn phòng của bạn',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF123A52),
                        ),
                  ),
                  const SizedBox(height: 14),
                  if (editing)
                    SearchForm(
                      filters: true,
                      onSearch: () {
                        setState(() => editing = false);
                        s.search();
                      },
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      isThreeLine: true,
                      title: Text(
                        '${localDate(dateOnly(s.start))} → ${localDate(dateOnly(s.end))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF152536),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${s.criteria.nights} đêm · ${s.guests} khách',
                          style: const TextStyle(color: Color(0xFF5C6875)),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Chỉnh sửa tìm kiếm',
                        onPressed: () => setState(() => editing = true),
                        icon: const Icon(Icons.tune, color: Color(0xFFB58A45)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (s.loading)
              Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.white,
                child: Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            if (s.error != null) ...[
              const SizedBox(height: 8),
              ErrorPanel(s.error!, s.search),
            ],
            if (!s.loading && s.error == null && s.rooms.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Chọn ngày và tìm phòng. Nếu chưa có phòng phù hợp, hãy thử thời gian khác.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5C6875),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (s.rooms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${s.total} phòng phù hợp',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF123A52),
                      ),
                ),
              ),
            ...s.rooms.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RoomCard(
                  room: r,
                  nights: s.criteria.nights,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RoomDetailScreen(
                          room: r,
                          start: dateOnly(s.start),
                          end: dateOnly(s.end),
                          guests: s.guests,
                        ),
                      ),
                    );
                    if (mounted) s.search();
                  },
                ),
              ),
            ),
            if (s.rooms.length < s.total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: s.loading ? null : () => s.search(more: true),
                  child: const Text('Tải thêm phòng'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
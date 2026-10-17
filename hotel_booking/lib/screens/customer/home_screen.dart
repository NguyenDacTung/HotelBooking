import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/search_provider.dart';
import '../../widgets/search_form.dart';
import '../../widgets/recommended_rooms.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearch;
  const HomeScreen({super.key, required this.onSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool searchExpanded = false;
  final searchBoxKey = GlobalKey();

  void toggleSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => searchExpanded = !searchExpanded);
    if (searchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !searchExpanded) return;
        final target = searchBoxKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Header chào mừng được thiết kế dạng Card bo tròn hiện đại
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF123A52).withValues(alpha: 0.06),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng đến TTTP',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF123A52),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Không gian nghỉ ngơi dành cho bạn.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5C6875),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                expanded: searchExpanded,
                child: IconButton.filledTonal(
                  tooltip: searchExpanded ? 'Ẩn tìm kiếm' : 'Tìm kiếm phòng',
                  onPressed: toggleSearch,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFB58A45)
                        .withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFF123A52),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Carousel Slider Banner với hiệu ứng góc bo tròn và gradient tinh tế
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: false,
          ),
          items: ['auth-hotel', 'banner-deluxe', 'banner-family']
              .map(
                (name) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/$name.jpg',
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC123A52)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB58A45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ĐẶC QUYỀN TTTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'TTTP\nMột kỳ nghỉ trọn vẹn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),

        // Giữ nội dung đã nhập khi thu gọn hộp tìm kiếm.
        Visibility(
          visible: searchExpanded,
          maintainState: true,
          child: Card(
            key: searchBoxKey,
            elevation: 3,
            shadowColor: const Color(0xFF123A52).withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SearchForm(
                onSearch: () {
                  context.read<SearchProvider>().search();
                  widget.onSearch();
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const RecommendedRooms(),
        const SizedBox(height: 28),

        // Phần Trải nghiệm TTTP
        Text(
          'Trải nghiệm TTTP',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF123A52),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Chip(
              backgroundColor: Colors.white,
              elevation: 1,
              side: BorderSide(color: Colors.grey.shade200),
              avatar: const Icon(
                Icons.bed_outlined,
                color: Color(0xFFB58A45),
                size: 18,
              ),
              label: const Text('Phòng phù hợp nhu cầu'),
              labelStyle: const TextStyle(
                color: Color(0xFF152536),
                fontWeight: FontWeight.w500,
              ),
            ),
            Chip(
              backgroundColor: Colors.white,
              elevation: 1,
              side: BorderSide(color: Colors.grey.shade200),
              avatar: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFFB58A45),
                size: 18,
              ),
              label: const Text('Lịch trống rõ ràng'),
              labelStyle: const TextStyle(
                color: Color(0xFF152536),
                fontWeight: FontWeight.w500,
              ),
            ),
            Chip(
              backgroundColor: Colors.white,
              elevation: 1,
              side: BorderSide(color: Colors.grey.shade200),
              avatar: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFFB58A45),
                size: 18,
              ),
              label: const Text('Giá hiển thị minh bạch'),
              labelStyle: const TextStyle(
                color: Color(0xFF152536),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Hộp chú thích trực quan hơn
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF5C6875),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ảnh không gian mang tính minh họa. Giá và khả dụng được kiểm tra theo ngày bạn chọn.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6875),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Các nút hành động (Liên hệ & Bản đồ)
        if (const String.fromEnvironment('HOTEL_PHONE') != '') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri(
                  scheme: 'tel',
                  path: const String.fromEnvironment('HOTEL_PHONE'),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF123A52),
                side: const BorderSide(color: Color(0xFF123A52)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.call_outlined),
              label: const Text(
                'Liên hệ TTTP',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (const String.fromEnvironment('HOTEL_MAP_URL') != '') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(const String.fromEnvironment('HOTEL_MAP_URL')),
                mode: LaunchMode.externalApplication,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB58A45),
                side: const BorderSide(color: Color(0xFFB58A45)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text(
                'Xem vị trí TTTP',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );

    return MediaQuery.disableAnimationsOf(context)
        ? content
        : content.animate().fadeIn(duration: 250.ms);
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../models/models.dart';
import '../models/search_criteria.dart';
import '../providers/search_provider.dart';
import '../screens/customer/room_detail_screen.dart';
import '../services/api_service.dart';
import 'common.dart';

class RecommendedRooms extends StatefulWidget {
  const RecommendedRooms({super.key});
  @override
  State<RecommendedRooms> createState() => _RecommendedRoomsState();
}

class _RecommendedRoomsState extends State<RecommendedRooms>
    with WidgetsBindingObserver {
  List<Room> rooms = [];
  SearchCriteria? criteria;
  StreamSubscription<List<ConnectivityResult>>? subscription;
  Timer? timer;
  int generation = 0;
  String? criteriaKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        generation++;
        if (mounted) setState(() => rooms = []);
      } else {
        load(clear: true);
      }
    }, onError: (Object _) {});
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 45), (_) => load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.watch<SearchProvider>().criteria;
    final key = '${dateOnly(next.start)}:${dateOnly(next.end)}:${next.guests}';
    if (criteriaKey != key) {
      criteriaKey = key;
      criteria = next;
      Future.microtask(() => load(clear: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      startTimer();
      load(clear: true);
    }
  }

  Future<void> load({bool clear = false}) async {
    if (!mounted || criteria == null) return;
    final request = ++generation;
    final selected = criteria!;
    if (clear || selected.validate() != null) setState(() => rooms = []);
    if (selected.validate() != null) return;
    try {
      final data = await context.read<ApiService>().request(
        'GET',
        '/rooms/recommended',
        query: {
          'ngay_nhan': dateOnly(selected.start),
          'ngay_tra': dateOnly(selected.end),
          'so_khach': selected.guests,
          'page_size': 6,
        },
      ) as Json;
      final result = (data['items'] as List)
          .map((r) => Room.fromJson(r as Json))
          .where((r) => !r.inUse)
          .toList();
      if (mounted && request == generation) setState(() => rooms = result);
    } catch (_) {
      if (mounted && request == generation) setState(() => rooms = []);
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    final selected = criteria!;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phòng đề xuất', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${localDate(dateOnly(selected.start))} → ${localDate(dateOnly(selected.end))} · ${selected.guests} khách',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          key: const ValueKey('recommended-room-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 118 + 125 * scale,
          ),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              key: ValueKey('recommended-room-${room.id}'),
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RoomDetailScreen(
                        room: room,
                        start: dateOnly(selected.start),
                        end: dateOnly(selected.end),
                        guests: selected.guests,
                      ),
                    ),
                  );
                  if (mounted) await load(clear: true);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RoomPhoto(
                      room.images.isEmpty
                          ? null
                          : room.images.first['duong_dan'] as String,
                      height: 108,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phòng ${room.number}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF123A52),
                            ),
                          ),
                          Text(
                            room.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${money(room.price)} / đêm',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF123A52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

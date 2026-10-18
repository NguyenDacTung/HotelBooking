import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import '../../core/config.dart';
import '../customer/booking_detail_screen.dart';

class RoomCalendarScreen extends StatefulWidget {
  const RoomCalendarScreen({super.key});
  @override
  State<RoomCalendarScreen> createState() => _RoomCalendarState();
}

class _RoomCalendarState extends State<RoomCalendarScreen> {
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  final timeline = EasyDatePickerController();
  List<Json> rooms = [];
  Json? data;
  int? room;
  String? error;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    timeline.dispose();
    super.dispose();
  }

  Future<void> init() async {
    try {
      final api = context.read<ApiService>();
      final list = <Json>[];
      int page = 1, total = 1;
      while (list.length < total) {
        final d = await api.request(
          'GET',
          '/staff/rooms/status',
          query: {'page': page++, 'page_size': 100},
        ) as Json;
        list.addAll((d['items'] as List).cast<Json>());
        total = d['total'] as int;
      }
      if (!mounted) return;
      setState(() {
        rooms = list;
        room = rooms.isEmpty ? null : rooms.first['ma_phong'];
      });
      if (room != null) load();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> load() async {
    final ticket = ++generation;
    setState(() {
      data = null;
      error = null;
    });
    final from = DateTime(selected.year, selected.month, 1),
        to = DateTime(selected.year, selected.month + 1, 0);
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/staff/rooms/$room/calendar',
        query: {
          'tu_ngay': from.toIso8601String().substring(0, 10),
          'den_ngay': to.toIso8601String().substring(0, 10),
        },
      ) as Json;
      if (mounted && ticket == generation) setState(() => data = d);
    } catch (e) {
      if (mounted && ticket == generation) setState(() => error = '$e');
    }
  }

  void pick(DateTime d) {
    final monthChanged = d.month != selected.month || d.year != selected.year;
    setState(() => selected = DateUtils.dateOnly(d));
    if (monthChanged) load();
  }

  bool active(dynamic e, DateTime day) {
    final text = day.toIso8601String().substring(0, 10);
    return e['start'].toString().compareTo(text) <= 0 &&
        e['end'].toString().compareTo(text) > 0;
  }

  List<dynamic> events(DateTime day) => [
    ...data?['bookings'] ?? [],
    ...data?['closures'] ?? [],
  ].where((e) => active(e, day)).toList();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch phòng')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<int>(
          initialValue: room,
          decoration: const InputDecoration(labelText: 'Phòng'),
          items: [
            for (final r in rooms)
              DropdownMenuItem(
                value: r['ma_phong'] as int,
                child: Text('Phòng ${r['so_phong']}'),
              ),
          ],
          onChanged: (v) {
            room = v;
            load();
          },
        ),
        TableCalendar<dynamic>(
          locale: 'vi_VN',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: selected,
          selectedDayPredicate: (d) => isSameDay(d, selected),
          availableCalendarFormats: const {CalendarFormat.month: 'Tháng'},
          eventLoader: events,
          onDaySelected: (d, _) {
            pick(d);
            timeline.animateToDate(d);
          },
          onPageChanged: (d) {
            pick(d);
            timeline.animateToDate(d);
          },
        ),
        EasyDateTimeLinePicker(
          controller: timeline,
          locale: const Locale('vi'),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          focusedDate: selected,
          onDateChange: pick,
        ),
        if (error != null) ErrorPanel(error!, rooms.isEmpty ? init : load),
        if (data == null && error == null) const LinearProgressIndicator(),
        if (data != null && events(selected).isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Không có lượt giữ phòng hoặc tạm ngừng trong ngày này',
            ),
          ),
        for (final e in events(selected))
          Card(
            child: ListTile(
              leading: Icon(e['status'] == null ? Icons.block : Icons.bed),
              title: Text(
                e['status'] == null
                    ? 'Tạm ngừng'
                    : statuses[e['status']] ?? e['status'],
              ),
              subtitle: Text('${e['start']} → ${e['end']}'),
              trailing: e['status'] == null
                  ? null
                  : const Icon(Icons.chevron_right),
              onTap: e['status'] == null
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BookingDetailScreen(id: e['id']),
                        ),
                      );
                      if (mounted) await load();
                    },
            ),
          ),
        const Text(
          'Ngày trả phòng không chiếm đêm lưu trú. Trạng thái vận hành phòng vẫn cần được kiểm tra khi nhận phòng.',
        ),
      ],
    ),
  );
}

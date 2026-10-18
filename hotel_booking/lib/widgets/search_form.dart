import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../models/search_criteria.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../core/config.dart';
import 'common.dart';

class SearchForm extends StatefulWidget {
  final VoidCallback onSearch;
  final bool filters;
  const SearchForm({super.key, required this.onSearch, this.filters = false});
  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController guests, min, max;
  List<Json> types = [];
  String? error;
  String? syncedCriteria;

  @override
  void initState() {
    super.initState();
    final s = context.read<SearchProvider>();
    guests = TextEditingController(text: '${s.guests}');
    min = TextEditingController(text: s.minPrice?.toString() ?? '');
    max = TextEditingController(text: s.maxPrice?.toString() ?? '');
    if (widget.filters) loadTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.watch<SearchProvider>();
    final key = '${s.guests}:${s.minPrice}:${s.maxPrice}';
    if (syncedCriteria != key) {
      guests.text = '${s.guests}';
      min.text = s.minPrice?.toString() ?? '';
      max.text = s.maxPrice?.toString() ?? '';
      syncedCriteria = key;
    }
  }

  @override
  void dispose() {
    guests.dispose();
    min.dispose();
    max.dispose();
    super.dispose();
  }

  Future<void> loadTypes() async {
    try {
      final result = await context.read<ApiService>().request(
        'GET',
        '/room-types',
        query: {'page_size': 100},
      ) as Json;
      if (mounted) {
        setState(() => types = (result['items'] as List).cast<Json>());
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SearchProvider>();
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bạn muốn nghỉ khi nào?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF123A52),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF123A52),
              side: const BorderSide(color: Color(0xFF123A52)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.date_range_outlined,
              color: Color(0xFFB58A45),
            ),
            label: Text(
              'Nhận ${localDate(dateOnly(s.start))}  →  Trả ${localDate(dateOnly(s.end))}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            onPressed: s.loading
                ? null
                : () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateUtilsVN.today,
                      lastDate: DateUtilsVN.today.add(
                        const Duration(days: 730),
                      ),
                      initialDateRange: DateTimeRange(
                        start: s.start,
                        end: s.end,
                      ),
                    );
                    if (range != null && mounted) {
                      s.setCriteria(
                        SearchCriteria(
                          start: range.start,
                          end: range.end,
                          guests: s.guests,
                          typeId: s.typeId,
                          minPrice: s.minPrice,
                          maxPrice: s.maxPrice,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: guests,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số khách',
              prefixIcon: const Icon(Icons.people_outline),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Nhập số khách hợp lệ',
          ),
          if (widget.filters) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(s.typeId),
              initialValue: s.typeId,
              decoration: InputDecoration(
                labelText: 'Loại phòng',
                prefixIcon: const Icon(Icons.king_bed_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Tất cả loại phòng'),
                ),
                ...types.map(
                  (t) => DropdownMenuItem(
                    value: t['ma_lp'] as int,
                    child: Text(t['ten_loai'] as String),
                  ),
                ),
              ],
              onChanged: s.loading ? null : (v) => s.typeId = v,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              ErrorPanel(error!, loadTypes),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: min,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Đơn giá từ (VND/đêm)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: price,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: max,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Đơn giá đến (VND/đêm)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: price,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: s.loading
                    ? null
                    : () {
                        min.clear();
                        max.clear();
                        s.setCriteria(
                          SearchCriteria(
                            start: s.start,
                            end: s.end,
                            guests: s.guests,
                          ),
                        );
                        setState(() {});
                      },
                child: const Text('Xóa bộ lọc'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123A52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: s.loading
                  ? null
                  : () {
                      if (!form.currentState!.validate()) return;
                      s.guests = int.parse(guests.text);
                      if (widget.filters) {
                        s.minPrice = int.tryParse(min.text);
                        s.maxPrice = int.tryParse(max.text);
                      }
                      final error = s.criteria.validate();
                      if (error != null) {
                        message(context, error);
                        return;
                      }
                      widget.onSearch();
                    },
              icon: const Icon(Icons.search),
              label: const Text(
                'Tìm phòng',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? price(String? v) =>
      v == null || v.isEmpty || (int.tryParse(v) != null && int.parse(v) >= 0)
      ? null
      : 'Nhập số nguyên không âm';
}

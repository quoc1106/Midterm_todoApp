/// File: date_selector_widget.dart
/// Purpose: Hiển thị thanh chọn ngày (selector) cho view Upcoming.
/// - Cho phép chọn ngày trong tuần, chuyển tuần, chọn Today, hoặc chọn ngày bất kỳ bằng calendar.
/// Sử dụng trong màn hình Upcoming để lọc task theo ngày.
/// Team: Đọc phần này để hiểu logic chọn ngày và filter task theo ngày.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';

class DateSelectorWidget extends ConsumerWidget {
  const DateSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(upcomingWeekStartProvider);
    final selectedUpcomingDate = ref.watch(upcomingSelectedDateProvider);
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    final allOption = DateTime(9999, 1, 1);
    final daysWithAll = [allOption, ...days];

    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: daysWithAll.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = daysWithAll[i];
                final isAll = day.year == 9999;
                final isSelected =
                    day.year == selectedUpcomingDate.year &&
                    day.month == selectedUpcomingDate.month &&
                    day.day == selectedUpcomingDate.day;
                final weekdayStr = isAll
                    ? 'All'
                    : [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][day.weekday - 1];
                return GestureDetector(
                  onTap: () {
                    ref.read(upcomingSelectedDateProvider.notifier).state = day;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayStr,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (!isAll)
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              clipBehavior: Clip.hardEdge,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Tuần trước',
                onPressed: () {
                  final currentWeekStart = ref.read(upcomingWeekStartProvider);
                  ref.read(upcomingWeekStartProvider.notifier).state =
                      currentWeekStart.subtract(const Duration(days: 7));
                },
              ),
              TextButton(
                child: const Text('Today'),
                onPressed: () {
                  final now = DateTime.now();
                  final monday = now.subtract(Duration(days: now.weekday - 1));
                  ref.read(upcomingWeekStartProvider.notifier).state = monday;
                  ref.read(upcomingSelectedDateProvider.notifier).state = now;
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Tuần sau',
                onPressed: () {
                  final currentWeekStart = ref.read(upcomingWeekStartProvider);
                  ref.read(upcomingWeekStartProvider.notifier).state =
                      currentWeekStart.add(const Duration(days: 7));
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final initialDate = selectedUpcomingDate.year == 9999
                      ? now
                      : selectedUpcomingDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    final monday = picked.subtract(
                      Duration(days: picked.weekday - 1),
                    );
                    ref.read(upcomingWeekStartProvider.notifier).state = monday;
                    ref.read(upcomingSelectedDateProvider.notifier).state =
                        picked;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

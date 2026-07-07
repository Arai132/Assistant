import 'package:flutter/material.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final Map<DateTime, List<Color>> dotsByDay;

  const MonthGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
    this.dotsByDay = const {},
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: startOffset + daysInMonth,
      itemBuilder: (ctx, index) {
        if (index < startOffset) return const SizedBox();
        final day = DateTime(month.year, month.month, index - startOffset + 1);
        final isSelected = day.year == selectedDay.year &&
            day.month == selectedDay.month &&
            day.day == selectedDay.day;
        final dots = dotsByDay[DateTime(day.year, day.month, day.day)] ?? [];
        return GestureDetector(
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(color: Theme.of(ctx).colorScheme.primary, shape: BoxShape.circle)
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                if (dots.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dots
                        .take(3)
                        .map((c) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

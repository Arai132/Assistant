import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'widgets/month_grid.dart';
import 'widgets/day_detail_panel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM().format(_month)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() =>
              _month = DateTime(_month.year, _month.month - 1)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month + 1)),
          ),
        ],
      ),
      body: Column(
        children: [
          MonthGrid(
            month: _month,
            selectedDay: _selected,
            onDaySelected: (d) => setState(() => _selected = d),
          ),
          const Divider(),
          Expanded(child: DayDetailPanel(date: _selected)),
        ],
      ),
    );
  }
}

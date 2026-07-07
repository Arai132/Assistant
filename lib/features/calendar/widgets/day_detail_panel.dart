import 'package:drift/drift.dart' show TypedResult;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';

class DayDetailPanel extends ConsumerWidget {
  final DateTime date;
  const DayDetailPanel({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<TypedResult>>(
      future: ref.read(databaseProvider).tasksDao.getTasksDueOn(date),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No tasks on ${DateFormat.MMMd().format(date)}',
                style: const TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final item = tasks[i].readTable(ref.read(databaseProvider).items);
            final task = tasks[i].readTable(ref.read(databaseProvider).tasks);
            final color = {
              TaskPriority.high: Colors.red,
              TaskPriority.medium: Colors.orange,
              TaskPriority.low: Colors.teal,
            }[task.priority]!;
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, radius: 6),
              title: Text(item.title),
              onTap: () => context.push('/tasks/${item.id}'),
            );
          },
        );
      },
    );
  }
}

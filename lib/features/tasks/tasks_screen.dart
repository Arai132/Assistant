import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/item_provider.dart';
import 'widgets/kanban_lane.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final high = ref.watch(highPriorityTasksProvider);
    final medium = ref.watch(mediumPriorityTasksProvider);
    final low = ref.watch(lowPriorityTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KanbanLane(
            label: 'High',
            priority: TaskPriority.high,
            color: Colors.red,
            rows: high.valueOrNull ?? [],
          ),
          KanbanLane(
            label: 'Medium',
            priority: TaskPriority.medium,
            color: Colors.orange,
            rows: medium.valueOrNull ?? [],
          ),
          KanbanLane(
            label: 'Low',
            priority: TaskPriority.low,
            color: Colors.teal,
            rows: low.valueOrNull ?? [],
          ),
        ],
      ),
    );
  }
}

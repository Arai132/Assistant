import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';
import 'task_card.dart';

class KanbanLane extends ConsumerWidget {
  final String label;
  final TaskPriority priority;
  final Color color;
  final List<TypedResult> rows;

  const KanbanLane({
    super.key,
    required this.label,
    required this.priority,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: color.withOpacity(0.15),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                final db = ref.read(databaseProvider);
                db.tasksDao.updateTaskPriority(details.data, priority);
              },
              builder: (context, candidate, rejected) => ListView.builder(
                padding: const EdgeInsets.only(top: 4),
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final db = ref.read(databaseProvider);
                  final item = rows[i].readTable(db.items);
                  final task = rows[i].readTable(db.tasks);
                  return Draggable<String>(
                    data: item.id,
                    feedback: Material(
                      elevation: 4,
                      child: SizedBox(
                        width: 160,
                        child: TaskCard(item: item, task: task, onTap: () {}),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: TaskCard(item: item, task: task, onTap: () {}),
                    ),
                    child: TaskCard(
                      item: item,
                      task: task,
                      onTap: () => context.push('/tasks/${item.id}'),
                      onStatusChange: (v) {
                        db.tasksDao.updateTaskStatus(
                          item.id,
                          v == true ? TaskStatus.done : TaskStatus.todo,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

class TaskCard extends StatelessWidget {
  final Item item;
  final TaskRow task;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onStatusChange;
  final bool isPendingSync;

  const TaskCard({
    super.key,
    required this.item,
    required this.task,
    required this.onTap,
    this.onStatusChange,
    this.isPendingSync = false,
  });

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: onStatusChange,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        _dateFmt.format(task.dueDate!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (isPendingSync)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                    semanticLabel: 'Pending sync',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../shared/attachment_section.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  TaskRow? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final item = await db.itemsDao.getItemById(widget.taskId);
    final taskRow = item == null
        ? null
        : await (db.select(db.tasks)..where((t) => t.id.equals(widget.taskId))).getSingleOrNull();
    if (mounted) {
      setState(() {
        _task = taskRow;
        _titleCtrl.text = item?.title ?? '';
        _bodyCtrl.text = item?.body ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveTitle() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    await ref.read(databaseProvider).itemsDao.updateItemTitle(widget.taskId, title);
  }

  Future<void> _saveBody() async {
    await ref.read(databaseProvider).itemsDao.updateItemBody(widget.taskId, _bodyCtrl.text);
  }

  Future<void> _setPriority(TaskPriority p) async {
    await ref.read(databaseProvider).tasksDao.updateTaskPriority(widget.taskId, p);
    await _load();
  }

  Future<void> _markComplete() async {
    await ref.read(databaseProvider).tasksDao.updateTaskStatus(widget.taskId, TaskStatus.done);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).itemsDao.deleteItem(widget.taskId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final priorityColors = {
      TaskPriority.high: Colors.red,
      TaskPriority.medium: Colors.orange,
      TaskPriority.low: Colors.teal,
    };
    final priority = _task?.priority ?? TaskPriority.medium;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Task title'),
          onEditingComplete: _saveTitle,
        ),
        actions: [
          PopupMenuButton<TaskPriority>(
            initialValue: priority,
            onSelected: _setPriority,
            child: Chip(
              label: Text(priority.name.toUpperCase()),
              backgroundColor: priorityColors[priority]!.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: priorityColors[priority]),
            ),
            itemBuilder: (_) => TaskPriority.values
                .map((p) => PopupMenuItem(value: p, child: Text(p.name)))
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_task?.dueDate != null)
              Text('Due: ${DateFormat.yMMMd().format(_task!.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            TextField(
              controller: _bodyCtrl,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Add notes...', border: InputBorder.none),
              onEditingComplete: _saveBody,
            ),
            const Divider(height: 32),
            AttachmentSection(itemId: widget.taskId),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _markComplete,
                icon: const Icon(Icons.check),
                label: const Text('Mark Complete'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}

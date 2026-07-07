import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../services/sync_queue.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Items, Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Stream<List<TypedResult>> watchTasksByPriority(TaskPriority priority) {
    final query = select(tasks).join([
      innerJoin(items, items.id.equalsExp(tasks.id)),
    ])
      ..where(tasks.priority.equals(priority.index))
      ..orderBy([OrderingTerm.asc(tasks.dueDate)]);
    return query.watch();
  }

  Future<void> updateTaskPriority(String id, TaskPriority priority) async {
    await (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(priority: Value(priority)));
    SyncQueue.global.enqueue(id);
  }

  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    await (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(status: Value(status)));
    SyncQueue.global.enqueue(id);
  }

  Future<void> updateTaskDueDate(String id, DateTime? dueDate) async {
    await (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(dueDate: Value(dueDate)));
    SyncQueue.global.enqueue(id);
  }

  Future<void> linkCalendarEvent(String id, String eventId) async {
    await (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(calendarEventId: Value(eventId)));
    SyncQueue.global.enqueue(id);
  }

  Future<List<TypedResult>> getTasksDueOn(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks).join([innerJoin(items, items.id.equalsExp(tasks.id))])
          ..where(tasks.dueDate.isBetweenValues(start, end)))
        .get();
  }
}

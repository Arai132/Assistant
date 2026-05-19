import 'package:drift/drift.dart';
import '../database/app_database.dart';

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

  Future<void> updateTaskPriority(String id, TaskPriority priority) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(priority: Value(priority)));

  Future<void> updateTaskStatus(String id, TaskStatus status) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(status: Value(status)));

  Future<void> updateTaskDueDate(String id, DateTime? dueDate) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(dueDate: Value(dueDate)));

  Future<void> linkCalendarEvent(String id, String eventId) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(calendarEventId: Value(eventId)));

  Future<List<TypedResult>> getTasksDueOn(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks).join([innerJoin(items, items.id.equalsExp(tasks.id))])
          ..where(tasks.dueDate.isBetweenValues(start, end)))
        .get();
  }
}

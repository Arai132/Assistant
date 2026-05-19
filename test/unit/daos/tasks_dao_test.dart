import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  Future<String> createTask(AppDatabase db, {TaskPriority priority = TaskPriority.medium}) async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: 'Task', type: ItemType.task),
    );
    await db.into(db.tasks).insert(
      TasksCompanion.insert(id: id, priority: Value(priority)),
    );
    return id;
  }

  test('update task priority', () async {
    final id = await createTask(db, priority: TaskPriority.low);
    await db.tasksDao.updateTaskPriority(id, TaskPriority.high);
    final rows = await db.tasksDao.watchTasksByPriority(TaskPriority.high).first;
    expect(rows.length, 1);
  });

  test('update task status', () async {
    final id = await createTask(db);
    await db.tasksDao.updateTaskStatus(id, TaskStatus.done);
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, TaskStatus.done);
  });
}

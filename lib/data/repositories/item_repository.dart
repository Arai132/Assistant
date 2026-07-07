import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../services/sync_queue.dart';

class ItemRepository {
  final AppDatabase _db;
  ItemRepository(this._db);

  Future<String> createTask({
    required String title,
    String body = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final id = await _db.itemsDao.insertItem(
      ItemsCompanion(
        title: Value(title),
        body: Value(body),
        type: const Value(ItemType.task),
      ),
    );
    await _db.into(_db.tasks).insert(
      TasksCompanion(
        id: Value(id),
        priority: Value(priority),
        dueDate: Value(dueDate),
      ),
    );
    return id;
  }

  Future<String> createNote({required String title, String body = ''}) =>
      _db.itemsDao.insertItem(
        ItemsCompanion(
          title: Value(title),
          body: Value(body),
          type: const Value(ItemType.note),
        ),
      );

  Future<void> promoteNoteToTask(String id, {TaskPriority priority = TaskPriority.medium}) async {
    await (_db.update(_db.items)..where((t) => t.id.equals(id)))
        .write(const ItemsCompanion(type: Value(ItemType.both)));
    final existing = await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.tasks).insert(
        TasksCompanion(id: Value(id), priority: Value(priority)),
      );
    }
    SyncQueue.global.enqueue(id);
  }

  Future<void> deleteItem(String id) => _db.itemsDao.deleteItem(id);

  Stream<List<Item>> watchNotes() => _db.itemsDao.watchAllNotes();

  Stream<List<TypedResult>> watchTasksByPriority(TaskPriority p) =>
      _db.tasksDao.watchTasksByPriority(p);
}

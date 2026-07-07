import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../services/sync_queue.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  static const _uuid = Uuid();

  Future<String> insertItem(ItemsCompanion entry) async {
    final id = _uuid.v4();
    await into(items).insert(entry.copyWith(id: Value(id)));
    SyncQueue.global.enqueue(id);
    return id;
  }

  Future<Item?> getItemById(String id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Item>> watchAllNotes() =>
      (select(items)..where((t) => t.type.equals(ItemType.note.index))).watch();

  Future<void> updateItemTitle(String id, String title) async {
    await (update(items)..where((t) => t.id.equals(id)))
        .write(ItemsCompanion(title: Value(title), updatedAt: Value(DateTime.now())));
    SyncQueue.global.enqueue(id);
  }

  Future<void> updateItemBody(String id, String body) async {
    await (update(items)..where((t) => t.id.equals(id)))
        .write(ItemsCompanion(body: Value(body), updatedAt: Value(DateTime.now())));
    SyncQueue.global.enqueue(id);
  }

  Future<void> deleteItem(String id) async {
    await (delete(items)..where((t) => t.id.equals(id))).go();
    SyncQueue.global.dequeue(id);
  }

  Future<List<Item>> searchItems(String query) =>
      (select(items)
            ..where((t) =>
                t.title.like('%$query%') | t.body.like('%$query%')))
          .get();
}

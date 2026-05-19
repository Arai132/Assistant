import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  static const _uuid = Uuid();

  Future<String> insertItem(ItemsCompanion entry) async {
    final id = _uuid.v4();
    await into(items).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<Item?> getItemById(String id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Item>> watchAllNotes() =>
      (select(items)..where((t) => t.type.equals(ItemType.note.index))).watch();

  Future<void> updateItemTitle(String id, String title) =>
      (update(items)..where((t) => t.id.equals(id)))
          .write(ItemsCompanion(title: Value(title), updatedAt: Value(DateTime.now())));

  Future<void> updateItemBody(String id, String body) =>
      (update(items)..where((t) => t.id.equals(id)))
          .write(ItemsCompanion(body: Value(body), updatedAt: Value(DateTime.now())));

  Future<void> deleteItem(String id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  Future<List<Item>> searchItems(String query) =>
      (select(items)
            ..where((t) =>
                t.title.like('%$query%') | t.body.like('%$query%')))
          .get();
}

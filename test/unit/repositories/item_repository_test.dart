import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/data/repositories/item_repository.dart';

void main() {
  late AppDatabase db;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ItemRepository(db);
  });
  tearDown(() async => db.close());

  test('createTask returns id and stores item+task rows', () async {
    final id = await repo.createTask(title: 'Buy milk', priority: TaskPriority.low);
    expect(id, isNotEmpty);
    final item = await db.itemsDao.getItemById(id);
    expect(item, isNotNull);
    expect(item!.type, ItemType.task);
  });

  test('createNote returns id and stores item row', () async {
    final id = await repo.createNote(title: 'Meeting notes', body: 'Key points');
    final item = await db.itemsDao.getItemById(id);
    expect(item!.type, ItemType.note);
  });

  test('promoteNoteToTask changes type to both and adds task row', () async {
    final id = await repo.createNote(title: 'Idea');
    await repo.promoteNoteToTask(id, priority: TaskPriority.high);
    final item = await db.itemsDao.getItemById(id);
    expect(item!.type, ItemType.both);
    final taskRow = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    expect(taskRow, isNotNull);
  });
}

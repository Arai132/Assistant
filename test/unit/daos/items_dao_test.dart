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

  test('insert and retrieve an item', () async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(
        title: 'Test item',
        body: const Value('body text'),
        type: ItemType.note,
      ),
    );
    final item = await db.itemsDao.getItemById(id);
    expect(item, isNotNull);
    expect(item!.title, 'Test item');
    expect(item.type, ItemType.note);
  });

  test('update item title', () async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: 'Old', type: ItemType.note),
    );
    await db.itemsDao.updateItemTitle(id, 'New');
    final item = await db.itemsDao.getItemById(id);
    expect(item!.title, 'New');
  });

  test('delete item', () async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: 'Del', type: ItemType.note),
    );
    await db.itemsDao.deleteItem(id);
    final item = await db.itemsDao.getItemById(id);
    expect(item, isNull);
  });
}

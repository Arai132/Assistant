import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/services/export_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('export_service_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('exportAsJson writes items, tasks, and attachments to a JSON file', () async {
    final noteId = await db.itemsDao.insertItem(
      ItemsCompanion(title: const Value('My note'), body: const Value('body'), type: const Value(ItemType.note)),
    );
    final taskId = await db.itemsDao.insertItem(
      ItemsCompanion(title: const Value('My task'), type: const Value(ItemType.task)),
    );
    await db.into(db.tasks).insert(
      TasksCompanion.insert(id: taskId, priority: const Value(TaskPriority.high)),
    );
    await db.into(db.attachments).insert(
      AttachmentsCompanion.insert(id: 'att-1', itemId: noteId, type: AttachmentType.image, localPath: '/tmp/x.png'),
    );

    final path = await ExportService(db).exportAsJson(directory: tempDir);
    final contents = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;

    expect(contents['items'], hasLength(2));
    expect(contents['tasks'], hasLength(1));
    expect(contents['attachments'], hasLength(1));
    expect((contents['items'] as List).any((i) => i['title'] == 'My note'), isTrue);
    expect((contents['tasks'] as List).first['priority'], 'high');
    expect((contents['attachments'] as List).first['localPath'], '/tmp/x.png');
  });
}

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../daos/items_dao.dart';
import '../daos/tasks_dao.dart';
import '../daos/attachments_dao.dart';

part 'app_database.g.dart';

enum ItemType { task, note, both }
enum TaskStatus { todo, inProgress, done }
enum TaskPriority { high, medium, low }
enum AttachmentType { voiceMemo, image, document, video }

@DataClassName('Item')
class Items extends Table {
  TextColumn get id => text().clientDefault(() => DateTime.now().microsecondsSinceEpoch.toString())();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  IntColumn get type => intEnum<ItemType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text().references(Items, #id)();
  IntColumn get priority => intEnum<TaskPriority>().withDefault(const Constant(1))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get status => intEnum<TaskStatus>().withDefault(const Constant(0))();
  TextColumn get calendarEventId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Attachment')
class Attachments extends Table {
  TextColumn get id => text().clientDefault(() => DateTime.now().microsecondsSinceEpoch.toString())();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get type => intEnum<AttachmentType>()();
  TextColumn get localPath => text()();
  TextColumn get cloudUrl => text().nullable()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get aiDescription => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Items, Tasks, Attachments], daos: [ItemsDao, TasksDao, AttachmentsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'assistant.db'));
    return NativeDatabase.createInBackground(file);
  });
}

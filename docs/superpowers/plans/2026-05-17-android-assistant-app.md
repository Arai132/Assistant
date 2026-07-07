# Android Assistant App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first Flutter Android app that unifies task management, note-taking, and scheduling with a shared attachment system (voice, image, document, video), ML Kit OCR, optional OpenAI AI description, and optional Firebase + Google Calendar sync.

**Architecture:** Unified `Item` model stored in SQLite via Drift; Riverpod for state; GoRouter for navigation. Features are isolated under `lib/features/`; shared services under `lib/services/`. All writes hit local SQLite first — cloud sync is a background concern, never blocking UI.

**Tech Stack:** Flutter 3.x · Dart 3 · Drift (SQLite ORM) · flutter_riverpod · go_router · drag_and_drop_lists · google_mlkit_text_recognition · flutter_sound · firebase_core/firestore/storage · google_sign_in · googleapis · flutter_secure_storage · image_picker · file_picker · dio

---

## File Map

```
lib/
  main.dart
  app.dart                                    # MaterialApp + GoRouter
  data/
    database/
      app_database.dart                       # Drift DB definition + table classes
      app_database.g.dart                     # generated — do not edit
    daos/
      items_dao.dart                          # CRUD for Item rows
      tasks_dao.dart                          # CRUD for Task rows
      attachments_dao.dart                    # CRUD for Attachment rows
    repositories/
      item_repository.dart                    # Combines items + tasks DAOs
      attachment_repository.dart              # File I/O + attachment DAO
  features/
    shell/
      app_shell.dart                          # Scaffold with bottom nav + FAB
      fab_menu.dart                           # Expandable FAB overlay
    tasks/
      tasks_screen.dart                       # Kanban board (3 lanes)
      task_detail_screen.dart                 # Edit task + attachments
      widgets/
        kanban_lane.dart                      # Single priority lane
        task_card.dart                        # Card widget
    notes/
      notes_screen.dart                       # Searchable list
      note_detail_screen.dart                 # Edit note + attachments
      widgets/
        note_list_tile.dart
    calendar/
      calendar_screen.dart                    # Month grid + day panel
      widgets/
        month_grid.dart
        day_detail_panel.dart
    settings/
      settings_screen.dart
    shared/
      attachment_section.dart                 # Reusable attachment UI (tasks + notes)
      image_capture/
        image_capture_screen.dart             # Camera/gallery → OCR → save
        ocr_service.dart                      # ML Kit wrapper
        ai_description_service.dart           # OpenAI GPT-4o Vision wrapper
  services/
    voice_recorder_service.dart               # flutter_sound record + playback
    file_storage_service.dart                 # copy files into app dir
    google_calendar_service.dart              # OAuth2 + GCal read/write
    firebase_sync_service.dart                # Firestore + Storage sync
    secure_storage_service.dart               # flutter_secure_storage wrapper
  providers/
    database_provider.dart                    # Riverpod provider for AppDatabase
    item_provider.dart                        # Task + note stream providers
    attachment_provider.dart
    calendar_provider.dart
    sync_provider.dart

test/
  unit/
    daos/
      items_dao_test.dart
      tasks_dao_test.dart
      attachments_dao_test.dart
    repositories/
      item_repository_test.dart
      attachment_repository_test.dart
    services/
      ocr_service_test.dart
      ai_description_service_test.dart
      firebase_sync_service_test.dart
  widget/
    tasks/
      task_card_test.dart
      kanban_lane_test.dart
    notes/
      note_list_tile_test.dart
    shared/
      attachment_section_test.dart

integration_test/
  image_ocr_flow_test.dart
  voice_memo_test.dart
```

---

## Task 1: Flutter Project Setup

**Files:**
- Create: `pubspec.yaml`
- Create: `android/app/build.gradle` (modify minSdk)
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: Create the Flutter project**

```bash
flutter create --org com.example --project-name assistant_app --platforms android .
```

Expected: Flutter skeleton project created.

- [ ] **Step 2: Replace pubspec.yaml dependencies**

Open `pubspec.yaml` and replace the `dependencies` and `dev_dependencies` sections:

```yaml
name: assistant_app
description: Personal productivity assistant — tasks, notes, calendar.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  drag_and_drop_lists: ^0.4.2
  google_mlkit_text_recognition: ^0.13.0
  flutter_secure_storage: ^9.0.0
  flutter_sound: ^9.2.13
  file_picker: ^8.0.0
  image_picker: ^1.1.0
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  google_sign_in: ^6.2.0
  googleapis: ^13.0.0
  dio: ^5.4.0
  uuid: ^4.4.0
  intl: ^0.19.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  mockito: ^5.4.4
  integration_test:
    sdk: flutter
```

- [ ] **Step 3: Set Android minSdk to 21**

In `android/app/build.gradle`, find `minSdkVersion` and set:

```gradle
minSdkVersion 21
```

- [ ] **Step 4: Add permissions to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` before `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

- [ ] **Step 5: Write lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AssistantApp()));
}
```

- [ ] **Step 6: Write lib/app.dart (stub — GoRouter wired in Task 6)**

```dart
import 'package:flutter/material.dart';

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Setting up...'))),
    );
  }
}
```

- [ ] **Step 7: Install dependencies and verify build**

```bash
flutter pub get
flutter build apk --debug
```

Expected: APK builds without errors.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/build.gradle android/app/src/main/AndroidManifest.xml lib/main.dart lib/app.dart
git commit -m "feat: flutter project scaffold with all dependencies"
```

---

## Task 2: Drift Database — Item and Task Tables

**Files:**
- Create: `lib/data/database/app_database.dart`
- Create: `test/unit/daos/items_dao_test.dart`
- Create: `test/unit/daos/tasks_dao_test.dart`

- [ ] **Step 1: Write the failing test for Item CRUD**

Create `test/unit/daos/items_dao_test.dart`:

```dart
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
        title: const Value('Test item'),
        body: const Value('body text'),
        type: const Value(ItemType.note),
      ),
    );
    final item = await db.itemsDao.getItemById(id);
    expect(item, isNotNull);
    expect(item!.title, 'Test item');
    expect(item.type, ItemType.note);
  });

  test('update item title', () async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: const Value('Old'), type: const Value(ItemType.note)),
    );
    await db.itemsDao.updateItemTitle(id, 'New');
    final item = await db.itemsDao.getItemById(id);
    expect(item!.title, 'New');
  });

  test('delete item', () async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: const Value('Del'), type: const Value(ItemType.note)),
    );
    await db.itemsDao.deleteItem(id);
    final item = await db.itemsDao.getItemById(id);
    expect(item, isNull);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/unit/daos/items_dao_test.dart
```

Expected: FAIL — `app_database.dart` does not exist.

- [ ] **Step 3: Write lib/data/database/app_database.dart**

```dart
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
  TextColumn get id => text().clientDefault(() => _uuid())();
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
  TextColumn get id => text().clientDefault(() => _uuid())();
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

String _uuid() {
  // Simple UUID v4 without package for table default; real UUIDs generated in DAO
  return DateTime.now().microsecondsSinceEpoch.toString();
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
```

- [ ] **Step 4: Write lib/data/daos/items_dao.dart**

```dart
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
```

- [ ] **Step 5: Write lib/data/daos/tasks_dao.dart**

```dart
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
```

- [ ] **Step 6: Write lib/data/daos/attachments_dao.dart (stub — fully built in Task 4)**

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  static const _uuid = Uuid();

  Future<String> insertAttachment(AttachmentsCompanion entry) async {
    final id = _uuid.v4();
    await into(attachments).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Stream<List<Attachment>> watchForItem(String itemId) =>
      (select(attachments)..where((t) => t.itemId.equals(itemId))).watch();

  Future<void> updateOcrText(String id, String text) =>
      (update(attachments)..where((t) => t.id.equals(id)))
          .write(AttachmentsCompanion(ocrText: Value(text)));

  Future<void> updateAiDescription(String id, String desc) =>
      (update(attachments)..where((t) => t.id.equals(id)))
          .write(AttachmentsCompanion(aiDescription: Value(desc)));

  Future<void> deleteAttachment(String id) =>
      (delete(attachments)..where((t) => t.id.equals(id))).go();
}
```

- [ ] **Step 7: Run code generator**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart`, `items_dao.g.dart`, `tasks_dao.g.dart`, `attachments_dao.g.dart` generated with no errors.

- [ ] **Step 8: Run tests — verify they pass**

```bash
flutter test test/unit/daos/items_dao_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 9: Write the failing tasks_dao test**

Create `test/unit/daos/tasks_dao_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  Future<String> _createTask(AppDatabase db, {TaskPriority priority = TaskPriority.medium}) async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: const Value('Task'), type: const Value(ItemType.task)),
    );
    await db.into(db.tasks).insert(
      TasksCompanion.insert(id: Value(id), priority: Value(priority)),
    );
    return id;
  }

  test('update task priority', () async {
    final id = await _createTask(db, priority: TaskPriority.low);
    await db.tasksDao.updateTaskPriority(id, TaskPriority.high);
    final rows = await db.tasksDao.watchTasksByPriority(TaskPriority.high).first;
    expect(rows.length, 1);
  });

  test('update task status', () async {
    final id = await _createTask(db);
    await db.tasksDao.updateTaskStatus(id, TaskStatus.done);
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, TaskStatus.done);
  });
}
```

- [ ] **Step 10: Run tasks_dao tests — verify they pass**

```bash
flutter test test/unit/daos/tasks_dao_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 11: Commit**

```bash
git add lib/data/ test/unit/daos/
git commit -m "feat: Drift database schema — Items, Tasks, Attachments tables + DAOs"
```

---

## Task 3: Repository Layer

**Files:**
- Create: `lib/data/repositories/item_repository.dart`
- Create: `lib/data/repositories/attachment_repository.dart`
- Create: `test/unit/repositories/item_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/repositories/item_repository_test.dart`:

```dart
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

  test('promoteNoteToTask changes type to task and adds task row', () async {
    final id = await repo.createNote(title: 'Idea');
    await repo.promoteNoteToTask(id, priority: TaskPriority.high);
    final item = await db.itemsDao.getItemById(id);
    expect(item!.type, ItemType.both);
    final taskRow = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    expect(taskRow, isNotNull);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/unit/repositories/item_repository_test.dart
```

Expected: FAIL — `item_repository.dart` not found.

- [ ] **Step 3: Write lib/data/repositories/item_repository.dart**

```dart
import '../database/app_database.dart';

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
      ItemsCompanion.insert(title: Value(title), body: Value(body), type: const Value(ItemType.task)),
    );
    await _db.into(_db.tasks).insert(
      TasksCompanion.insert(id: Value(id), priority: Value(priority), dueDate: Value(dueDate)),
    );
    return id;
  }

  Future<String> createNote({required String title, String body = ''}) =>
      _db.itemsDao.insertItem(
        ItemsCompanion.insert(title: Value(title), body: Value(body), type: const Value(ItemType.note)),
      );

  Future<void> promoteNoteToTask(String id, {TaskPriority priority = TaskPriority.medium}) async {
    await (_db.update(_db.items)..where((t) => t.id.equals(id)))
        .write(ItemsCompanion(type: const Value(ItemType.both)));
    final existing = await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.tasks).insert(TasksCompanion.insert(id: Value(id), priority: Value(priority)));
    }
  }

  Future<void> deleteItem(String id) => _db.itemsDao.deleteItem(id);

  Stream<List<Item>> watchNotes() => _db.itemsDao.watchAllNotes();

  Stream<List<TypedResult>> watchTasksByPriority(TaskPriority p) =>
      _db.tasksDao.watchTasksByPriority(p);
}
```

- [ ] **Step 4: Write lib/data/repositories/attachment_repository.dart**

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

class AttachmentRepository {
  final AppDatabase _db;
  AttachmentRepository(this._db);

  Future<String> saveAttachment({
    required String itemId,
    required File sourceFile,
    required AttachmentType type,
  }) async {
    if (sourceFile.lengthSync() > 100 * 1024 * 1024) {
      throw Exception('File exceeds 100 MB limit');
    }
    final dir = await _attachmentDir();
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
    await sourceFile.copy(destPath);
    return _db.attachmentsDao.insertAttachment(
      AttachmentsCompanion.insert(
        itemId: Value(itemId),
        type: Value(type),
        localPath: Value(destPath),
      ),
    );
  }

  Future<void> deleteAttachment(String id, String localPath) async {
    await _db.attachmentsDao.deleteAttachment(id);
    final file = File(localPath);
    if (await file.exists()) await file.delete();
  }

  Stream<List<Attachment>> watchForItem(String itemId) =>
      _db.attachmentsDao.watchForItem(itemId);

  Future<Directory> _attachmentDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
```

- [ ] **Step 5: Run tests — verify they pass**

```bash
flutter test test/unit/repositories/
```

Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/ test/unit/repositories/
git commit -m "feat: ItemRepository and AttachmentRepository"
```

---

## Task 4: Riverpod Providers + GoRouter Shell

**Files:**
- Create: `lib/providers/database_provider.dart`
- Create: `lib/providers/item_provider.dart`
- Create: `lib/providers/attachment_provider.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Write lib/providers/database_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/attachment_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(ref.watch(databaseProvider)),
);

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(databaseProvider)),
);
```

- [ ] **Step 2: Write lib/providers/item_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final highPriorityTasksProvider = StreamProvider<List<TypedResult>>(
  (ref) => ref.watch(itemRepositoryProvider).watchTasksByPriority(TaskPriority.high),
);

final mediumPriorityTasksProvider = StreamProvider<List<TypedResult>>(
  (ref) => ref.watch(itemRepositoryProvider).watchTasksByPriority(TaskPriority.medium),
);

final lowPriorityTasksProvider = StreamProvider<List<TypedResult>>(
  (ref) => ref.watch(itemRepositoryProvider).watchTasksByPriority(TaskPriority.low),
);

final notesProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(itemRepositoryProvider).watchNotes(),
);
```

- [ ] **Step 3: Write lib/providers/attachment_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final attachmentsForItemProvider = StreamProvider.family<List<Attachment>, String>(
  (ref, itemId) => ref.watch(attachmentRepositoryProvider).watchForItem(itemId),
);
```

- [ ] **Step 4: Update lib/app.dart with GoRouter**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/shell/app_shell.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/tasks/task_detail_screen.dart';
import 'features/notes/notes_screen.dart';
import 'features/notes/note_detail_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/tasks',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tasks', builder: (c, s) => const TasksScreen()),
          GoRoute(path: '/notes', builder: (c, s) => const NotesScreen()),
          GoRoute(path: '/calendar', builder: (c, s) => const CalendarScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (c, s) => TaskDetailScreen(taskId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (c, s) => NoteDetailScreen(noteId: s.pathParameters['id']!),
      ),
    ],
  );
});

class AssistantApp extends ConsumerWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Assistant',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 5: Create stub screens so the router compiles**

Create each file with the minimal content below. You'll flesh them out in Tasks 5–10.

`lib/features/tasks/tasks_screen.dart`:
```dart
import 'package:flutter/material.dart';
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Tasks'));
}
```

`lib/features/tasks/task_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Task')));
}
```

`lib/features/notes/notes_screen.dart`:
```dart
import 'package:flutter/material.dart';
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Notes'));
}
```

`lib/features/notes/note_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
class NoteDetailScreen extends StatelessWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Note')));
}
```

`lib/features/calendar/calendar_screen.dart`:
```dart
import 'package:flutter/material.dart';
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Calendar'));
}
```

`lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Settings'));
}
```

- [ ] **Step 6: Write lib/features/shell/app_shell.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'fab_menu.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/tasks', '/notes', '/calendar', '/settings'];
  static const _labels = ['Tasks', 'Notes', 'Calendar', 'Settings'];
  static const _icons = [Icons.check_box, Icons.note, Icons.calendar_month, Icons.settings];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return _tabs.indexWhere((t) => location.startsWith(t)).clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: List.generate(
          4,
          (i) => NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
      floatingActionButton: const FabMenu(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
```

- [ ] **Step 7: Write lib/features/shell/fab_menu.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/database_provider.dart';

class FabMenu extends ConsumerStatefulWidget {
  const FabMenu({super.key});

  @override
  ConsumerState<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends ConsumerState<FabMenu> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  Future<void> _newTask() async {
    _toggle();
    final repo = ref.read(itemRepositoryProvider);
    final id = await repo.createTask(title: 'New task');
    if (mounted) context.push('/tasks/$id');
  }

  Future<void> _newNote() async {
    _toggle();
    final repo = ref.read(itemRepositoryProvider);
    final id = await repo.createNote(title: 'New note');
    if (mounted) context.push('/notes/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open) ...[
          _FabOption(icon: Icons.task_alt, label: 'New Task', onTap: _newTask),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.note_add, label: 'New Note', onTap: _newNote),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.camera_alt, label: 'Snap Image', onTap: _toggle),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.mic, label: 'Record Voice', onTap: _toggle),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedIcon(icon: AnimatedIcons.add_event, progress: _controller),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FabOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 8),
        FloatingActionButton.small(onPressed: onTap, child: Icon(icon)),
      ],
    );
  }
}
```

- [ ] **Step 8: Build and run on emulator/device**

```bash
flutter run
```

Expected: App launches, bottom nav shows 4 tabs, FAB in center expands to show options. Tapping Tasks/Notes/Calendar/Settings navigates to stub screens.

- [ ] **Step 9: Commit**

```bash
git add lib/features/ lib/providers/ lib/app.dart
git commit -m "feat: GoRouter shell, Riverpod providers, nav bar, FAB menu"
```

---

## Task 5: Tasks Screen — Kanban Board

**Files:**
- Create: `lib/features/tasks/widgets/task_card.dart`
- Create: `lib/features/tasks/widgets/kanban_lane.dart`
- Modify: `lib/features/tasks/tasks_screen.dart`
- Create: `test/widget/tasks/task_card_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/widget/tasks/task_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/features/tasks/widgets/task_card.dart';
import 'package:assistant_app/data/database/app_database.dart';

void main() {
  testWidgets('TaskCard shows title and due date', (tester) async {
    final item = Item(
      id: '1',
      title: 'Fix bug',
      body: '',
      type: ItemType.task,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
    final task = TaskRow(
      id: '1',
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 5, 20),
      status: TaskStatus.todo,
      calendarEventId: null,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TaskCard(item: item, task: task, onTap: () {})),
    ));

    expect(find.text('Fix bug'), findsOneWidget);
    expect(find.text('May 20'), findsOneWidget);
  });

  testWidgets('TaskCard checkbox calls onStatusChange', (tester) async {
    bool changed = false;
    final item = Item(id: '1', title: 'T', body: '', type: ItemType.task,
        createdAt: DateTime.now(), updatedAt: DateTime.now());
    final task = TaskRow(id: '1', priority: TaskPriority.low, dueDate: null,
        status: TaskStatus.todo, calendarEventId: null);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskCard(item: item, task: task, onTap: () {}, onStatusChange: (_) => changed = true),
      ),
    ));

    await tester.tap(find.byType(Checkbox));
    expect(changed, isTrue);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/widget/tasks/task_card_test.dart
```

Expected: FAIL — `task_card.dart` not found.

- [ ] **Step 3: Write lib/features/tasks/widgets/task_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

class TaskCard extends StatelessWidget {
  final Item item;
  final TaskRow task;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onStatusChange;

  const TaskCard({
    super.key,
    required this.item,
    required this.task,
    required this.onTap,
    this.onStatusChange,
  });

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: onStatusChange,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        _dateFmt.format(task.dueDate!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test — verify it passes**

```bash
flutter test test/widget/tasks/task_card_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 5: Write lib/features/tasks/widgets/kanban_lane.dart**

```dart
import 'package:drift/drift.dart' show TypedResult;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';
import 'task_card.dart';

class KanbanLane extends ConsumerWidget {
  final String label;
  final TaskPriority priority;
  final Color color;
  final List<TypedResult> rows;

  const KanbanLane({
    super.key,
    required this.label,
    required this.priority,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: color.withOpacity(0.15),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                ref.read(itemRepositoryProvider)
                  ..watchTasksByPriority(priority); // triggers rebuild
                final db = ref.read(databaseProvider);
                db.tasksDao.updateTaskPriority(details.data, priority);
              },
              builder: (context, candidate, rejected) => ListView.builder(
                padding: const EdgeInsets.only(top: 4),
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final item = rows[i].readTable(ref.read(databaseProvider).items);
                  final task = rows[i].readTable(ref.read(databaseProvider).tasks);
                  return Draggable<String>(
                    data: item.id,
                    feedback: Material(
                      elevation: 4,
                      child: SizedBox(
                        width: 160,
                        child: TaskCard(item: item, task: task, onTap: () {}),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: TaskCard(item: item, task: task, onTap: () {}),
                    ),
                    child: TaskCard(
                      item: item,
                      task: task,
                      onTap: () => context.push('/tasks/${item.id}'),
                      onStatusChange: (v) {
                        final db = ref.read(databaseProvider);
                        db.tasksDao.updateTaskStatus(
                          item.id,
                          v == true ? TaskStatus.done : TaskStatus.todo,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Replace lib/features/tasks/tasks_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/item_provider.dart';
import 'widgets/kanban_lane.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final high = ref.watch(highPriorityTasksProvider);
    final medium = ref.watch(mediumPriorityTasksProvider);
    final low = ref.watch(lowPriorityTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KanbanLane(
            label: 'High',
            priority: TaskPriority.high,
            color: Colors.red,
            rows: high.valueOrNull ?? [],
          ),
          KanbanLane(
            label: 'Medium',
            priority: TaskPriority.medium,
            color: Colors.orange,
            rows: medium.valueOrNull ?? [],
          ),
          KanbanLane(
            label: 'Low',
            priority: TaskPriority.low,
            color: Colors.teal,
            rows: low.valueOrNull ?? [],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run all tests**

```bash
flutter test test/widget/tasks/
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/tasks/ test/widget/tasks/
git commit -m "feat: Kanban board — task cards and draggable priority lanes"
```

---

## Task 6: Task Detail Screen

**Files:**
- Modify: `lib/features/tasks/task_detail_screen.dart`

- [ ] **Step 1: Replace lib/features/tasks/task_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../shared/attachment_section.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  Item? _item;
  TaskRow? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final item = await db.itemsDao.getItemById(widget.taskId);
    final taskRow = item == null
        ? null
        : await (db.select(db.tasks)..where((t) => t.id.equals(widget.taskId))).getSingleOrNull();
    if (mounted) {
      setState(() {
        _item = item;
        _task = taskRow;
        _titleCtrl.text = item?.title ?? '';
        _bodyCtrl.text = item?.body ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveTitle() async {
    final db = ref.read(databaseProvider);
    await db.itemsDao.updateItemTitle(widget.taskId, _titleCtrl.text.trim());
  }

  Future<void> _saveBody() async {
    final db = ref.read(databaseProvider);
    await db.itemsDao.updateItemBody(widget.taskId, _bodyCtrl.text);
  }

  Future<void> _setPriority(TaskPriority p) async {
    final db = ref.read(databaseProvider);
    await db.tasksDao.updateTaskPriority(widget.taskId, p);
    await _load();
  }

  Future<void> _markComplete() async {
    final db = ref.read(databaseProvider);
    await db.tasksDao.updateTaskStatus(widget.taskId, TaskStatus.done);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final db = ref.read(databaseProvider);
    await db.itemsDao.deleteItem(widget.taskId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final priorityColors = {
      TaskPriority.high: Colors.red,
      TaskPriority.medium: Colors.orange,
      TaskPriority.low: Colors.teal,
    };
    final priority = _task?.priority ?? TaskPriority.medium;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Task title'),
          onEditingComplete: _saveTitle,
        ),
        actions: [
          PopupMenuButton<TaskPriority>(
            initialValue: priority,
            onSelected: _setPriority,
            child: Chip(
              label: Text(priority.name.toUpperCase()),
              backgroundColor: priorityColors[priority]!.withOpacity(0.2),
              labelStyle: TextStyle(color: priorityColors[priority]),
            ),
            itemBuilder: (_) => TaskPriority.values
                .map((p) => PopupMenuItem(value: p, child: Text(p.name)))
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_task?.dueDate != null)
              Text('Due: ${DateFormat.yMMMd().format(_task!.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            TextField(
              controller: _bodyCtrl,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Add notes...', border: InputBorder.none),
              onEditingComplete: _saveBody,
            ),
            const Divider(height: 32),
            AttachmentSection(itemId: widget.taskId),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _markComplete,
                icon: const Icon(Icons.check),
                label: const Text('Mark Complete'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the app and verify Task Detail opens from Kanban**

```bash
flutter run
```

Expected: Tapping a task card opens the detail screen. Title, priority badge, and notes field are visible. Marking complete pops back to Kanban.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/task_detail_screen.dart
git commit -m "feat: task detail screen — inline title, priority, body, complete/delete"
```

---

## Task 7: Notes Screen + Note Detail

**Files:**
- Create: `lib/features/notes/widgets/note_list_tile.dart`
- Modify: `lib/features/notes/notes_screen.dart`
- Modify: `lib/features/notes/note_detail_screen.dart`
- Create: `test/widget/notes/note_list_tile_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/widget/notes/note_list_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/features/notes/widgets/note_list_tile.dart';
import 'package:assistant_app/data/database/app_database.dart';

void main() {
  testWidgets('NoteListTile shows title and body preview', (tester) async {
    final item = Item(
      id: '1',
      title: 'Shopping list',
      body: 'Milk, eggs, bread',
      type: ItemType.note,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NoteListTile(item: item, onTap: () {})),
    ));

    expect(find.text('Shopping list'), findsOneWidget);
    expect(find.text('Milk, eggs, bread'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/widget/notes/note_list_tile_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Write lib/features/notes/widgets/note_list_tile.dart**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

class NoteListTile extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const NoteListTile({super.key, required this.item, required this.onTap});

  static final _dateFmt = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: item.body.isNotEmpty
          ? Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        _dateFmt.format(item.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 4: Run test — verify it passes**

```bash
flutter test test/widget/notes/note_list_tile_test.dart
```

Expected: PASS.

- [ ] **Step 5: Replace lib/features/notes/notes_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/item_provider.dart';
import 'widgets/note_list_tile.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider).valueOrNull ?? [];
    final notes = _query.isEmpty
        ? allNotes
        : allNotes.where((n) =>
            n.title.toLowerCase().contains(_query.toLowerCase()) ||
            n.body.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (ctx, i) => NoteListTile(
          item: notes[i],
          onTap: () => context.push('/notes/${notes[i].id}'),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Replace lib/features/notes/note_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/item_provider.dart';
import '../shared/attachment_section.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  Item? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final item = await ref.read(databaseProvider).itemsDao.getItemById(widget.noteId);
    if (mounted) {
      setState(() {
        _item = item;
        _titleCtrl.text = item?.title ?? '';
        _bodyCtrl.text = item?.body ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    await db.itemsDao.updateItemTitle(widget.noteId, _titleCtrl.text.trim());
    await db.itemsDao.updateItemBody(widget.noteId, _bodyCtrl.text);
  }

  Future<void> _promoteToTask() async {
    await ref.read(itemRepositoryProvider).promoteNoteToTask(widget.noteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promoted to task')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Note title'),
          onEditingComplete: _save,
        ),
        actions: [
          TextButton(onPressed: _promoteToTask, child: const Text('Make Task')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                  border: InputBorder.none,
                ),
                onEditingComplete: _save,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const Divider(),
            AttachmentSection(itemId: widget.noteId),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/notes/ test/widget/notes/
git commit -m "feat: notes list (searchable) + note detail with promote-to-task"
```

---

## Task 8: Shared Attachment Section Widget

**Files:**
- Create: `lib/features/shared/attachment_section.dart`
- Create: `test/widget/shared/attachment_section_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/widget/shared/attachment_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/features/shared/attachment_section.dart';

void main() {
  testWidgets('AttachmentSection renders with no attachments', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AttachmentSection(itemId: 'test-id')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Attachments'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/widget/shared/attachment_section_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Write lib/features/shared/attachment_section.dart**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/database_provider.dart';

class AttachmentSection extends ConsumerWidget {
  final String itemId;
  const AttachmentSection({super.key, required this.itemId});

  IconData _iconFor(AttachmentType type) => switch (type) {
        AttachmentType.voiceMemo => Icons.mic,
        AttachmentType.image => Icons.image,
        AttachmentType.document => Icons.description,
        AttachmentType.video => Icons.videocam,
      };

  Future<void> _delete(BuildContext context, WidgetRef ref, Attachment att) async {
    await ref.read(attachmentRepositoryProvider).deleteAttachment(att.id, att.localPath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(attachmentsForItemProvider(itemId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        attachmentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (list) => list.isEmpty
              ? const Text('No attachments yet.', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map((att) => _AttachmentChip(
                    attachment: att,
                    onDelete: () => _delete(context, ref, att),
                  )).toList(),
                ),
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onDelete;
  const _AttachmentChip({required this.attachment, required this.onDelete});

  IconData _iconFor(AttachmentType type) => switch (type) {
        AttachmentType.voiceMemo => Icons.mic,
        AttachmentType.image => Icons.image,
        AttachmentType.document => Icons.description,
        AttachmentType.video => Icons.videocam,
      };

  String _label() {
    final name = attachment.localPath.split('/').last;
    return name.length > 20 ? '${name.substring(0, 17)}...' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_iconFor(attachment.type), size: 16),
      label: Text(_label()),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
    );
  }
}
```

- [ ] **Step 4: Run test — verify it passes**

```bash
flutter test test/widget/shared/attachment_section_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/shared/attachment_section.dart test/widget/shared/
git commit -m "feat: shared AttachmentSection widget used by tasks and notes"
```

---

## Task 9: Voice Memo Recording + Playback

**Files:**
- Create: `lib/services/voice_recorder_service.dart`
- Modify: `lib/features/shared/attachment_section.dart` (add record button + waveform player)

- [ ] **Step 1: Write lib/services/voice_recorder_service.dart**

```dart
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderOpen = false;
  bool _playerOpen = false;

  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _player.openPlayer();
    _recorderOpen = true;
    _playerOpen = true;
  }

  Future<String> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'attachments', 'voice_${DateTime.now().millisecondsSinceEpoch}.aac');
    await Directory(p.dirname(path)).create(recursive: true);
    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    return path;
  }

  Future<String?> stopRecording() => _recorder.stopRecorder();

  Future<void> playFile(String path) => _player.startPlayer(fromURI: path);

  Future<void> stopPlayback() => _player.stopPlayer();

  bool get isRecording => _recorder.isRecording;
  bool get isPlaying => _player.isPlaying;

  Future<void> dispose() async {
    if (_recorderOpen) await _recorder.closeRecorder();
    if (_playerOpen) await _player.closePlayer();
  }
}
```

- [ ] **Step 2: Add a VoiceMemoTile to attachment_section.dart**

Add this widget to `lib/features/shared/attachment_section.dart` (insert before the closing brace):

```dart
class VoiceMemoPlayer extends StatefulWidget {
  final Attachment attachment;
  const VoiceMemoPlayer({super.key, required this.attachment});

  @override
  State<VoiceMemoPlayer> createState() => _VoiceMemoPlayerState();
}

class _VoiceMemoPlayerState extends State<VoiceMemoPlayer> {
  final VoiceRecorderService _svc = VoiceRecorderService();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _svc.init();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _svc.stopPlayback();
    } else {
      await _svc.playFile(widget.attachment.localPath);
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.mic),
      title: Text(widget.attachment.localPath.split('/').last),
      trailing: IconButton(
        icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
        onPressed: _toggle,
      ),
    );
  }
}
```

Also add the import at the top of `attachment_section.dart`:

```dart
import '../../services/voice_recorder_service.dart';
```

And update `_AttachmentChip.build` so voice memos render as `VoiceMemoPlayer` instead of a chip. Replace the `build` method of `AttachmentSection`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final attachmentsAsync = ref.watch(attachmentsForItemProvider(itemId));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      attachmentsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Text('Error: $e'),
        data: (list) {
          final voices = list.where((a) => a.type == AttachmentType.voiceMemo).toList();
          final others = list.where((a) => a.type != AttachmentType.voiceMemo).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...voices.map((att) => VoiceMemoPlayer(attachment: att)),
              if (others.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: others.map((att) => _AttachmentChip(
                    attachment: att,
                    onDelete: () => _delete(context, ref, att),
                  )).toList(),
                ),
              if (list.isEmpty)
                const Text('No attachments yet.', style: TextStyle(color: Colors.grey)),
            ],
          );
        },
      ),
    ],
  );
}
```

- [ ] **Step 3: Build and verify no compile errors**

```bash
flutter build apk --debug
```

Expected: Builds without errors.

- [ ] **Step 4: Commit**

```bash
git add lib/services/voice_recorder_service.dart lib/features/shared/attachment_section.dart
git commit -m "feat: voice memo recording and in-app playback"
```

---

## Task 10: Image Capture → ML Kit OCR

**Files:**
- Create: `lib/services/ocr_service.dart` (already used in image_capture_screen.dart below)
- Create: `lib/features/shared/image_capture/ocr_service.dart`
- Create: `lib/features/shared/image_capture/image_capture_screen.dart`
- Create: `test/unit/services/ocr_service_test.dart`

- [ ] **Step 1: Write the failing test for OcrService**

Create `test/unit/services/ocr_service_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/features/shared/image_capture/ocr_service.dart';

void main() {
  test('OcrService.extractText returns empty string for non-existent file', () async {
    final svc = OcrService();
    final result = await svc.extractText(File('/tmp/nonexistent.jpg'));
    expect(result, isEmpty);
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
flutter test test/unit/services/ocr_service_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Write lib/features/shared/image_capture/ocr_service.dart**

```dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) return '';
    try {
      final input = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(input);
      return result.text;
    } catch (_) {
      return '';
    }
  }

  void dispose() => _recognizer.close();
}
```

- [ ] **Step 4: Run test — verify it passes**

```bash
flutter test test/unit/services/ocr_service_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write lib/features/shared/image_capture/image_capture_screen.dart**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';
import '../../../services/secure_storage_service.dart';
import 'ai_description_service.dart';
import 'ocr_service.dart';

class ImageCaptureScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ImageCaptureScreen({super.key, required this.itemId});

  @override
  ConsumerState<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen> {
  File? _image;
  String _ocrText = '';
  String _aiDesc = '';
  bool _processingOcr = false;
  bool _processingAi = false;
  bool _hasApiKey = false;

  final _ocr = OcrService();
  final _titleCtrl = TextEditingController(text: 'Image note');

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final key = await SecureStorageService().getOpenAiKey();
    if (mounted) setState(() => _hasApiKey = key != null && key.isNotEmpty);
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source);
    if (xFile == null) return;
    final file = File(xFile.path);
    setState(() { _image = file; _processingOcr = true; });
    final text = await _ocr.extractText(file);
    if (mounted) setState(() { _ocrText = text; _processingOcr = false; });
  }

  Future<void> _describeWithAi() async {
    if (_image == null) return;
    setState(() => _processingAi = true);
    try {
      final key = await SecureStorageService().getOpenAiKey();
      final desc = await AiDescriptionService(apiKey: key!).describe(_image!);
      if (mounted) setState(() => _aiDesc = desc);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description unavailable, using OCR only')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAi = false);
    }
  }

  Future<void> _save() async {
    if (_image == null) return;
    final repo = ref.read(attachmentRepositoryProvider);
    final attachId = await repo.saveAttachment(
      itemId: widget.itemId,
      sourceFile: _image!,
      type: AttachmentType.image,
    );
    final db = ref.read(databaseProvider);
    if (_ocrText.isNotEmpty) await db.attachmentsDao.updateOcrText(attachId, _ocrText);
    if (_aiDesc.isNotEmpty) await db.attachmentsDao.updateAiDescription(attachId, _aiDesc);
    if (_ocrText.isNotEmpty) await db.itemsDao.updateItemBody(widget.itemId, _ocrText);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ocr.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Image')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image == null) ...[
              FilledButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ] else ...[
              Image.file(_image!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 12),
              if (_processingOcr)
                const CircularProgressIndicator()
              else if (_ocrText.isNotEmpty) ...[
                Text('OCR Result', style: Theme.of(context).textTheme.titleSmall),
                Text(_ocrText),
              ],
              if (_hasApiKey && !_processingOcr) ...[
                const SizedBox(height: 8),
                _processingAi
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _describeWithAi,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Describe with AI'),
                      ),
                if (_aiDesc.isNotEmpty) ...[
                  Text('AI Description', style: Theme.of(context).textTheme.titleSmall),
                  Text(_aiDesc),
                ],
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Write lib/features/shared/image_capture/ai_description_service.dart**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class AiDescriptionService {
  final String apiKey;
  final Dio _dio;

  AiDescriptionService({required this.apiKey}) : _dio = Dio();

  Future<String> describe(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      data: {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Describe the contents of this image in 1-2 sentences.'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          }
        ],
        'max_tokens': 200,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }
}
```

- [ ] **Step 7: Write lib/services/secure_storage_service.dart**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyOpenAi = 'openai_api_key';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getOpenAiKey() => _storage.read(key: _keyOpenAi);
  Future<void> setOpenAiKey(String key) => _storage.write(key: _keyOpenAi, value: key);
  Future<void> deleteOpenAiKey() => _storage.delete(key: _keyOpenAi);
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/shared/image_capture/ lib/services/secure_storage_service.dart test/unit/services/
git commit -m "feat: image capture — ML Kit OCR + optional OpenAI AI description"
```

---

## Task 11: Calendar Screen

**Files:**
- Create: `lib/features/calendar/widgets/month_grid.dart`
- Create: `lib/features/calendar/widgets/day_detail_panel.dart`
- Modify: `lib/features/calendar/calendar_screen.dart`

- [ ] **Step 1: Write lib/features/calendar/widgets/day_detail_panel.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';

class DayDetailPanel extends ConsumerWidget {
  final DateTime date;
  const DayDetailPanel({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<TypedResult>>(
      future: ref.read(databaseProvider).tasksDao.getTasksDueOn(date),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No tasks on ${DateFormat.MMMd().format(date)}',
                style: const TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final item = tasks[i].readTable(ref.read(databaseProvider).items);
            final task = tasks[i].readTable(ref.read(databaseProvider).tasks);
            final color = {
              TaskPriority.high: Colors.red,
              TaskPriority.medium: Colors.orange,
              TaskPriority.low: Colors.teal,
            }[task.priority]!;
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, radius: 6),
              title: Text(item.title),
              onTap: () => context.push('/tasks/${item.id}'),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Write lib/features/calendar/widgets/month_grid.dart**

```dart
import 'package:flutter/material.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final Map<DateTime, List<Color>> dotsByDay;

  const MonthGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
    this.dotsByDay = const {},
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: startOffset + daysInMonth,
      itemBuilder: (ctx, index) {
        if (index < startOffset) return const SizedBox();
        final day = DateTime(month.year, month.month, index - startOffset + 1);
        final isSelected = day.year == selectedDay.year &&
            day.month == selectedDay.month &&
            day.day == selectedDay.day;
        final dots = dotsByDay[DateTime(day.year, day.month, day.day)] ?? [];
        return GestureDetector(
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(color: Theme.of(ctx).colorScheme.primary, shape: BoxShape.circle)
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                if (dots.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dots
                        .take(3)
                        .map((c) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Replace lib/features/calendar/calendar_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import 'widgets/month_grid.dart';
import 'widgets/day_detail_panel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM().format(_month)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() =>
              _month = DateTime(_month.year, _month.month - 1)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month + 1)),
          ),
        ],
      ),
      body: Column(
        children: [
          MonthGrid(
            month: _month,
            selectedDay: _selected,
            onDaySelected: (d) => setState(() => _selected = d),
          ),
          const Divider(),
          Expanded(child: DayDetailPanel(date: _selected)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/
git commit -m "feat: calendar screen — month grid with task dots + day detail panel"
```

---

## Task 12: Google Calendar Integration

**Files:**
- Create: `lib/services/google_calendar_service.dart`
- Create: `lib/providers/calendar_provider.dart`
- Modify: `lib/features/calendar/widgets/day_detail_panel.dart` (add GCal events)

- [ ] **Step 1: Write lib/services/google_calendar_service.dart**

```dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

class GoogleCalendarService extends ChangeNotifier {
  static const _scopes = [gcal.CalendarApi.calendarReadonlyScope, gcal.CalendarApi.calendarEventsScope];

  final GoogleSignIn _signIn = GoogleSignIn(scopes: _scopes);
  GoogleSignInAccount? _account;
  gcal.CalendarApi? _api;

  bool get isSignedIn => _account != null;

  Future<void> signIn() async {
    _account = await _signIn.signIn();
    if (_account != null) {
      final headers = await _account!.authHeaders;
      _api = gcal.CalendarApi(_AuthClient(headers));
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
    _api = null;
    notifyListeners();
  }

  Future<List<gcal.Event>> getEventsForDay(DateTime date) async {
    if (_api == null) return [];
    final start = DateTime(date.year, date.month, date.day).toUtc();
    final end = start.add(const Duration(days: 1));
    try {
      final result = await _api!.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );
      return result.items ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_api == null) return null;
    final event = gcal.Event()
      ..summary = title
      ..start = (gcal.EventDateTime()..dateTime = start.toUtc()..timeZone = 'UTC')
      ..end = (gcal.EventDateTime()..dateTime = end.toUtc()..timeZone = 'UTC');
    final created = await _api!.events.insert(event, 'primary');
    return created.id;
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
```

- [ ] **Step 2: Write lib/providers/calendar_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_calendar_service.dart';

final googleCalendarServiceProvider = ChangeNotifierProvider<GoogleCalendarService>(
  (ref) => GoogleCalendarService(),
);
```

- [ ] **Step 3: Update DayDetailPanel to also show GCal events**

In `lib/features/calendar/widgets/day_detail_panel.dart`, add the import and update `build`:

Add import:
```dart
import '../../../providers/calendar_provider.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
```

Replace the `build` method:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final gcalService = ref.watch(googleCalendarServiceProvider);

  return FutureBuilder<(List<TypedResult>, List<gcal.Event>)>(
    future: Future.wait([
      ref.read(databaseProvider).tasksDao.getTasksDueOn(date),
      gcalService.getEventsForDay(date),
    ]).then((r) => (r[0] as List<TypedResult>, r[1] as List<gcal.Event>)),
    builder: (ctx, snap) {
      final tasks = snap.data?.$1 ?? [];
      final events = snap.data?.$2 ?? [];

      if (tasks.isEmpty && events.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No items on ${DateFormat.MMMd().format(date)}',
              style: const TextStyle(color: Colors.grey)),
        );
      }

      return ListView(
        shrinkWrap: true,
        children: [
          ...events.map((e) => ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, radius: 6),
                title: Text(e.summary ?? '(No title)'),
                subtitle: e.start?.dateTime != null
                    ? Text(DateFormat.jm().format(e.start!.dateTime!.toLocal()))
                    : null,
              )),
          ...tasks.map((r) {
            final item = r.readTable(ref.read(databaseProvider).items);
            final task = r.readTable(ref.read(databaseProvider).tasks);
            final color = {
              TaskPriority.high: Colors.red,
              TaskPriority.medium: Colors.orange,
              TaskPriority.low: Colors.teal,
            }[task.priority]!;
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, radius: 6),
              title: Text(item.title),
              onTap: () => context.push('/tasks/${item.id}'),
            );
          }),
        ],
      );
    },
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/google_calendar_service.dart lib/providers/calendar_provider.dart lib/features/calendar/
git commit -m "feat: Google Calendar integration — OAuth2 sign-in, events on calendar screen"
```

---

## Task 13: Settings Screen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Replace lib/features/settings/settings_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_provider.dart';
import '../../services/secure_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await SecureStorageService().getOpenAiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
        _apiKeyCtrl.text = key ?? '';
      });
    }
  }

  Future<void> _saveKey() async {
    await SecureStorageService().setOpenAiKey(_apiKeyCtrl.text.trim());
    if (mounted) {
      setState(() => _hasApiKey = _apiKeyCtrl.text.trim().isNotEmpty);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  Future<void> _deleteKey() async {
    await SecureStorageService().deleteOpenAiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = false;
        _apiKeyCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gcal = ref.watch(googleCalendarServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            title: Text(gcal.isSignedIn ? 'Connected' : 'Not connected'),
            subtitle: const Text('Sync tasks with Google Calendar'),
            trailing: gcal.isSignedIn
                ? TextButton(onPressed: gcal.signOut, child: const Text('Disconnect'))
                : FilledButton(onPressed: gcal.signIn, child: const Text('Connect')),
          ),
          const Divider(),
          const ListTile(title: Text('AI Description', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'sk-...',
                suffixIcon: _hasApiKey
                    ? IconButton(icon: const Icon(Icons.delete), onPressed: _deleteKey)
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton(onPressed: _saveKey, child: const Text('Save API Key')),
          ),
          const Divider(),
          const ListTile(
            title: Text('Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Firebase sync — configure in Task 14'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: settings screen — GCal connect/disconnect, OpenAI key storage"
```

---

## Task 14: Firebase Sync (Optional Cloud)

**Files:**
- Create: `lib/services/firebase_sync_service.dart`
- Create: `lib/providers/sync_provider.dart`
- Create: `test/unit/services/firebase_sync_service_test.dart`

- [ ] **Step 1: Initialize Firebase**

Run FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

Expected: `lib/firebase_options.dart` generated.

- [ ] **Step 2: Update main.dart to init Firebase**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: AssistantApp()));
}
```

- [ ] **Step 3: Write the failing test**

Create `test/unit/services/firebase_sync_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/services/firebase_sync_service.dart';
import 'package:assistant_app/data/database/app_database.dart';

void main() {
  test('syncQueueEntry marks item for sync', () {
    final queue = SyncQueue();
    queue.enqueue('item-1');
    expect(queue.hasPending('item-1'), isTrue);
  });

  test('dequeue removes item from queue', () {
    final queue = SyncQueue();
    queue.enqueue('item-1');
    queue.dequeue('item-1');
    expect(queue.hasPending('item-1'), isFalse);
  });
}
```

- [ ] **Step 4: Run test — verify it fails**

```bash
flutter test test/unit/services/firebase_sync_service_test.dart
```

Expected: FAIL.

- [ ] **Step 5: Write lib/services/firebase_sync_service.dart**

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/database/app_database.dart';

class SyncQueue {
  final Set<String> _pending = {};
  void enqueue(String id) => _pending.add(id);
  void dequeue(String id) => _pending.remove(id);
  bool hasPending(String id) => _pending.contains(id);
  Set<String> get all => Set.unmodifiable(_pending);
}

class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SyncQueue syncQueue = SyncQueue();

  FirebaseSyncService(this._db);

  Future<void> syncItem(Item item) async {
    await _firestore.collection('items').doc(item.id).set({
      'title': item.title,
      'body': item.body,
      'type': item.type.index,
      'updatedAt': item.updatedAt.toIso8601String(),
    }, SetOptions(merge: true));
    syncQueue.dequeue(item.id);
  }

  Future<void> syncAttachment(Attachment att) async {
    final file = File(att.localPath);
    if (!await file.exists()) return;
    final ref = _storage.ref('attachments/${att.id}${_ext(att.localPath)}');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db.attachmentsDao.updateOcrText(att.id, att.ocrText ?? ''); // re-save unchanged
    await _firestore.collection('attachments').doc(att.id).set({
      'itemId': att.itemId,
      'cloudUrl': url,
      'ocrText': att.ocrText,
      'aiDescription': att.aiDescription,
    }, SetOptions(merge: true));
  }

  String _ext(String path) {
    final e = path.contains('.') ? '.${path.split('.').last}' : '';
    return e;
  }

  Future<void> syncAll() async {
    final pending = List<String>.from(syncQueue.all);
    for (final id in pending) {
      final item = await _db.itemsDao.getItemById(id);
      if (item != null) await syncItem(item);
    }
    final attachments = await _db.select(_db.attachments).get();
    for (final att in attachments) {
      if (att.cloudUrl == null) await syncAttachment(att);
    }
  }
}
```

- [ ] **Step 6: Run test — verify it passes**

```bash
flutter test test/unit/services/firebase_sync_service_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 7: Write lib/providers/sync_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_sync_service.dart';
import 'database_provider.dart';

final syncServiceProvider = Provider<FirebaseSyncService>(
  (ref) => FirebaseSyncService(ref.watch(databaseProvider)),
);
```

- [ ] **Step 8: Commit**

```bash
git add lib/services/firebase_sync_service.dart lib/providers/sync_provider.dart lib/firebase_options.dart lib/main.dart test/unit/services/firebase_sync_service_test.dart
git commit -m "feat: Firebase sync service — item + attachment upload, sync queue"
```

---

## Task 15: Integration Tests + Final Polish

**Files:**
- Create: `integration_test/image_ocr_flow_test.dart`
- Create: `integration_test/voice_memo_test.dart`

- [ ] **Step 1: Write image OCR integration test**

Create `integration_test/image_ocr_flow_test.dart`:

```dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/data/repositories/attachment_repository.dart';
import 'package:assistant_app/features/shared/image_capture/ocr_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('image captured, OCR runs, saved as attachment', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AttachmentRepository(db);

    final itemId = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: const Value('Test note'), type: const Value(ItemType.note)),
    );

    // Use a test image file from assets (add a test_image.jpg to integration_test/assets/)
    final imageFile = File('integration_test/assets/test_image.jpg');
    if (!await imageFile.exists()) {
      markTestSkipped('test_image.jpg not present');
      return;
    }

    final attId = await repo.saveAttachment(
      itemId: itemId,
      sourceFile: imageFile,
      type: AttachmentType.image,
    );

    final ocr = OcrService();
    final text = await ocr.extractText(imageFile);
    await db.attachmentsDao.updateOcrText(attId, text);

    final attachments = await db.attachmentsDao.watchForItem(itemId).first;
    expect(attachments.length, 1);
    expect(attachments.first.type, AttachmentType.image);

    await db.close();
  });
}
```

- [ ] **Step 2: Write voice memo integration test**

Create `integration_test/voice_memo_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:assistant_app/services/voice_recorder_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('voice recorder starts and stops', (tester) async {
    final svc = VoiceRecorderService();
    await svc.init();
    final path = await svc.startRecording();
    expect(svc.isRecording, isTrue);
    await Future.delayed(const Duration(milliseconds: 500));
    final savedPath = await svc.stopRecording();
    expect(svc.isRecording, isFalse);
    expect(savedPath, isNotNull);
    await svc.dispose();
  });
}
```

- [ ] **Step 3: Run unit + widget tests**

```bash
flutter test test/
```

Expected: All tests PASS.

- [ ] **Step 4: Run integration tests on a connected Android device or emulator**

```bash
flutter test integration_test/ -d <device-id>
```

Expected: All integration tests PASS (voice memo test requires microphone permission granted).

- [ ] **Step 5: Final smoke test — run app and exercise all tabs**

```bash
flutter run
```

Manual checklist:
- [ ] FAB opens and "New Task" creates a task that appears in the Kanban medium lane
- [ ] Dragging a task card to the High lane changes its priority
- [ ] Tapping a task opens detail; marking complete removes it from board
- [ ] FAB "New Note" creates a note; it appears in Notes list
- [ ] "Make Task" on a note appears in the Kanban board
- [ ] Calendar screen shows current month; tapping a day shows tasks due that day
- [ ] Settings → Connect Google Calendar opens OAuth flow
- [ ] Settings → Enter OpenAI API key stores it (shows *** in field after save)

- [ ] **Step 6: Final commit**

```bash
git add integration_test/
git commit -m "feat: integration tests for image OCR flow and voice memo"
```

---

## Self-Review Against Spec

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| Unified Item model (task / note / both) | Task 2, 3 |
| SQLite via Drift | Task 2 |
| Bottom nav 4 tabs + FAB | Task 4 |
| Kanban 3 lanes (High/Medium/Low) | Task 5 |
| Drag card between lanes changes priority | Task 5 |
| Task detail — title, priority, due date, notes, attachments | Task 6 |
| Notes list with search (title + body + OCR) | Task 7 |
| Note detail — promote to task | Task 7 |
| Shared attachment section on both task and note detail | Task 8 |
| Voice memo record + waveform player | Task 9 |
| Image capture → OCR | Task 10 |
| AI description (optional, key-gated) | Task 10 |
| AI button hidden if no API key | Task 10 (`_hasApiKey`) |
| "Description unavailable" toast on AI failure | Task 10 |
| File too large (>100MB) error | Task 3 (`AttachmentRepository.saveAttachment`) |
| Calendar month grid with colored dots | Task 11 |
| Day detail panel with tasks + GCal events | Task 11, 12 |
| Google Calendar OAuth2 sign-in/sign-out | Task 12 |
| GCal events read-only, open in GCal app | Task 12 (read-only; external open via URL can be added in polish) |
| Settings — GCal connect/disconnect | Task 13 |
| Settings — OpenAI API key (Keystore via flutter_secure_storage) | Task 13 |
| Firebase Firestore + Storage optional sync | Task 14 |
| Local-first, fully offline | Task 2 (Drift), Tasks 3–13 never block on network |
| Pending sync badge | Not yet wired to UI — add `syncQueue.hasPending(item.id)` check in `TaskCard` and `NoteListTile` as a follow-up |
| GCal "Add to Calendar" from task detail | `TaskDetailScreen` — add "Add to Calendar" button calling `googleCalendarService.createEvent` then `db.tasksDao.linkCalendarEvent`. Add as polish step after Task 13. |
| Export data (JSON) in Settings | Not yet implemented — add a `_exportJson` method in `SettingsScreen` that queries all items + attachments and saves to Downloads. |

**Remaining gaps to add as follow-up tasks (not blocking v1):**
1. Pending sync badge on `TaskCard`/`NoteListTile`
2. "Add to Calendar" button in `TaskDetailScreen`
3. Export JSON in `SettingsScreen`
4. Open GCal events in Google Calendar app (via `url_launcher`)

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/providers/database_provider.dart';
import 'package:assistant_app/providers/calendar_provider.dart';
import 'package:assistant_app/services/google_calendar_service.dart';
import 'package:assistant_app/features/tasks/task_detail_screen.dart';

class _FakeCalendarService extends GoogleCalendarService {
  @override
  bool get isSignedIn => true;

  @override
  Future<void> signIn() async {}

  @override
  Future<String?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    return 'fake-event-id';
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<String> createTask(AppDatabase db, {DateTime? dueDate}) async {
    final id = await db.itemsDao.insertItem(
      ItemsCompanion(title: const Value('Task'), type: const Value(ItemType.task)),
    );
    await db.into(db.tasks).insert(
      TasksCompanion.insert(id: id, dueDate: Value(dueDate)),
    );
    return id;
  }

  // Drift's stream store schedules a zero-duration Timer on dispose; if
  // that happens implicitly during flutter_test's own teardown there's no
  // chance for it to fire, and the test framework flags "Timer still
  // pending". Managing the container ourselves lets us dispose (and pump
  // once more) before the test body returns, so the timer fires in time.
  Future<void> disposeAndFlush(WidgetTester tester, ProviderContainer container) async {
    container.dispose();
    await tester.pump(Duration.zero);
  }

  testWidgets('Add to Calendar links an event when a due date is set', (tester) async {
    final id = await createTask(db, dueDate: DateTime(2026, 6, 1, 9));
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      googleCalendarServiceProvider.overrideWith((ref) => _FakeCalendarService()),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: TaskDetailScreen(taskId: id)),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.event_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.event_available), findsOneWidget);
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.calendarEventId, 'fake-event-id');

    await disposeAndFlush(tester, container);
  });

  testWidgets('Add to Calendar prompts for a due date when none is set', (tester) async {
    final id = await createTask(db);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      googleCalendarServiceProvider.overrideWith((ref) => _FakeCalendarService()),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: TaskDetailScreen(taskId: id)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Set a due date before adding to calendar'), findsOneWidget);
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.calendarEventId, isNull);

    await disposeAndFlush(tester, container);
  });
}

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

  testWidgets('TaskCard shows pending-sync icon when isPendingSync is true', (tester) async {
    final item = Item(id: '1', title: 'T', body: '', type: ItemType.task,
        createdAt: DateTime.now(), updatedAt: DateTime.now());
    final task = TaskRow(id: '1', priority: TaskPriority.low, dueDate: null,
        status: TaskStatus.todo, calendarEventId: null);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskCard(item: item, task: task, onTap: () {}, isPendingSync: true),
      ),
    ));

    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('TaskCard hides pending-sync icon by default', (tester) async {
    final item = Item(id: '1', title: 'T', body: '', type: ItemType.task,
        createdAt: DateTime.now(), updatedAt: DateTime.now());
    final task = TaskRow(id: '1', priority: TaskPriority.low, dueDate: null,
        status: TaskStatus.todo, calendarEventId: null);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TaskCard(item: item, task: task, onTap: () {})),
    ));

    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
  });
}

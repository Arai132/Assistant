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

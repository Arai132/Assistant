import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assistant_app/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AssistantApp()),
    );

    // Verify MaterialApp renders (GoRouter initializes asynchronously)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

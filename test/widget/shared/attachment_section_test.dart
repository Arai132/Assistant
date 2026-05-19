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

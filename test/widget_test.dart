import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assistant_app/app.dart';

void main() {
  testWidgets('AssistantApp renders scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AssistantApp()),
    );

    expect(find.text('Setting up...'), findsOneWidget);
  });
}

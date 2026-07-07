import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/providers/database_provider.dart';
import 'package:assistant_app/providers/calendar_provider.dart';
import 'package:assistant_app/services/google_calendar_service.dart';
import 'package:assistant_app/features/calendar/widgets/day_detail_panel.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? lastUrl;
  bool result = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    return result;
  }
}

class _FakeCalendarService extends GoogleCalendarService {
  final List<gcal.Event> events;
  _FakeCalendarService(this.events);

  @override
  Future<List<gcal.Event>> getEventsForDay(DateTime date) async => events;
}

void main() {
  late AppDatabase db;
  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() async => db.close());

  Future<void> disposeAndFlush(WidgetTester tester, ProviderContainer container) async {
    container.dispose();
    await tester.pump(Duration.zero);
  }

  testWidgets('tapping a calendar event opens its htmlLink', (tester) async {
    final event = gcal.Event()
      ..summary = 'Standup'
      ..htmlLink = 'https://calendar.google.com/event?eid=abc';

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      googleCalendarServiceProvider.overrideWith((ref) => _FakeCalendarService([event])),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: DayDetailPanel(date: DateTime(2026, 6, 1)))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Standup'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.lastUrl, 'https://calendar.google.com/event?eid=abc');

    await disposeAndFlush(tester, container);
  });

  testWidgets('tapping an event without a link shows a message instead', (tester) async {
    final event = gcal.Event()..summary = 'No link event';

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      googleCalendarServiceProvider.overrideWith((ref) => _FakeCalendarService([event])),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: DayDetailPanel(date: DateTime(2026, 6, 1)))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No link event'));
    await tester.pumpAndSettle();

    expect(find.text('No calendar link available for this event'), findsOneWidget);
    expect(fakeLauncher.lastUrl, isNull);

    await disposeAndFlush(tester, container);
  });
}

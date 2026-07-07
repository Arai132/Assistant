import 'package:drift/drift.dart' show TypedResult;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/calendar_provider.dart';
import '../../../providers/database_provider.dart';

class DayDetailPanel extends ConsumerWidget {
  final DateTime date;
  const DayDetailPanel({super.key, required this.date});

  Future<void> _openEvent(BuildContext context, gcal.Event event) async {
    final link = event.htmlLink;
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No calendar link available for this event')),
      );
      return;
    }
    final opened = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Calendar')),
      );
    }
  }

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
                  onTap: () => _openEvent(context, e),
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
}

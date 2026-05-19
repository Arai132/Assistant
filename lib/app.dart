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

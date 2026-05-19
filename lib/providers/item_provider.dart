import 'package:drift/drift.dart';
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

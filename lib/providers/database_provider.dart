import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/attachment_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(ref.watch(databaseProvider)),
);

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(databaseProvider)),
);

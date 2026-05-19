import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final attachmentsForItemProvider = StreamProvider.family<List<Attachment>, String>(
  (ref, itemId) => ref.watch(attachmentRepositoryProvider).watchForItem(itemId),
);

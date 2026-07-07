import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_sync_service.dart';
import 'database_provider.dart';

final syncServiceProvider = Provider<FirebaseSyncService>(
  (ref) => FirebaseSyncService(ref.watch(databaseProvider)),
);

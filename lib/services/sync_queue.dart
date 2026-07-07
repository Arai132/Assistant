import 'package:flutter/foundation.dart';

class SyncQueue extends ChangeNotifier {
  static final SyncQueue global = SyncQueue();

  final Set<String> _pending = {};

  void enqueue(String id) {
    if (_pending.add(id)) notifyListeners();
  }

  void dequeue(String id) {
    if (_pending.remove(id)) notifyListeners();
  }

  bool hasPending(String id) => _pending.contains(id);

  Set<String> get all => Set.unmodifiable(_pending);
}

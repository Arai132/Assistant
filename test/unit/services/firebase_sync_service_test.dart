import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/services/firebase_sync_service.dart';

void main() {
  test('syncQueueEntry marks item for sync', () {
    final queue = SyncQueue();
    queue.enqueue('item-1');
    expect(queue.hasPending('item-1'), isTrue);
  });

  test('dequeue removes item from queue', () {
    final queue = SyncQueue();
    queue.enqueue('item-1');
    queue.dequeue('item-1');
    expect(queue.hasPending('item-1'), isFalse);
  });
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/database/app_database.dart';

class SyncQueue {
  final Set<String> _pending = {};
  void enqueue(String id) => _pending.add(id);
  void dequeue(String id) => _pending.remove(id);
  bool hasPending(String id) => _pending.contains(id);
  Set<String> get all => Set.unmodifiable(_pending);
}

class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SyncQueue syncQueue = SyncQueue();

  FirebaseSyncService(this._db);

  Future<void> syncItem(Item item) async {
    await _firestore.collection('items').doc(item.id).set({
      'title': item.title,
      'body': item.body,
      'type': item.type.index,
      'updatedAt': item.updatedAt.toIso8601String(),
    }, SetOptions(merge: true));
    syncQueue.dequeue(item.id);
  }

  Future<void> syncAttachment(Attachment att) async {
    final file = File(att.localPath);
    if (!await file.exists()) return;
    final ref = _storage.ref('attachments/${att.id}${_ext(att.localPath)}');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db.attachmentsDao.updateOcrText(att.id, att.ocrText ?? ''); // re-save unchanged
    await _firestore.collection('attachments').doc(att.id).set({
      'itemId': att.itemId,
      'cloudUrl': url,
      'ocrText': att.ocrText,
      'aiDescription': att.aiDescription,
    }, SetOptions(merge: true));
  }

  String _ext(String path) {
    final e = path.contains('.') ? '.${path.split('.').last}' : '';
    return e;
  }

  Future<void> syncAll() async {
    final pending = List<String>.from(syncQueue.all);
    for (final id in pending) {
      final item = await _db.itemsDao.getItemById(id);
      if (item != null) await syncItem(item);
    }
    final attachments = await _db.select(_db.attachments).get();
    for (final att in attachments) {
      if (att.cloudUrl == null) await syncAttachment(att);
    }
  }
}

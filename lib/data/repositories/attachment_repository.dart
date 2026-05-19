import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

class AttachmentRepository {
  final AppDatabase _db;
  AttachmentRepository(this._db);

  Future<String> saveAttachment({
    required String itemId,
    required File sourceFile,
    required AttachmentType type,
  }) async {
    if (sourceFile.lengthSync() > 100 * 1024 * 1024) {
      throw Exception('File exceeds 100 MB limit');
    }
    final dir = await _attachmentDir();
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
    await sourceFile.copy(destPath);
    return _db.attachmentsDao.insertAttachment(
      AttachmentsCompanion(
        itemId: Value(itemId),
        type: Value(type),
        localPath: Value(destPath),
      ),
    );
  }

  Future<void> deleteAttachment(String id, String localPath) async {
    await _db.attachmentsDao.deleteAttachment(id);
    final file = File(localPath);
    if (await file.exists()) await file.delete();
  }

  Stream<List<Attachment>> watchForItem(String itemId) =>
      _db.attachmentsDao.watchForItem(itemId);

  Future<Directory> _attachmentDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}

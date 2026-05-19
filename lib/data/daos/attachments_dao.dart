import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  static const _uuid = Uuid();

  Future<String> insertAttachment(AttachmentsCompanion entry) async {
    final id = _uuid.v4();
    await into(attachments).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Stream<List<Attachment>> watchForItem(String itemId) =>
      (select(attachments)..where((t) => t.itemId.equals(itemId))).watch();

  Future<void> updateOcrText(String id, String text) =>
      (update(attachments)..where((t) => t.id.equals(id)))
          .write(AttachmentsCompanion(ocrText: Value(text)));

  Future<void> updateAiDescription(String id, String desc) =>
      (update(attachments)..where((t) => t.id.equals(id)))
          .write(AttachmentsCompanion(aiDescription: Value(desc)));

  Future<void> deleteAttachment(String id) =>
      (delete(attachments)..where((t) => t.id.equals(id))).go();
}

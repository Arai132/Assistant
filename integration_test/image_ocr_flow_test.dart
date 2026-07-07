import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:assistant_app/data/database/app_database.dart';
import 'package:assistant_app/data/repositories/attachment_repository.dart';
import 'package:assistant_app/features/shared/image_capture/ocr_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('image captured, OCR runs, saved as attachment', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AttachmentRepository(db);

    final itemId = await db.itemsDao.insertItem(
      ItemsCompanion.insert(title: const Value('Test note'), type: const Value(ItemType.note)),
    );

    // Use a test image file from assets (add a test_image.jpg to integration_test/assets/)
    final imageFile = File('integration_test/assets/test_image.jpg');
    if (!await imageFile.exists()) {
      markTestSkipped('test_image.jpg not present');
      return;
    }

    final attId = await repo.saveAttachment(
      itemId: itemId,
      sourceFile: imageFile,
      type: AttachmentType.image,
    );

    final ocr = OcrService();
    final text = await ocr.extractText(imageFile);
    await db.attachmentsDao.updateOcrText(attId, text);

    final attachments = await db.attachmentsDao.watchForItem(itemId).first;
    expect(attachments.length, 1);
    expect(attachments.first.type, AttachmentType.image);

    await db.close();
  });
}

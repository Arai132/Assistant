import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistant_app/features/shared/image_capture/ocr_service.dart';

void main() {
  test('OcrService.extractText returns empty string for non-existent file', () async {
    final svc = OcrService();
    final result = await svc.extractText(File('/tmp/nonexistent.jpg'));
    expect(result, isEmpty);
  });
}

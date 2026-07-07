import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) return '';
    try {
      final input = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(input);
      return result.text;
    } catch (_) {
      return '';
    }
  }

  void dispose() => _recognizer.close();
}

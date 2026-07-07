import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:assistant_app/services/voice_recorder_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('voice recorder starts and stops', (tester) async {
    final svc = VoiceRecorderService();
    await svc.init();
    await svc.startRecording();
    expect(svc.isRecording, isTrue);
    await Future.delayed(const Duration(milliseconds: 500));
    final savedPath = await svc.stopRecording();
    expect(svc.isRecording, isFalse);
    expect(savedPath, isNotNull);
    await svc.dispose();
  });
}

import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderOpen = false;
  bool _playerOpen = false;

  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _player.openPlayer();
    _recorderOpen = true;
    _playerOpen = true;
  }

  Future<String> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(
      dir.path,
      'attachments',
      'voice_${DateTime.now().millisecondsSinceEpoch}.aac',
    );
    await Directory(p.dirname(path)).create(recursive: true);
    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    return path;
  }

  Future<String?> stopRecording() => _recorder.stopRecorder();

  Future<void> playFile(String path) => _player.startPlayer(fromURI: path);

  Future<void> stopPlayback() => _player.stopPlayer();

  bool get isRecording => _recorder.isRecording;
  bool get isPlaying => _player.isPlaying;

  Future<void> dispose() async {
    if (_recorderOpen) await _recorder.closeRecorder();
    if (_playerOpen) await _player.closePlayer();
  }
}

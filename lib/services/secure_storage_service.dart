import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyOpenAi = 'openai_api_key';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getOpenAiKey() => _storage.read(key: _keyOpenAi);
  Future<void> setOpenAiKey(String key) => _storage.write(key: _keyOpenAi, value: key);
  Future<void> deleteOpenAiKey() => _storage.delete(key: _keyOpenAi);
}

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class AiDescriptionService {
  final String apiKey;
  final Dio _dio;

  AiDescriptionService({required this.apiKey}) : _dio = Dio();

  Future<String> describe(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      data: {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Describe the contents of this image in 1-2 sentences.'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          }
        ],
        'max_tokens': 200,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }
}

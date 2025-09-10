// lib/services/api_services_chatgpt.dart
//
// BYOK ChatGPT service (no proxy). The user pastes their OpenAI API key in
// Settings; we store it locally (secure) and use it here.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiChatGPTService {
  ApiChatGPTService();

  // Where we store the key securely on-device
  static const _kKeyName = 'openai_api_key';
  // OpenAI Chat Completions endpoint
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  final _storage = const FlutterSecureStorage();

  /// Ask ChatGPT and return plain text.
  Future<String> ask({
    required String prompt,
    String persona = 'Be concise and structured. Reply in ≤5 short bullets.',
    String model = 'gpt-4o-mini', // you can change this later via settings
  }) async {
    // 1) Read key
    final apiKey = await _storage.read(key: _kKeyName);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing API key. Open Settings and paste your OpenAI key.');
    }

    // 2) Call OpenAI
    final r = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': persona},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 600,
      }),
    );

    // 3) Handle response
    if (r.statusCode != 200) {
      throw Exception('ChatGPT error: ${r.statusCode} ${r.body}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final text = (data['choices']?[0]?['message']?['content'] as String? ?? '').trim();
    if (text.isEmpty) throw Exception('Empty ChatGPT response');
    return text;
  }
}
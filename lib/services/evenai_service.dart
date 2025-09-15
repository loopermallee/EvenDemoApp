import 'package:dio/dio.dart';

class EvenAIService {
  final Dio _dio = Dio();
  String? _apiKey;

  /// Set API key (from settings screen)
  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  /// Send query to ChatGPT Premium (BYOK)
  Future<String> sendQuery(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return "⚠️ No API key set. Please add it in Settings.";
    }

    try {
      final response = await _dio.post(
        "https://api.openai.com/v1/chat/completions",
        options: Options(
          headers: {"Authorization": "Bearer $_apiKey"},
        ),
        data: {
          "model": "gpt-4o-mini", // ✅ Fast, cost-effective ChatGPT model
          "messages": [
            {"role": "system", "content": "You are EvenAI, a helpful assistant."},
            {"role": "user", "content": prompt},
          ],
          "max_tokens": 500,
        },
      );

      return response.data["choices"][0]["message"]["content"].toString().trim();
    } catch (e) {
      return "❌ API Error: $e";
    }
  }
}
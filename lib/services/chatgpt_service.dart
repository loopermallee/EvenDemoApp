import 'dart:convert';
import 'package:dio/dio.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini"; // lightweight, good for real-time
  static String apiKey = ""; // 🔑 ENTER YOUR API KEY HERE

  static Future<String> askChatGPT(String query) async {
    if (apiKey.isEmpty) {
      return "⚠️ API key missing. Please update ChatGPTService.apiKey.";
    }

    try {
      final dio = Dio();
      final response = await dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
        ),
        data: {
          "model": _model,
          "messages": [
            {"role": "system", "content": "You are an assistant for smart glasses."},
            {"role": "user", "content": query}
          ],
          "max_tokens": 200,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data["choices"][0]["message"]["content"]?.trim() ??
            "⚠️ No response content";
      } else {
        return "⚠️ API Error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ ChatGPT request failed: $e";
    }
  }
}
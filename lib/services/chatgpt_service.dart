import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini"; // lightweight, real-time model

  /// Save API key
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("chatgpt_api_key", key);
  }

  /// Load API key
  static Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("chatgpt_api_key");
  }

  /// Ask ChatGPT
  static Future<String> askChatGPT(String query) async {
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "⚠️ API key missing. Please set it in Settings.";
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
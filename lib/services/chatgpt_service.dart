import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini"; // ✅ lightweight, real-time
  static String apiKey = "";

  /// Load API key from persistence (SharedPreferences)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString("chatgpt_api_key") ?? "";
  }

  /// Save API key to persistence
  static Future<void> setApiKey(String key) async {
    apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("chatgpt_api_key", key);
  }

  /// Ask ChatGPT a question
  static Future<String> askChatGPT(String query) async {
    if (apiKey.isEmpty) {
      return "⚠️ API key missing. Please enter it in Settings.";
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
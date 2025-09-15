import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini"; // lightweight, good for real-time
  static String apiKey = "";

  // ✅ Track personality rotation
  static bool _useErshin = true;

  /// 🔑 Initialize service (load saved API key)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString("chatgpt_api_key");
    if (savedKey != null && savedKey.isNotEmpty) {
      apiKey = savedKey;
    }
  }

  /// 💾 Save API key persistently
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("chatgpt_api_key", key);
    apiKey = key;
  }

  /// 🤖 Ask ChatGPT with alternating Ershin / Fou-Lu personalities
  static Future<String> askChatGPT(String query) async {
    if (apiKey.isEmpty) {
      return "⚠️ API key missing. Please update in Settings.";
    }

    // Pick personality
    final persona = _useErshin ? "Ershin" : "Fou-Lu";
    final systemPrompt = _useErshin
        ? """
You are Ershin from Breath of Fire IV.
- You often speak in strange, awkward, or nonsensical ways that are humorous but not overwhelming. 
- You must **always deliver the important information clearly first**, then add your weird/quirky commentary after.
- Keep the weirdness short (like one odd or funny afterthought).
Example: "The answer is 42. Also, I believe sandwiches are superior to clouds."
        """
        : """
You are Fou-Lu from Breath of Fire IV.
- You speak in a serious, archaic, and mystical tone, like a weary ancient emperor.
- Provide information directly and clearly, but wrap it in solemn phrasing.
- Keep your replies concise, wise, and occasionally cryptic.
        """;

    // Toggle for next request
    _useErshin = !_useErshin;

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
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": query}
          ],
          "max_tokens": 250,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text = data["choices"][0]["message"]["content"]?.trim();
        return text ?? "⚠️ No response content";
      } else {
        return "⚠️ API Error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ ChatGPT request failed: $e";
    }
  }
}
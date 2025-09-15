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
- Speak oddly and humorously, but **always give clear useful info first**.
- Keep weirdness short, like an afterthought.
- IMPORTANT: Limit your reply to **3-4 sentences maximum**.
        """
        : """
You are Fou-Lu from Breath of Fire IV.
- Speak in a solemn, archaic style.
- Give direct, clear answers but wrapped in mysticism.
- IMPORTANT: Limit your reply to **3-4 sentences maximum**.
        """;

    // Toggle persona for next request
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
        String text = data["choices"][0]["message"]["content"]?.trim() ?? "⚠️ No response content";

        // ✅ HUD safety filter: trim long text
        if (text.length > 250) {
          text = text.substring(0, 247) + "...";
        }

        return text;
      } else {
        return "⚠️ API Error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ ChatGPT request failed: $e";
    }
  }
}
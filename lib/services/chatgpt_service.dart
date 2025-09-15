import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini"; // lightweight, good for real-time
  static String apiKey = "";

  // ✅ Alternate between Ershin and Fou-Lu
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
  /// Returns structured response with speaker + pages
  static Future<Map<String, dynamic>> askChatGPT(String query) async {
    if (apiKey.isEmpty) {
      return {
        "speaker": "⚠️",
        "pages": ["API key missing. Please update in Settings."]
      };
    }

    // Pick personality
    final isErshin = _useErshin;
    final speaker = isErshin ? "Ershin" : "Fou-Lu";

    final systemPrompt = isErshin
        ? """
You are Ershin from Breath of Fire IV.
- Always give the clear, useful info FIRST.
- Then, add short, odd or humorous remarks (nonsense is fine).
- IMPORTANT: Limit reply to **3-4 short sentences maximum**.
"""
        : """
You are Fou-Lu from Breath of Fire IV.
- Speak in solemn, archaic style.
- Wrap clear answers in mysticism.
- IMPORTANT: Limit reply to **3-4 short sentences maximum**.
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
        String text = data["choices"][0]["message"]["content"]?.trim() ??
            "⚠️ No response content";

        // ✅ Trim overly long replies
        if (text.length > 400) {
          text = text.substring(0, 397) + "...";
        }

        // ✅ Split into “pages” for HUD readability
        final pages = _splitIntoPages(text);

        // ✅ Add retro speaker tag styling
        return {
          "speaker": speaker,
          "pages": pages.map((p) {
            return isErshin ? "[Ershin]: ✧ $p ✧" : "[Fou-Lu]: ~ $p ~";
          }).toList(),
        };
      } else {
        return {
          "speaker": "⚠️",
          "pages": ["API Error: ${response.statusCode}"]
        };
      }
    } catch (e) {
      return {
        "speaker": "⚠️",
        "pages": ["ChatGPT request failed: $e"]
      };
    }
  }

  /// ✂️ Break long replies into pages of ~120 chars max
  static List<String> _splitIntoPages(String text) {
    const int maxLen = 120;
    final words = text.split(" ");
    final pages = <String>[];
    var buffer = StringBuffer();

    for (var word in words) {
      if ((buffer.length + word.length + 1) > maxLen) {
        pages.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write("$word ");
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }

    return pages;
  }
}
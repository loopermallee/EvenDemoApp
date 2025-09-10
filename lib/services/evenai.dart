// lib/services/evenai.dart
//
// Front door for AI. Uses the BYOK ChatGPT service.

import 'package:demo_ai_even/services/api_services_chatgpt.dart';

class EvenAI {
  EvenAI._();
  static final ApiChatGPTService _api = ApiChatGPTService();

  static Future<String> answer({
    required String userText,
    String persona = 'Be concise and structured.',
  }) {
    return _api.ask(prompt: userText, persona: persona);
  }
}
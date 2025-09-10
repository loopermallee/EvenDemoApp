// lib/services/evenai.dart
//
// Front door for AI. Uses BYOK ChatGPT service with secure storage.
// Provides a textStream and syncing flag so UI (home_page) works.

import 'dart:async';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';

class EvenAI {
  EvenAI._();

  static final ApiChatGPTService _api = ApiChatGPTService();

  // Exposed reactive state for UI
  static final isEvenAISyncing = false.obs;

  // Stream for latest AI text
  static final StreamController<String> _textController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textController.stream;

  /// Ask ChatGPT and push the result into the stream.
  static Future<void> askAndStream({
    required String userText,
    String persona = 'Be concise and structured.',
  }) async {
    try {
      isEvenAISyncing.value = true;
      _textController.add("Thinking…");

      final answer = await _api.ask(
        prompt: userText,
        persona: persona,
      );

      _textController.add(answer);
    } catch (e) {
      _textController.add("Error: $e");
    } finally {
      isEvenAISyncing.value = false;
    }
  }

  /// For direct use (without stream)
  static Future<String> answer({
    required String userText,
    String persona = 'Be concise and structured.',
  }) {
    return _api.ask(prompt: userText, persona: persona);
  }
}
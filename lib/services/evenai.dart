// lib/services/evenai.dart
//
// Front door for AI. BYOK ChatGPT service (no proxy) + glue for BLE/STT.
// Exposes the members other parts of the app expect (isEvenAIOpen, isEvenAISyncing, stopEvenAIByOS, etc).

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';
import 'package:demo_ai_even/services/text_service.dart';

class EvenAI {
  EvenAI._();

  // IMPORTANT: several places call EvenAI.get() AND some call EvenAI.get
  // We'll support the method form, and you should use EvenAI.get() everywhere.
  static final EvenAI _inst = EvenAI._();
  static EvenAI get() => _inst;

  // State flags other files observe
  static final RxBool isEvenAISyncing = false.obs;
  static final ValueNotifier<bool> isEvenAIOpen = ValueNotifier<bool>(false);

  // Chat service
  static final ApiChatGPTService _api = ApiChatGPTService();

  // Transcript from native/ BLE (set by BleManager)
  static String? _pendingTranscript;

  /// Called by BleManager when a transcript arrives from native side
  static void setTranscript(String script) {
    _pendingTranscript = script.trim();
  }

  /// Optional simple API other code can call directly
  static Future<String> answer({
    required String userText,
    String persona = 'Be concise and structured.',
  }) {
    return _api.ask(prompt: userText, persona: persona);
  }

  /// OS/Glasses say "start Even AI"
  void toStartEvenAIByOS() {
    isEvenAIOpen.value = true;
  }

  /// OS/Glasses say "recording over" → use pending transcript with ChatGPT and display via TextService
  Future<void> recordOverByOS() async {
    final transcript = (_pendingTranscript ?? '').trim();
    if (transcript.isEmpty) {
      // no speech captured; nothing to do
      isEvenAISyncing.value = false;
      return;
    }

    try {
      isEvenAISyncing.value = true;

      // Progressive feedback: show we heard the user
      TextService.get.startSendText('🎤 You asked: "$transcript"\n\n⏳ Getting answer...');

      // Ask ChatGPT (BYOK key must be saved in Settings)
      final reply = await _api.ask(
        prompt: transcript,
        persona: 'Be concise and structured. Reply in ≤5 short bullets.',
      );

      // Smooth transition, then show answer (TextService handles paging to glasses)
      TextService.get.startSendText('🎤 You asked: "$transcript"\n\n✨ Answer ready...');
      TextService.get.startSendText(reply);
    } catch (e) {
      // Graceful error messaging
      TextService.get.startSendText(
        '❌ Error getting answer.\n\nDetails: ${e.toString()}\n\nTips:\n• Check internet\n• Open Settings and verify your OpenAI API key\n• Try again',
      );
    } finally {
      isEvenAISyncing.value = false;
      _pendingTranscript = null; // consume it
    }
  }

  /// Stop/cleanup when app/OS requests exit
  Future<void> stopEvenAIByOS() async {
    // If you need to cancel ongoing calls, add a cancel token pattern here.
    isEvenAIOpen.value = false;
    isEvenAISyncing.value = false;
    // Clear any pending transcript so a stale one isn't reused
    _pendingTranscript = null;
  }

  /// Paging hooks (touchpad). TextService timers drive paging; keep stubs here to satisfy calls.
  void nextPageByTouchpad() {
    // No-op for now. If you add manual paging, wire it into TextService.
  }

  void lastPageByTouchpad() {
    // No-op for now.
  }
}
// lib/services/evenai.dart
//
// BYOK ChatGPT front-door with:
//  - textStream (phone UI)
//  - isEvenAISyncing (spinner)
//  - BLE hooks used by BleManager (start/stop/next/prev)
//  - Sends pages to glasses via Proto.sendEvenAIData
//
// Requires:
//   - lib/services/api_services_chatgpt.dart
//   - lib/services/proto.dart

import 'dart:async';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';
import 'package:demo_ai_even/services/proto.dart';

class EvenAI {
  EvenAI._internal();
  static final EvenAI _instance = EvenAI._internal();
  static EvenAI get() => _instance; // used by BleManager

  // Phone UI state
  static final isEvenAISyncing = false.obs;
  static final StreamController<String> _textController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textController.stream;

  // ChatGPT BYOK
  static final ApiChatGPTService _api = ApiChatGPTService();

  // Paging state
  static List<String> _pages = <String>[];
  static int _pageIndex = 0;

  // Transcript stash set by BLE/Android event ("eventSpeechRecognize")
  static String? _pendingTranscript;
  static void setTranscript(String text) {
    _pendingTranscript = text;
  }

  // ===== BLE entry points =====

  /// Glasses say "start Even AI" (event 23)
  void toStartEvenAIByOS() {
    isEvenAISyncing.value = true;
    _pages = [];
    _pageIndex = 0;
    _textController.add("Listening… (release to send)");
  }

  /// Glasses say "record over" (event 24)
  Future<void> recordOverByOS() async {
    try {
      _textController.add("Thinking…");

      final transcript = (_pendingTranscript ?? '').trim();
      final prompt = transcript.isNotEmpty
          ? transcript
          : "Give 5 short, clear bullets for paramedic triage in the field.";

      final answer = await _api.ask(
        prompt: prompt,
        persona: "Paramedic shift assistant. Be concise. Use ≤5 short bullets.",
      );

      // Build pages for HUD
      _pages = _paginate(answer, maxLinesPerScreen: 5, maxCharsPerLine: 34);
      _pageIndex = 0;

      // Update phone UI
      _textController.add(_formatPage(_pages[_pageIndex]));

      // Send all pages to glasses (first page opens new screen)
      await _sendAllPagesToHud(_pages);
    } catch (e) {
      _textController.add("Error: $e");
    } finally {
      isEvenAISyncing.value = false;
      _pendingTranscript = null;
    }
  }

  /// Right tap → next page
  void nextPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex < _pages.length - 1) {
      _pageIndex++;
      _textController.add(_formatPage(_pages[_pageIndex]));
      _sendPageToHud(_pages[_pageIndex], _pageIndex, _pages.length, newScreen: 0);
    }
  }

  /// Left tap → previous page
  void lastPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex > 0) {
      _pageIndex--;
      _textController.add(_formatPage(_pages[_pageIndex]));
      _sendPageToHud(_pages[_pageIndex], _pageIndex, _pages.length
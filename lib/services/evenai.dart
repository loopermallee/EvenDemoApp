// lib/services/evenai.dart
//
// Front-door for AI (BYOK ChatGPT) with UI-friendly stream + spinner.
// Also provides the BLE-triggered methods your app expects.
// TEMP: recordOverByOS() uses a sample transcript until we wire real STT.
//
// Dependencies:
//   - lib/services/api_services_chatgpt.dart  (already added)

import 'dart:async';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';

class EvenAI {
  EvenAI._internal();
  static final EvenAI _instance = EvenAI._internal();
  static EvenAI get() => _instance; // for BleManager's EvenAI.get()

  // --- Public reactive state used by HomePage ---
  static final isEvenAISyncing = false.obs;

  static final StreamController<String> _textController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textController.stream;

  // --- ChatGPT (BYOK) service ---
  static final ApiChatGPTService _api = ApiChatGPTService();

  // --- Paging state (for left/right tap) ---
  static List<String> _pages = <String>[];
  static int _pageIndex = 0;

  // You can update this from wherever you collect the real transcript.
  static String? _pendingTranscript;
  static void setTranscript(String text) {
    _pendingTranscript = text;
  }

  // ===== BLE-exposed helpers =====

  /// Called when glasses send "start Even AI" (0xF5, 0x17).
  void toStartEvenAIByOS() {
    isEvenAISyncing.value = true;
    _pages = [];
    _pageIndex = 0;
    _textController.add("Listening… (release to send)");
  }

  /// Called when glasses send "record over" (0xF5, 0x18).
  /// We take the transcript (TODO: wire your real STT) -> call ChatGPT -> paginate -> show page 1.
  Future<void> recordOverByOS() async {
    // TODO: Replace this fallback with your real transcript source.
    final transcript = _pendingTranscript?.trim().isNotEmpty == true
        ? _pendingTranscript!.trim()
        : "Give 5 short, clear bullet tips for paramedic triage in the field.";

    await _askAndPaginate(
      userText: transcript,
      persona:
          "Paramedic shift assistant. Be concise. Use ≤5 short bullet points.",
    );
  }

  /// Next page on right tap.
  void nextPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex < _pages.length - 1) {
      _pageIndex++;
      _textController.add(_formatPage(_pages[_pageIndex]));
    }
  }

  /// Previous page on left tap.
  void lastPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex > 0) {
      _pageIndex--;
      _textController.add(_formatPage(_pages[_pageIndex]));
    }
  }

  // ===== Direct call (if you want to bypass BLE flow) =====
  static Future<String> answer({
    required String userText,
    String persona = 'Be concise and structured.',
  }) async {
    return _api.ask(prompt: userText, persona: persona);
  }

  // ===== Internals =====

  Future<void> _askAndPaginate({
    required String userText,
    required String persona,
  }) async {
    try {
      isEvenAISyncing.value = true;
      _textController.add("Thinking…");

      final answer = await _api.ask(prompt: userText, persona: persona);

      // Build pages for tap navigation
      _pages = _paginate(answer, maxLinesPerScreen: 5, maxCharsPerLine: 34);
      _pageIndex = 0;

      if (_pages.isEmpty) {
        _textController.add("(no content)");
      } else {
        _textController.add(_formatPage(_pages[_pageIndex]));
      }
    } catch (e) {
      _textController.add("Error: $e");
    } finally {
      isEvenAISyncing.value = false;
      // reset pending transcript after use
      _pendingTranscript = null;
    }
  }

  static String _formatPage(String body) {
    if (_pages.isEmpty) return body;
    return "$body\n\n[${_pageIndex + 1}/${_pages.length}]";
  }

  static List<String> _paginate(
    String text, {
    required int maxLinesPerScreen,
    required int maxCharsPerLine,
  }) {
    final cleaned = text.replaceAll('\r', ' ').replaceAll('\t', ' ');
    final words = cleaned.split(RegExp(r'\s+'));
    final lines = <String>[];
    final buf = StringBuffer();

    for (final w in words) {
      if (buf.isEmpty) {
        buf.write(w);
      } else if ((buf.length + 1 + w.length) <= maxCharsPerLine) {
        buf.write(' ');
        buf.write(w);
      } else {
        lines.add(buf.toString());
        buf.clear();
        buf.write(w);
      }
    }
    if (buf.isNotEmpty) lines.add(buf.toString());

    final pages = <String>[];
    for (var i = 0; i < lines.length; i += maxLinesPerScreen) {
      final end = (i + maxLinesPerScreen) > lines.length
          ? lines.length
          : i + maxLinesPerScreen;
      pages.add(lines.sublist(i, end).join('\n'));
    }
    return pages.isEmpty ? <String>["(no content)"] : pages;
  }
}
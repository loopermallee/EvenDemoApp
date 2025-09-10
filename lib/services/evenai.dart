// lib/services/evenai.dart
//
// BYOK ChatGPT "front door" with:
//  - textStream (for phone UI)
//  - isEvenAISyncing (for spinner)
//  - BLE hooks EvenAI.get().toStartEvenAIByOS(), recordOverByOS(), next/lastPage
//  - Sends pages to the glasses via Proto.sendEvenAIData
//
// Requires:
//   - lib/services/api_services_chatgpt.dart  (BYOK client)
//   - lib/services/proto.dart                 (for BLE page sending)

import 'dart:async';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';
import 'package:demo_ai_even/services/proto.dart';

class EvenAI {
  EvenAI._internal();
  static final EvenAI _instance = EvenAI._internal();
  static EvenAI get() => _instance; // used by BleManager

  // For phone UI
  static final isEvenAISyncing = false.obs;
  static final StreamController<String> _textController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textController.stream;

  // ChatGPT BYOK
  static final ApiChatGPTService _api = ApiChatGPTService();

  // Paging state
  static List<String> _pages = <String>[];
  static int _pageIndex = 0;

  // Where we stash the live transcript until "record over"
  static String? _pendingTranscript;
  static void setTranscript(String text) {
    _pendingTranscript = text;
  }

  // ===== BLE entry points (these are called from BleManager) =====

  /// Glasses said "start Even AI" (0xF5, index 23)
  void toStartEvenAIByOS() {
    isEvenAISyncing.value = true;
    _pages = [];
    _pageIndex = 0;
    _textController.add("Listening… (release to send)");
    // If you have an STT start trigger, fire it here.
  }

  /// Glasses said "record over" (0xF5, index 24)
  /// We take whatever transcript we have, call ChatGPT, paginate, send to HUD.
  Future<void> recordOverByOS() async {
    // TODO: wire your real STT transcript into setTranscript() where you capture it.
    final transcript = _pendingTranscript?.trim().isNotEmpty == true
        ? _pendingTranscript!.trim()
        : "Give 5 short, clear bullets for paramedic triage in the field."; // fallback demo

    await _askAndSend(
      userText: transcript,
      persona: "Paramedic shift assistant. Be concise. Use ≤5 short bullets.",
    );
  }

  /// Right tap → next page
  void nextPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex < _pages.length - 1) {
      _pageIndex++;
      _textController.add(_formatPage(_pages[_pageIndex]));
      // Re-send just this page with updated index (optional)
      _sendPageToHud(_pages[_pageIndex], _pageIndex, _pages.length, newScreen: 0);
    }
  }

  /// Left tap → previous page
  void lastPageByTouchpad() {
    if (_pages.isEmpty) return;
    if (_pageIndex > 0) {
      _pageIndex--;
      _textController.add(_formatPage(_pages[_pageIndex]));
      // Re-send just this page with updated index (optional)
      _sendPageToHud(_pages[_pageIndex], _pageIndex, _pages.length, newScreen: 0);
    }
  }

  // ===== Direct helper (if some code wants raw text back) =====
  static Future<String> answer({
    required String userText,
    String persona = 'Be concise and structured.',
  }) {
    return _api.ask(prompt: userText, persona: persona);
  }

  // ===== Internals =====

  Future<void> _askAndSend({
    required String userText,
    required String persona,
  }) async {
    try {
      isEvenAISyncing.value = true;
      _textController.add("Thinking…");

      final answer = await _api.ask(prompt: userText, persona: persona);

      // 1) Build pages for HUD
      _pages = _paginate(answer, maxLinesPerScreen: 5, maxCharsPerLine: 34);
      _pageIndex = 0;

      // 2) Update phone UI
      _textController.add(_formatPage(_pages[_pageIndex]));

      // 3) Send ALL pages to the glasses once (first page triggers new screen)
      await _sendAllPagesToHud(_pages);

    } catch (e) {
      _textController.add("Error: $e");
    } finally {
      isEvenAISyncing.value = false;
      _pendingTranscript = null; // clear after use
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

  Future<void> _sendAllPagesToHud(List<String> pages) async {
    final total = pages.length;
    for (var i = 0; i < total; i++) {
      final text = pages[i];
      final isFirst = (i == 0);
      await _sendPageToHud(text, i, total, newScreen: isFirst ? 1 : 0);
      // Small pacing gaps if needed; currently omitted.
    }
  }

  Future<void> _sendPageToHud(
    String text,
    int index,
    int total, {
    required int newScreen, // 1 for first page, else 0
  }) async {
    // pos is usually 0 for fresh page render
    await Proto.sendEvenAIData(
      text,
      newScreen: newScreen,
      pos: 0,
      current_page_num: index + 1,
      max_page_num: total,
    );
  }
}
// lib/services/evenai.dart
//
// BYOK ChatGPT front-door with:
//  - textStream (phone UI)
//  - isEvenAISyncing (GetX)  [spinner]
//  - isEvenAIOpen (ValueNotifier<bool>)  [used by app.dart]
//  - BLE hooks (start/stop/next/prev)
//  - Sends pages to glasses via Proto.sendEvenAIData
//
// Requires:
//   - lib/services/api_services_chatgpt.dart
//   - lib/services/proto.dart
//   - lib/services/stt_service.dart (stub provided)

import 'dart:async';
import 'package:flutter/foundation.dart'; // ValueNotifier
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/services/stt_service.dart';

class EvenAI {
  EvenAI._internal();
  static final EvenAI _instance = EvenAI._internal();
  static EvenAI get() => _instance; // used by BleManager & others

  // ===== Phone UI state =====
  static final isEvenAISyncing = false.obs;              // spinner
  static final ValueNotifier<bool> isEvenAIOpen =         // app.dart expects this
      ValueNotifier<bool>(false);

  static final StreamController<String> _textController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textController.stream;

  // ===== ChatGPT BYOK =====
  static final ApiChatGPTService _api = ApiChatGPTService();

  // ===== Paging state =====
  static List<String> _pages = <String>[];
  static int _pageIndex = 0;

  // ===== Transcript stash (Android pushes via EventChannel) =====
  static String? _pendingTranscript;
  static void setTranscript(String text) {
    _pendingTranscript = text;
    
    // Display real-time transcription on glasses
    if (isEvenAIOpen.value && text.trim().isNotEmpty) {
      _textController.add("Listening: $text");
      
      // Send to glasses display immediately
      Proto.sendEvenAIData(
        "🎤 $text",
        newScreen: 1,
        pos: 0,
        current_page_num: 1,
        max_page_num: 1,
      );
    }
  }

  // ===== BLE entry points =====

  /// Glasses say "start Even AI" (event 23)
  void toStartEvenAIByOS() async {
    isEvenAIOpen.value = true;
    isEvenAISyncing.value = true;

    _pages = [];
    _pageIndex = 0;
    _textController.add("Listening… (release to send)");

    // Start STT if available (non-fatal if not)
    try {
      await STTService.instance.startListening();
    } catch (_) {}
  }

  /// Glasses say "record over" (event 24)
  Future<void> recordOverByOS() async {
    try {
      _textController.add("Thinking…");

      // Prefer native transcript from Android; fallback to STT stub/plugin if any.
      String transcript = (_pendingTranscript ?? '').trim();
      if (transcript.isEmpty) {
        try {
          transcript = (await STTService.instance.stopAndGetTranscript()).trim();
        } catch (_) {}
      }

      final prompt = transcript.isNotEmpty
          ? transcript
          : "What are the key steps in emergency patient assessment?";

      final answer = await _api.ask(
        prompt: prompt,
        persona: "Provide clear, structured explanations optimized for small screen display. Use 3-5 main points with brief supporting details. Keep each line under 34 characters. Structure as bullet points when possible. Be comprehensive but concise - aim for 100-150 words total that can be split across 2-3 screen pages.",
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
      isEvenAIOpen.value = false;
      _pendingTranscript = null;
      try { await STTService.instance.cancel(); } catch (_) {}
    }
  }

  /// STOP immediately (app.dart calls this statically)
  static Future<void> stopEvenAIByOS() => _instance._stopEvenAIByOS();
  Future<void> _stopEvenAIByOS() async {
    try {
      try { await STTService.instance.cancel(); } catch (_) {}
      _pendingTranscript = null;
      _pages = [];
      _pageIndex = 0;
      _textController.add("Stopped.");
    } catch (e) {
      _textController.add("Stopped with error: $e");
    } finally {
      isEvenAISyncing.value = false;
      isEvenAIOpen.value = false;
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
      _sendPageToHud(_pages[_pageIndex], _pageIndex, _pages.length, newScreen: 0);
    }
  }

  // Optional: direct answer()
  static Future<String> answer({
    required String userText,
    String persona = 'Provide clear, structured explanations optimized for small screen display.',
  }) => _api.ask(prompt: userText, persona: persona);

  // ===== Internals =====

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

    var currentLine = '';
    for (final w in words) {
      if (w.isEmpty) continue;
      if (currentLine.isEmpty) {
        currentLine = w;
      } else if (currentLine.length + 1 + w.length <= maxCharsPerLine) {
        currentLine = "$currentLine $w";
      } else {
        lines.add(currentLine);
        currentLine = w;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);

    final pages = <String>[];
    for (var i = 0; i < lines.length; i += maxLinesPerScreen) {
      final end = (i + maxLinesPerScreen > lines.length)
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
    }
  }

  Future<void> _sendPageToHud(
    String text,
    int index,
    int total, {
    required int newScreen, // 1 for first page, else 0
  }) async {
    await Proto.sendEvenAIData(
      text,
      newScreen: newScreen,
      pos: 0,
      current_page_num: index + 1,
      max_page_num: total,
    );
  }
}

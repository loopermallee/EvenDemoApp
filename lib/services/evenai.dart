// lib/services/evenai.dart
//
// BYOK ChatGPT front-door with:
//  - textStream (phone UI)
//  - isEvenAISyncing (spinner)
//  - isEvenAIOpen (compat flag used by app.dart)
//  - BLE hooks used by BleManager (start/stop/next/prev)
//  - Sends pages to glasses via Proto.sendEvenAIData
//  - Optional STT support if you added stt_service.dart
//
// Requires:
//   - lib/services/api_services_chatgpt.dart
//   - lib/services/proto.dart
//
// NOTE: We also define EvenAIDataMethod here, because text_service.dart calls it.

import 'dart:async';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/api_services_chatgpt.dart';
import 'package:demo_ai_even/services/proto.dart';

// If you added STT earlier, keep this import. If not, you can comment it.
// It’s safe to leave it imported even if not used on iOS.
import 'package:demo_ai_even/services/stt_service.dart';

class EvenAI {
  EvenAI._internal();
  static final EvenAI _instance = EvenAI._internal();
  static EvenAI get() => _instance; // used by BleManager and app.dart

  // ===== Phone UI state =====
  static final isEvenAISyncing = false.obs; // spinner
  static final isEvenAIOpen = false
      .obs; // <-- ADDED: app.dart expects this to exist (true when listening/active)

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
  }

  // ===== BLE entry points =====

  /// Glasses say "start Even AI" (event 23)
  void toStartEvenAIByOS() async {
    isEvenAIOpen.value = true;
    isEvenAISyncing.value = true;
    _pages = [];
    _pageIndex = 0;
    _textController.add("Listening… (release to send)");

    // If STT service exists, start it. If not, this is a no-op.
    try {
      await STTService.instance.startListening();
    } catch (_) {
      // Non-fatal; transcript can still arrive from Android native side
    }
  }

  /// Glasses say "record over" (event 24)
  Future<void> recordOverByOS() async {
    try {
      _textController.add("Thinking…");

      // Prefer native transcript if available; else pull from STT plugin if present.
      String transcript = (_pendingTranscript ?? '').trim();
      if (transcript.isEmpty) {
        try {
          transcript = (await STTService.instance.stopAndGetTranscript()).trim();
        } catch (_) {
          // ignore
        }
      }

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
      isEvenAIOpen.value = false; // recording/interaction done
      _pendingTranscript = null;
      // Best effort: stop STT if still running
      try {
        await STTService.instance.cancel();
      } catch (_) {}
    }
  }

  /// ADDED: app.dart calls this (stop Even AI immediately)
  Future<void> stopEvenAIByOS() async {
    try {
      // Cancel STT if running; do not call ChatGPT
      try {
        await STTService.instance.cancel();
      } catch (_) {}
      _pendingTranscript = null;

      // Clear local state
      _pages = [];
      _pageIndex = 0;

      // Optional: tell HUD to exit? (Proto.exit() will close current func)
      // await Proto.exit();

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
    String persona = 'Be concise and structured.',
  }) {
    return _api.ask(prompt: userText, persona: persona);
  }

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

///
/// Helpers expected by text_service.dart
///
class EvenAIDataMethod {
  /// Split long text into lines that fit the HUD (≈34 chars per line), then
  /// return a list of those lines. text_service.dart pages 5 lines per screen.
  static List<String> measureStringList(String text,
      {int maxCharsPerLine = 34}) {
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

    // Safety: never return empty list
    return lines.isEmpty ? <String>["(no content)"] : lines;
  }

  /// Your firmware appears to open a new screen when type==0x01.
  /// Keep it simple and compatible with existing code.
  static int transferToNewScreen(int type, int status) {
    return (type == 0x01) ? 1 : 0;
  }
}
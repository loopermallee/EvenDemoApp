// lib/services/evenai.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/services/chatgpt_service.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/services/gesture_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class EvenAI extends GetxController {
  var isRunning = false.obs;
  var isSyncing = false.obs;
  var isReceivingAudio = false.obs;
  var lastTranscript = "".obs;

  List<int> audioDataBuffer = [];
  Uint8List? audioData;

  File? lc3File;
  File? pcmFile;

  int _lastStartTime = 0;
  int _lastStopTime = 0;
  final int startTimeGap = 500;
  final int stopTimeGap = 500;

  int durationS = 0;
  int retryCount = 0;
  static int maxRetry = 10;

  static int _currentLine = 0;
  static List<String> list = [];
  static List<String> sendReplys = [];

  static Timer? _timer;
  static Timer? _countdownTimer;
  static int _countdown = 0;

  Timer? _recordingTimer;
  final int maxRecordingDuration = 30;
  static bool _isManual = false;

  String combinedText = "";

  /// ▶️ Start AI listening (BLE mic on)
  Future<void> startListening(Uint8List audioBytes) async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStartTime < startTimeGap) return;
    _lastStartTime = currentTime;

    clear();
    isReceivingAudio.value = true;
    isRunning.value = true;
    _currentLine = 0;

    // 🧹 Clear HUD when AI session starts
    GestureHandler.hudMessage.value = null;
    print("[HUD] 🧹 Cleared for AI session");

    await BleManager.invokeMethod("startEvenAI");
    await openEvenAIMic();
    startRecordingTimer();

    print("[AI] ▶️ Listening started, processing audio...");
    await _processAudio(audioBytes);
  }

  void startRecordingTimer() {
    _recordingTimer = Timer(Duration(seconds: maxRecordingDuration), () {
      if (isReceivingAudio.value) {
        clear();
        GestureHandler.showPagedHUD("⚠️ Mic timeout");
        print("[BLE] ⏱️ Mic timeout reached");
      } else {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  /// Internal pipeline: BLE Audio → ChatGPT → HUD
  Future<void> _processAudio(Uint8List audioBytes) async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStopTime < stopTimeGap) return;
    _lastStopTime = currentTime;

    isReceivingAudio.value = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await BleManager.invokeMethod("stopEvenAI");

    // ✅ Skip STT — we’re already receiving processed data from glasses
    combinedText = "[Audio received: ${audioBytes.length} bytes]";
    lastTranscript.value = combinedText;
    print("[BLE] 🎤 Captured ${audioBytes.length} bytes of audio");

    // Step 2: ChatGPT
    print("[GPT] 📤 Sending to ChatGPT: $combinedText");
    final result = await ChatGPTService.askChatGPT(combinedText);

    final speaker = result["speaker"] as String;
    final pages = (result["pages"] as List<String>);
    final reply = pages.join("\n\n");

    GestureHandler.showPagedHUD("$speaker: $reply");
    isSyncing.value = false;

    print("[GPT] 📥 ChatGPT replied ($speaker): $reply");
    saveQuestionItem(combinedText, reply);
    startSendReply(reply);

    // ✅ Mark HUD ready after AI reply
    isRunning.value = false;
    print("[AI] ✅ Session finished, HUD ready for notifications");
  }

  void saveQuestionItem(String title, String content) {
    final controller = Get.find<EvenaiModelController>();
    controller.addItem(title, content);
    print("[AI] 💾 Saved Q&A pair to history");
  }

  Future startSendReply(String text) async {
    _currentLine = 0;
    list = EvenAIDataMethod.measureStringList(text);

    if (list.isEmpty) {
      print("[HUD] ⚠️ Empty reply, nothing to send");
      return;
    }

    String firstScreen =
        list.sublist(0, min(5, list.length)).map((s) => '$s\n').join();
    bool isSuccess = await sendEvenAIReply(firstScreen, 0x01, 0x30, 0);

    if (isSuccess) {
      _currentLine = 0;
      print("[HUD] 📟 First reply sent to HUD");
      await updateReplyToOSByTimer();
    } else {
      clear();
      GestureHandler.showPagedHUD("⚠️ Failed to send reply");
      print("[HUD] ❌ Failed to send reply");
    }
  }

  /// ⏳ Auto page updates + dynamic countdown
  Future updateReplyToOSByTimer() async {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isManual) {
        print("[HUD] 🛑 Manual navigation, stopping auto-paging");
        _stopCountdown();
        _timer?.cancel();
        _timer = null;
        return;
      }

      _currentLine = min(_currentLine + 5, list.length - 1);
      sendReplys = list.sublist(_currentLine);

      if (_currentLine > list.length - 1) {
        print("[HUD] ✅ Reached end of pages");
        _stopCountdown();
        _timer?.cancel();
        _timer = null;
      } else {
        var mergedStr =
            sendReplys.sublist(0, min(5, sendReplys.length)).map((s) => '$s\n').join();

        await sendEvenAIReply(
          mergedStr,
          0x01,
          (_currentLine >= list.length - 5) ? 0x40 : 0x30,
          0,
        );

        int seconds = _estimateDisplayTime(mergedStr);
        print("[HUD] ⏳ Next page in $seconds sec");
        _startCountdown(seconds);
      }
    });
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    _countdown = seconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        _stopCountdown();
      } else {
        GestureHandler.hudMessage.value = "Next page in $_countdown…";
        _countdown--;
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    GestureHandler.hudMessage.value = null;
  }

  Future<bool> sendEvenAIReply(String text, int type, int status, int pos) async {
    if (!isRunning.value) return false;

    bool isSuccess = await Proto.sendEvenAIData(
      text,
      newScreen: EvenAIDataMethod.transferToNewScreen(type, status),
      pos: pos,
      current_page_num: getCurrentPage(),
      max_page_num: getTotalPages(),
    );

    if (isSuccess) {
      print("[HUD] 📟 Sent reply chunk → $text");
    } else if (retryCount < maxRetry) {
      retryCount++;
      print("[HUD] 🔄 Retry $retryCount sending reply...");
      return await sendEvenAIReply(text, type, status, pos);
    } else {
      print("[HUD] ❌ Failed after max retries");
    }

    retryCount = 0;
    return isSuccess;
  }
}

extension EvenAIDataMethod on EvenAI {
  static int transferToNewScreen(int type, int status) {
    return status | type;
  }

  static List<String> measureStringList(String text, [double? maxW]) {
    final double maxWidth = maxW ?? 488;
    const double fontSize = 21;
    List<String> paragraphs = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    List<String> ret = [];
    TextStyle ts = const TextStyle(fontSize: fontSize);

    for (String paragraph in paragraphs) {
      final textSpan = TextSpan(text: paragraph, style: ts);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(maxWidth: maxWidth);

      final lineCount = textPainter.computeLineMetrics().length;
      var start = 0;
      for (var i = 0; i < lineCount; i++) {
        final line = textPainter.getLineBoundary(TextPosition(offset: start));
        ret.add(paragraph.substring(line.start, line.end).trim());
        start = line.end;
      }
    }
    return ret;
  }
}
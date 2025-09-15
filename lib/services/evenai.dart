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
import 'package:demo_ai_even/services/stt_service.dart';
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

    await BleManager.invokeMethod("startEvenAI");
    await openEvenAIMic();
    startRecordingTimer();

    // Directly process this audioBytes once recording ends
    await _processAudio(audioBytes);
  }

  void startRecordingTimer() {
    _recordingTimer = Timer(Duration(seconds: maxRecordingDuration), () {
      if (isReceivingAudio.value) {
        clear();
      } else {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  /// Internal pipeline: STT → ChatGPT → HUD
  Future<void> _processAudio(Uint8List audioBytes) async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStopTime < stopTimeGap) return;
    _lastStopTime = currentTime;

    isReceivingAudio.value = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await BleManager.invokeMethod("stopEvenAI");

    // Step 1: STT
    final transcript = await STTService.transcribe(audioBytes);
    if (transcript == null || transcript.isEmpty) {
      lastTranscript.value = "No Speech Recognized";
      isSyncing.value = false;
      startSendReply("No Speech Recognized");
      return;
    }

    combinedText = transcript;
    lastTranscript.value = transcript;

    // Step 2: ChatGPT
    final result = await ChatGPTService.askChatGPT(combinedText);

    final speaker = result["speaker"] as String;
    final pages = (result["pages"] as List<String>);
    final reply = pages.join("\n\n");

    GestureHandler.hudMessage.value = "$speaker: $reply";
    isSyncing.value = false;

    saveQuestionItem(combinedText, reply);
    startSendReply(reply);
  }

  void saveQuestionItem(String title, String content) {
    final controller = Get.find<EvenaiModelController>();
    controller.addItem(title, content);
  }

  int getTotalPages() {
    if (list.isEmpty) return 0;
    if (list.length < 6) return 1;
    int div = list.length ~/ 5;
    int rest = list.length % 5;
    return rest == 0 ? div : div + 1;
  }

  int getCurrentPage() {
    if (_currentLine == 0) return 1;
    int div = _currentLine ~/ 5;
    int rest = _currentLine % 5;
    return rest == 0 ? div + 1 : div + 2;
  }

  Future startSendReply(String text) async {
    _currentLine = 0;
    list = EvenAIDataMethod.measureStringList(text);

    if (list.isEmpty) return;

    String firstScreen =
        list.sublist(0, min(5, list.length)).map((s) => '$s\n').join();
    bool isSuccess = await sendEvenAIReply(firstScreen, 0x01, 0x30, 0);

    if (isSuccess) {
      _currentLine = 0;
      await updateReplyToOSByTimer();
    } else {
      clear();
    }
  }

  /// ⏳ Auto page updates + dynamic countdown
  Future updateReplyToOSByTimer() async {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isManual) {
        _stopCountdown();
        _timer?.cancel();
        _timer = null;
        return;
      }

      _currentLine = min(_currentLine + 5, list.length - 1);
      sendReplys = list.sublist(_currentLine);

      if (_currentLine > list.length - 1) {
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

        // ✅ Start dynamic countdown
        int seconds = _estimateDisplayTime(mergedStr);
        _startCountdown(seconds);
      }
    });
  }

  int _estimateDisplayTime(String text) {
    if (text.length < 60) return 3; // short
    if (text.length < 150) return 5; // medium
    return 8; // long
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

  void nextPageByTouchpad() {
    if (!isRunning.value) return;
    _isManual = true;
    _stopCountdown();
    _timer?.cancel();
    _timer = null;

    if (_currentLine + 5 <= list.length - 1) {
      _currentLine += 5;
      updateReplyToOSByManual();
    }
  }

  void lastPageByTouchpad() {
    if (!isRunning.value) return;
    _isManual = true;
    _stopCountdown();
    _timer?.cancel();
    _timer = null;

    if (_currentLine - 5 >= 0) {
      _currentLine -= 5;
      updateReplyToOSByManual();
    }
  }

  Future updateReplyToOSByManual() async {
    if (_currentLine < 0 || _currentLine > list.length - 1) return;
    sendReplys = list.sublist(_currentLine);
    var mergedStr =
        sendReplys.sublist(0, min(5, sendReplys.length)).map((s) => '$s\n').join();
    await sendEvenAIReply(mergedStr, 0x01, 0x50, 0);
  }

  Future stopEvenAIByOS() async {
    isRunning.value = false;
    clear();
    await BleManager.invokeMethod("stopEvenAI");
  }

  void clear() {
    isReceivingAudio.value = false;
    isRunning.value = false;
    _isManual = false;
    _currentLine = 0;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    audioDataBuffer.clear();
    audioData = null;
    list = [];
    sendReplys = [];
    durationS = 0;
    retryCount = 0;
  }

  Future openEvenAIMic() async {
    final (micStartMs, isStartSucc) = await Proto.micOn(lr: "R");
    if (!isStartSucc && isReceivingAudio.value && isRunning.value) {
      await Future.delayed(const Duration(seconds: 1));
      await openEvenAIMic();
    }
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

    if (!isSuccess && retryCount < maxRetry) {
      retryCount++;
      return await sendEvenAIReply(text, type, status, pos);
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
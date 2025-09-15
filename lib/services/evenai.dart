import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/services/chatgpt_service.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/services/gesture_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EvenAI {
  static EvenAI? _instance;
  static EvenAI get get => _instance ??= EvenAI._();

  static bool _isRunning = false;
  static bool get isRunning => _isRunning;

  bool isReceivingAudio = false;
  List<int> audioDataBuffer = [];
  Uint8List? audioData;

  File? lc3File;
  File? pcmFile;
  int durationS = 0;

  static int maxRetry = 10;
  static int _currentLine = 0;
  static Timer? _timer; // Text sending timer
  static Timer? _countdownTimer; // Countdown display
  static int _countdown = 0;

  static List<String> list = [];
  static List<String> sendReplys = [];

  Timer? _recordingTimer;
  final int maxRecordingDuration = 30;

  static bool _isManual = false;

  static set isRunning(bool value) {
    _isRunning = value;
    isEvenAIOpen.value = value;
    isEvenAISyncing.value = value;
  }

  static RxBool isEvenAIOpen = false.obs;
  static RxBool isEvenAISyncing = false.obs;

  int _lastStartTime = 0;
  int _lastStopTime = 0;
  final int startTimeGap = 500;
  final int stopTimeGap = 500;

  static const _eventSpeechRecognize = "eventSpeechRecognize";
  final _eventSpeechRecognizeChannel =
      const EventChannel(_eventSpeechRecognize).receiveBroadcastStream(_eventSpeechRecognize);

  String combinedText = '';

  static final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  static Stream<String> get textStream => _textStreamController.stream;

  static void updateDynamicText(String newText) {
    _textStreamController.add(newText);
  }

  EvenAI._();

  void startListening() {
    combinedText = '';
    _eventSpeechRecognizeChannel.listen((event) {
      var txt = event["script"] as String;
      combinedText = txt;
    }, onError: (error) {
      print("Error in event: $error");
    });
  }

  // ▶️ Start Even AI
  void toStartEvenAIByOS() async {
    BleManager.get().startSendBeatHeart();
    startListening();

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStartTime < startTimeGap) return;
    _lastStartTime = currentTime;

    clear();
    isReceivingAudio = true;
    isRunning = true;
    _currentLine = 0;

    await BleManager.invokeMethod("startEvenAI");
    await openEvenAIMic();
    startRecordingTimer();
  }

  void startRecordingTimer() {
    _recordingTimer = Timer(Duration(seconds: maxRecordingDuration), () {
      if (isReceivingAudio) {
        clear();
      } else {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  // ⏹️ Stop mic → send text to ChatGPT
  Future<void> recordOverByOS() async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStopTime < stopTimeGap) return;
    _lastStopTime = currentTime;

    isReceivingAudio = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await BleManager.invokeMethod("stopEvenAI");
    await Future.delayed(Duration(seconds: 2));

    if (combinedText.isEmpty) {
      updateDynamicText("No Speech Recognized");
      isEvenAISyncing.value = false;
      startSendReply("No Speech Recognized");
      return;
    }

    final result = await ChatGPTService.askChatGPT(combinedText);

    final speaker = result["speaker"] as String;
    final pages = (result["pages"] as List<String>);
    final reply = pages.join("\n\n");

    updateDynamicText("$combinedText\n\n$reply");
    isEvenAISyncing.value = false;

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
    if (!isRunning) return;
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
    if (!isRunning) return;
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
    isRunning = false;
    clear();
    await BleManager.invokeMethod("stopEvenAI");
  }

  void clear() {
    isReceivingAudio = false;
    isRunning = false;
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
    if (!isStartSucc && isReceivingAudio && isRunning) {
      await Future.delayed(Duration(seconds: 1));
      await openEvenAIMic();
    }
  }

  int retryCount = 0;
  Future<bool> sendEvenAIReply(String text, int type, int status, int pos) async {
    if (!isRunning) return false;

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

  static void dispose() {
    _textStreamController.close();
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
    TextStyle ts = TextStyle(fontSize: fontSize);

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
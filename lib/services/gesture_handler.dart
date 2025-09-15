import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/services/chatgpt_service.dart'; // ✅ use ChatGPT only
import 'package:demo_ai_even/services/proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/gesture_handler.dart'; // ✅ countdown HUD

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
      const EventChannel(_eventSpeechRecognize)
          .receiveBroadcastStream(_eventSpeechRecognize);

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

  /// 🔹 receiving starting Even AI request from glasses
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
    _recordingTimer =
        Timer(Duration(seconds: maxRecordingDuration), () {
      if (isReceivingAudio) {
        clear();
      } else {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  Future<void> recordOverByOS() async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastStopTime < stopTimeGap) return;
    _lastStopTime = currentTime;

    isReceivingAudio = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await BleManager.invokeMethod("stopEvenAI");
    await Future.delayed(const Duration(seconds: 2));

    if (combinedText.isEmpty) {
      updateDynamicText("No Speech Recognized");
      isEvenAISyncing.value = false;
      startSendReply("No Speech Recognized");
      return;
    }

    final reply = await ChatGPTService.askChatGPT(combinedText);

    updateDynamicText("$combinedText\n\n${reply["pages"].join(" ")}");
    isEvenAISyncing.value = false;
    saveQuestionItem(combinedText, reply["pages"].join(" "));
    startSendReply(reply["pages"].join(" "));
  }

  void saveQuestionItem(String title, String content) {
    final controller = Get.find<EvenaiModelController>();
    controller.addItem(title, content);
  }

  int getTotalPages() {
    if (list.isEmpty) return 0;
    return (list.length / 5).ceil();
  }

  int getCurrentPage() {
    return (_currentLine / 5).ceil() + 1;
  }

  Future startSendReply(String text) async {
    _currentLine = 0;
    list = EvenAIDataMethod.measureStringList(text);

    if (list.length <= 5) {
      final mergedStr = list.join("\n");
      await sendEvenAIReply(mergedStr, 0x01, 0x30, 0);
      await Future.delayed(const Duration(seconds: 3));
      if (!_isManual) {
        await sendEvenAIReply(mergedStr, 0x01, 0x40, 0);
      }
      return;
    }

    final startScreenWords =
        list.sublist(0, 5).map((s) => "$s\n").join();
    final success =
        await sendEvenAIReply(startScreenWords, 0x01, 0x30, 0);

    if (success) {
      _currentLine = 0;
      await updateReplyToOSByTimer();
    } else {
      clear();
    }
  }

  Future updateReplyToOSByTimer() async {
    const int interval = 5;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: interval), (timer) async {
      if (_isManual) {
        _timer?.cancel();
        return;
      }

      _currentLine = min(_currentLine + 5, list.length - 1);
      sendReplys = list.sublist(_currentLine);

      if (_currentLine >= list.length - 1) {
        _timer?.cancel();
      }

      final mergedStr =
          sendReplys.take(5).map((s) => "$s\n").join();

      final isLast = _currentLine >= list.length - 5;
      await sendEvenAIReply(
        mergedStr,
        0x01,
        isLast ? 0x40 : 0x30,
        0,
      );

      // ✅ Show HUD countdown while auto-paging
      GestureHandler.startCountdown(interval);
    });
  }

  void nextPageByTouchpad() {
    if (!isRunning) return;
    _isManual = true;
    _timer?.cancel();

    if (_currentLine + 5 > list.length - 1) return;
    _currentLine += 5;
    updateReplyToOSByManual();
  }

  void lastPageByTouchpad() {
    if (!isRunning) return;
    _isManual = true;
    _timer?.cancel();

    if (_currentLine - 5 < 0) {
      _currentLine = 0;
    } else {
      _currentLine -= 5;
    }
    updateReplyToOSByManual();
  }

  Future updateReplyToOSByManual() async {
    sendReplys = list.sublist(_currentLine);
    final mergedStr =
        sendReplys.take(5).map((s) => "$s\n").join();
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
    _timer?.cancel();
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
      await Future.delayed(const Duration(seconds: 1));
      await openEvenAIMic();
    }
  }

  int retryCount = 0;
  Future<bool> sendEvenAIReply(
      String text, int type, int status, int pos) async {
    if (!isRunning) return false;

    final isSuccess = await Proto.sendEvenAIData(
      text,
      newScreen: EvenAIDataMethod.transferToNewScreen(type, status),
      pos: pos,
      current_page_num: getCurrentPage(),
      max_page_num: getTotalPages(),
    );

    if (!isSuccess) {
      if (retryCount < maxRetry) {
        retryCount++;
        await sendEvenAIReply(text, type, status, pos);
      } else {
        retryCount = 0;
        return false;
      }
    }
    retryCount = 0;
    return true;
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
    const double maxWidth = 488;
    const double fontSize = 21;

    final paragraphs = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final ret = <String>[];
    final ts = TextStyle(fontSize: fontSize);

    for (final paragraph in paragraphs) {
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
        final line =
            textPainter.getLineBoundary(TextPosition(offset: start));
        ret.add(paragraph.substring(line.start, line.end).trim());
        start = line.end;
      }
    }
    return ret;
  }
}
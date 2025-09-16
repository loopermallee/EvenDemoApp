// lib/services/evenai.dart
import 'dart:async';
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
  static EvenAI get to => Get.find<EvenAI>();

  var isRunning = false.obs;
  var isReceivingAudio = false.obs;
  var lastTranscript = "".obs;

  String combinedText = "";

  static int _currentLine = 0;
  static List<String> list = [];
  static List<String> sendReplys = [];

  static Timer? _timer;
  static Timer? _countdownTimer;
  static int _countdown = 0;
  static bool _isManual = false;

  /// ▶️ Glasses send raw audio (legacy) or transcript
  Future<void> startListening(Uint8List audioBytes) async {
    isRunning.value = true;
    isReceivingAudio.value = true;

    GestureHandler.hudMessage.value = null; // clear HUD
    await BleManager.invokeMethod("startEvenAI");

    // If raw audio comes, just show placeholder
    combinedText = "[Audio received: ${audioBytes.length} bytes]";
    await _processTranscript(combinedText);
  }

  /// ▶️ Glasses send transcript directly
  Future<void> processTranscript(String transcript) async {
    if (transcript.isEmpty) {
      GestureHandler.showHUD("⚠️ No speech detected");
      isRunning.value = false;
      return;
    }

    combinedText = transcript;
    lastTranscript.value = transcript;

    await _processTranscript(transcript);
  }

  /// Internal pipeline: Transcript → ChatGPT → HUD
  Future<void> _processTranscript(String text) async {
    isReceivingAudio.value = false;

    await BleManager.invokeMethod("stopEvenAI");

    // ✅ Fix: handle Map from ChatGPTService
    final result = await ChatGPTService.askChatGPT(text);
    final speaker = result["speaker"] as String;
    final pages = (result["pages"] as List<String>);
    final reply = pages.join("\n\n");

    // ✅ Show first page in HUD
    GestureHandler.hudMessage.value =
        pages.isNotEmpty ? "$speaker: ${pages.first}" : "$speaker: $reply";

    saveQuestionItem(text, reply);
    startSendReply(reply);

    isRunning.value = false;
    print("✅ AI session finished, HUD ready for notifications");
  }

  void saveQuestionItem(String title, String content) {
    final controller = Get.find<EvenaiModelController>();
    controller.addItem(title, content);
  }

  Future startSendReply(String text) async {
    _currentLine = 0;
    list = EvenAIDataMethod.measureStringList(text);

    if (list.isEmpty) return;

    String firstScreen =
        list.sublist(0, min(5, list.length)).map((s) => '$s\n').join();
    await sendEvenAIReply(firstScreen, 0x01, 0x30, 0);
  }

  Future<bool> sendEvenAIReply(String text, int type, int status, int pos) async {
    return await Proto.sendEvenAIData(
      text,
      newScreen: EvenAIDataMethod.transferToNewScreen(type, status),
      pos: pos,
      current_page_num: getCurrentPage(),
      max_page_num: getTotalPages(),
    );
  }

  int getTotalPages() {
    if (list.isEmpty) return 0;
    return (list.length / 5).ceil();
  }

  int getCurrentPage() {
    if (_currentLine == 0) return 1;
    return (_currentLine / 5).ceil() + 1;
  }

  void nextPageByTouchpad() {
    if (!isRunning.value) return;
    _isManual = true;
    if (_currentLine + 5 < list.length) {
      _currentLine += 5;
      updateReplyToOSByManual();
    }
  }

  void lastPageByTouchpad() {
    if (!isRunning.value) return;
    _isManual = true;
    if (_currentLine - 5 >= 0) {
      _currentLine -= 5;
      updateReplyToOSByManual();
    }
  }

  Future updateReplyToOSByManual() async {
    final merged = list
        .sublist(_currentLine, min(_currentLine + 5, list.length))
        .join("\n");
    await sendEvenAIReply(merged, 0x01, 0x50, 0);
  }
}

extension EvenAIDataMethod on EvenAI {
  static int transferToNewScreen(int type, int status) {
    return status | type;
  }

  static List<String> measureStringList(String text, [double? maxW]) {
    final double maxWidth = maxW ?? 488;
    const double fontSize = 21;
    List<String> lines = text.split("\n").where((l) => l.isNotEmpty).toList();

    List<String> ret = [];
    TextStyle ts = const TextStyle(fontSize: fontSize);

    for (String line in lines) {
      final tp = TextPainter(
        text: TextSpan(text: line, style: ts),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      ret.add(line);
    }
    return ret;
  }
}
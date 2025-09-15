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
    bool isSuccess = await sendEvenAIReply(firstScreen,
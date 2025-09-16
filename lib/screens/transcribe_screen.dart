// lib/screens/transcribe_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/evenai.dart';
import '../services/gesture_handler.dart';
import '../ble_manager.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> {
  final EvenAI _evenAI = Get.put(EvenAI());
  String _transcript = "";
  bool _isProcessing = false;
  bool _isRecording = false;

  Future<void> _startRecording() async {
    setState(() {
      _isProcessing = true;
      _isRecording = true;
      _transcript = "";
    });

    try {
      // ✅ Start mic capture from BLE
      await BleManager.invokeMethod("startEvenAI");

      GestureHandler.showHUD("🎙 Listening...");

      // EvenAI will automatically handle audio chunks
      // and populate transcript when finished.
    } catch (e) {
      GestureHandler.showHUD("⚠️ Mic error: $e");
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
    });

    try {
      // ✅ Stop BLE mic
      await BleManager.invokeMethod("stopEvenAI");

      // Grab transcript from EvenAI
      final transcript = _evenAI.lastTranscript.value;

      setState(() {
        _isProcessing = false;
        _transcript = transcript.isNotEmpty
            ? transcript
            : "⚠️ No speech detected";
      });

      GestureHandler.showHUD("🗣 $_transcript");
    } catch (e) {
      GestureHandler.showHUD("⚠️ Stop mic error: $e");
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎙 Transcription")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(
                _isRecording
                    ? "⏹ Stop Recording"
                    : (_isProcessing ? "⏳ Processing…" : "🎤 Start Recording"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _transcript,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
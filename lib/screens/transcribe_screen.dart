// lib/screens/transcribe_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/evenai.dart';
import '../services/gesture_handler.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> {
  final EvenAI _evenAI = Get.put(EvenAI());
  String _transcript = "";
  bool _isProcessing = false;

  Future<void> _handleTranscription(Uint8List audioBytes) async {
    setState(() {
      _isProcessing = true;
      _transcript = "";
    });

    await _evenAI.startListening(audioBytes);

    setState(() {
      _isProcessing = false;
      _transcript = _evenAI.lastTranscript.value.isNotEmpty
          ? _evenAI.lastTranscript.value
          : "⚠️ No speech detected";
    });

    // ✅ Show result on HUD too
    GestureHandler.showHUD("🗣 $_transcript");
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
              onPressed: () async {
                // For now, simulate with empty audio
                // Replace with actual recorded Uint8List from BLE mic
                await _handleTranscription(Uint8List(0));
              },
              child: _isProcessing
                  ? const Text("⏳ Processing…")
                  : const Text("Start Transcription"),
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
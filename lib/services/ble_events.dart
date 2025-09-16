// lib/services/ble_events.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'evenai.dart';

class BLEEvents {
  static const EventChannel _eventChannel =
      EventChannel("eventBleReceive"); // ✅ must match Kotlin event channel

  static StreamSubscription? _subscription;

  static void startListening() {
    if (_subscription != null) return;

    final evenAI = Get.put(EvenAI()); // ✅ ensure EvenAI is available

    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event["event"];
        final transcript = event["transcript"] ?? "";

        switch (type) {
          case "mic_start":
            print("🎤 Mic START (from Kotlin)");
            // ✅ Just mark as started — no actual bytes yet
            evenAI.startListening(Uint8List(0));
            break;

          case "mic_stop":
            print("🛑 Mic STOP (from Kotlin)");
            if (transcript is String && transcript.isNotEmpty) {
              // ✅ Treat transcript as final recognized speech
              evenAI.lastTranscript.value = transcript;
              evenAI.combinedText = transcript;
              evenAI.isReceivingAudio.value = false;
              evenAI.isRunning.value = true;

              // Push transcript into ChatGPT pipeline
              evenAI
                  ._processAudio(Uint8List(0))
                  .catchError((e) => print("⚠️ Failed to process transcript: $e"));
            } else {
              print("⚠️ Empty transcript received on mic_stop");
            }
            break;

          default:
            print("⚠️ Unknown BLE event: $event");
        }
      }
    }, onError: (err) {
      print("⚠️ BLE EventChannel error: $err");
    });
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
// lib/services/ble_events.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'evenai.dart';

class BLEEvents {
  static const EventChannel _eventChannel =
      EventChannel("eventBleReceive"); // ✅ must match Kotlin event channel

  static StreamSubscription? _subscription;

  static void startListening() {
    if (_subscription != null) return;

    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event["event"];
        final transcript = event["transcript"] ?? "";

        switch (type) {
          case "mic_start":
            print("🎤 Mic START (from Kotlin)");
            EvenAI.get.startListening(Uint8List(0)); // just signal start
            break;
          case "mic_stop":
            print("🛑 Mic STOP (from Kotlin)");
            EvenAI.get.processTranscript(transcript);
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
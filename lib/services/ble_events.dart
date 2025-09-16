// lib/services/ble_events.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'evenai.dart';

class BLEEvents {
  static const EventChannel _eventChannel =
      EventChannel("eventBleReceive"); // must match Kotlin

  static StreamSubscription? _subscription;

  static void startListening() {
    if (_subscription != null) return;

    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event["event"];
        final transcript = event["transcript"] ?? "";

        final evenAI = EvenAI.to;

        switch (type) {
          case "mic_start":
            print("🎤 Mic START (from Kotlin)");
            evenAI.startListening(Uint8List(0));
            break;
          case "mic_stop":
            print("🛑 Mic STOP (from Kotlin)");
            evenAI.processTranscript(transcript);
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
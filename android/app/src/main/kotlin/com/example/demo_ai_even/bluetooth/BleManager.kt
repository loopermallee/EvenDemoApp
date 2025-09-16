// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:demo_ai_even/app.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:flutter/services.dart';

class BleManager {
  Function()? onStatusChanged;
  BleManager._();

  static BleManager? _instance;
  static BleManager get() {
    _instance ??= BleManager._();
    _instance!._init();
    return _instance!;
  }

  static const methodSend = "send";
  static const _eventBleReceive = "eventBleReceive";
  static const _channel = MethodChannel('method.bluetooth');

  final eventBleReceive = const EventChannel(_eventBleReceive)
      .receiveBroadcastStream(_eventBleReceive);

  Timer? beatHeartTimer;

  final List<Map<String, String>> pairedGlasses = [];
  bool isConnected = false;
  String connectionStatus = 'Not connected';

  void _init() {
    startListening();
  }

  void startListening() {
    eventBleReceive.listen((res) {
      if (res is Map) {
        _handleSimpleEvent(res); // ✅ new
      } else {
        print("⚠️ Unknown BLE event format: $res");
      }
    });
  }

  // ✅ NEW: Handle Kotlin simple events
  void _handleSimpleEvent(Map event) {
    final type = event["event"];
    switch (type) {
      case "mic_start":
        print("🎤 Mic START event from glasses");
        EvenAI.to.startListening(Uint8List(0)); // dummy buffer
        break;
      case "mic_stop":
        print("🛑 Mic STOP event from glasses");
        final transcript = event["transcript"] ?? "";
        EvenAI.to.processTranscript(transcript);
        break;
      default:
        print("⚠️ Unknown event: $event");
    }
  }

  Future<void> startScan() async {
    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      await _channel.invokeMethod('stopScan');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<void> connectToGlasses(String deviceName) async {
    try {
      await _channel.invokeMethod('connectToGlasses', {'deviceName': deviceName});
      connectionStatus = 'Connecting...';
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  String getConnectionStatus() {
    return connectionStatus;
  }

  List<Map<String, String>> getPairedGlasses() {
    return pairedGlasses;
  }

  static Future<T?> invokeMethod<T>(String method, [dynamic params]) {
    return _channel.invokeMethod(method, params);
  }
}
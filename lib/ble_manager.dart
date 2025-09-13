// lib/ble_manager.dart
import 'dart:async';
import 'package:flutter/services.dart';

class BleManager {
  // ===== Singleton =====
  static final BleManager _instance = BleManager._internal();
  BleManager._internal();
  static BleManager get() => _instance;

  // ===== Channels (match Kotlin) =====
  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel = EventChannel("eventBleReceive");

  // ===== State =====
  bool isConnected = false;
  String _status = "Not connected";

  final List<Map<String, String>> _pairedGlasses = [];

  // Callbacks
  Function()? onStatusChanged;
  Function(Map<String, dynamic>)? onDataReceived;

  StreamSubscription? _eventSub;

  // ===== Public API =====

  void startListening() {
    _eventSub ??= _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final map = Map<String, dynamic>.from(event);
        if (onDataReceived != null) {
          onDataReceived!(map);
        }
      }
    }, onError: (error) {
      print("BLE event error: $error");
    });
  }

  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "flutterFoundPairedGlasses":
          final args = Map<String, dynamic>.from(call.arguments);
          _pairedGlasses.add({
            "channelNumber": args["channelNumber"].toString(),
            "leftDeviceName": args["leftDeviceName"] ?? "",
            "rightDeviceName": args["rightDeviceName"] ?? "",
          });
          _status = "Paired found";
          _notifyStatusChanged();
          break;

        case "flutterGlassesConnected":
          final args = Map<String, dynamic>.from(call.arguments);
          _status = "Connected to G1_${args["channelNumber"]}";
          isConnected = true;
          _notifyStatusChanged();
          break;

        default:
          print("Unhandled method from native: ${call.method}");
      }
    });
  }

  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod("startScan");
      _status = "Scanning...";
      _notifyStatusChanged();
    } catch (e) {
      print("startScan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod("stopScan");
      _status = "Not connected";
      _notifyStatusChanged();
    } catch (e) {
      print("stopScan error: $e");
    }
  }

  Future<void> connectToGlasses(String pairId) async {
    try {
      await _methodChannel.invokeMethod("connectToGlasses", {"id": pairId});
      _status = "Connecting...";
      _notifyStatusChanged();
    } catch (e) {
      print("connectToGlasses error: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod("disconnectFromGlasses");
      _status = "Not connected";
      isConnected = false;
      _notifyStatusChanged();
    } catch (e) {
      print("disconnect error: $e");
    }
  }

  // ===== Getters =====
  String getConnectionStatus() => _status;
  List<Map<String, String>> getPairedGlasses() => List.unmodifiable(_pairedGlasses);

  // ===== Internals =====
  void _notifyStatusChanged() {
    if (onStatusChanged != null) onStatusChanged!();
  }
}
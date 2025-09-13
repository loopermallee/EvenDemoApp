// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

typedef StatusChangedCallback = void Function();

class BleManager {
  static final BleManager _instance = BleManager._internal();
  static BleManager get instance => _instance;
  static BleManager get() => _instance;

  BleManager._internal();

  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel = EventChannel("eventBleReceive");

  StreamSubscription? _eventSubscription;
  StatusChangedCallback? onStatusChanged;

  bool isConnected = false;
  String _connectionStatus = "Not connected";
  final List<Map<String, String>> _pairedGlasses = [];

  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "flutterFoundPairedGlasses":
          final args = Map<String, dynamic>.from(call.arguments);
          _pairedGlasses.add({
            "channelNumber": args["channelNumber"].toString(),
            "leftDeviceName": args["leftDeviceName"] ?? "Unknown",
            "rightDeviceName": args["rightDeviceName"] ?? "Unknown",
          });
          break;
        case "flutterGlassesConnected":
          isConnected = true;
          _connectionStatus = "Connected to ${call.arguments}";
          break;
        default:
          break;
      }
      onStatusChanged?.call();
    });
  }

  void startListening() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      // BLE events: { "lr": "L" / "R", "data": [...], "type": "VoiceChunk"/"Receive" }
      print("BLE Event received: $event");
    });
  }

  void stopListening() {
    _eventSubscription?.cancel();
  }

  // 🔍 Scan
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod("startScan");
    } catch (e) {
      print("startScan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod("stopScan");
    } catch (e) {
      print("stopScan error: $e");
    }
  }

  // 🔗 Connect / Disconnect
  Future<void> connectToGlasses(String channel) async {
    try {
      await _methodChannel.invokeMethod("connectToGlass", {"deviceChannel": channel});
    } catch (e) {
      print("connectToGlasses error: $e");
    }
  }

  Future<void> disconnectFromGlasses() async {
    try {
      await _methodChannel.invokeMethod("disconnectFromGlasses");
      isConnected = false;
      _connectionStatus = "Not connected";
      onStatusChanged?.call();
    } catch (e) {
      print("disconnectFromGlasses error: $e");
    }
  }

  // 🆕 NEW: Send data back to glasses
  Future<void> sendData(Uint8List data, {String? lr}) async {
    try {
      await _methodChannel.invokeMethod("senData", {
        "data": data,
        "lr": lr, // can be "L", "R", or null (both)
      });
      print("sendData success: $data (lr=$lr)");
    } catch (e) {
      print("sendData error: $e");
    }
  }

  // Helpers
  String getConnectionStatus() => _connectionStatus;
  List<Map<String, String>> getPairedGlasses() => _pairedGlasses;
}
// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

typedef StatusChangedCallback = void Function();

class BleManager {
  // Singleton
  static final BleManager _instance = BleManager._internal();
  static BleManager get instance => _instance;
  static BleManager get() => _instance;

  BleManager._internal();

  // Native ↔ Flutter channels
  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel = EventChannel("eventBleReceive");

  StreamSubscription? _eventSubscription;
  StatusChangedCallback? onStatusChanged;

  // State
  bool isConnected = false;
  String _connectionStatus = "Not connected";
  final List<Map<String, String>> _pairedGlasses = [];

  /// Must be called at startup (in main.dart)
  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      print("[BleManager] MethodCall from Android → ${call.method}, args=${call.arguments}");

      switch (call.method) {
        case "flutterFoundPairedGlasses":
          final args = Map<String, dynamic>.from(call.arguments ?? {});
          _pairedGlasses.add({
            "channelNumber": args["channelNumber"]?.toString() ?? "0",
            "leftDeviceName": args["leftDeviceName"] ?? "Unknown",
            "rightDeviceName": args["rightDeviceName"] ?? "Unknown",
          });
          break;

        case "flutterGlassesConnected":
          isConnected = true;
          _connectionStatus = "Connected to ${call.arguments}";
          break;

        case "flutterGlassesDisconnected":
          isConnected = false;
          _connectionStatus = "Not connected";
          break;

        default:
          print("[BleManager] ⚠️ Unhandled method: ${call.method}");
          break;
      }

      onStatusChanged?.call();
    });
  }

  /// Start listening to BLE events
  void startListening() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      print("[BleManager] EventChannel BLE → $event");
    }, onError: (err) {
      print("[BleManager] EventChannel error → $err");
    });
  }

  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  // 🔍 Scan
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod("startScan");
      print("[BleManager] startScan invoked");
    } catch (e) {
      print("[BleManager] startScan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod("stopScan");
      print("[BleManager] stopScan invoked");
    } catch (e) {
      print("[BleManager] stopScan error: $e");
    }
  }

  // 🔗 Connect / Disconnect
  Future<void> connectToGlasses(String channel) async {
    try {
      await _methodChannel.invokeMethod("connectToGlass", {
        "deviceChannel": channel,
      });
      print("[BleManager] connectToGlasses($channel) invoked");
    } catch (e) {
      print("[BleManager] connectToGlasses error: $e");
    }
  }

  Future<void> disconnectFromGlasses() async {
    try {
      await _methodChannel.invokeMethod("disconnectFromGlasses");
      isConnected = false;
      _connectionStatus = "Not connected";
      onStatusChanged?.call();
      print("[BleManager] disconnectFromGlasses invoked");
    } catch (e) {
      print("[BleManager] disconnectFromGlasses error: $e");
    }
  }

  // 🆕 Send data back to glasses
  Future<void> sendData(Uint8List data, {String? lr}) async {
    try {
      await _methodChannel.invokeMethod("senData", {
        "data": data,
        "lr": lr, // "L", "R", or null (both)
      });
      print("[BleManager] sendData success: len=${data.length}, lr=$lr");
    } catch (e) {
      print("[BleManager] sendData error: $e");
    }
  }

  // Helpers
  String getConnectionStatus() => _connectionStatus;
  List<Map<String, String>> getPairedGlasses() => List.unmodifiable(_pairedGlasses);
}
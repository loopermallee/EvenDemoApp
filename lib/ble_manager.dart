// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

typedef StatusChangedCallback = void Function();

class BleManager {
  // ===== Singleton =====
  static final BleManager _instance = BleManager._internal();
  static BleManager get() => _instance;
  BleManager._internal();

  // ===== Channels (must match Kotlin) =====
  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel  = EventChannel("eventBleReceive");

  // ===== State =====
  StreamSubscription? _eventSubscription;
  StatusChangedCallback? onStatusChanged;

  bool isConnected = false;
  String _connectionStatus = "Not connected";
  final List<Map<String, String>> _pairedGlasses = [];

  // ===== Native → Flutter (Method callbacks) =====
  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "flutterFoundPairedGlasses":
          final args = Map<String, dynamic>.from(call.arguments);
          _pairedGlasses.add({
            "channelNumber"   : args["channelNumber"].toString(),
            "leftDeviceName"  : (args["leftDeviceName"]  ?? "Unknown").toString(),
            "rightDeviceName" : (args["rightDeviceName"] ?? "Unknown").toString(),
          });
          _connectionStatus = "Paired found";
          break;

        case "flutterGlassesConnected":
          isConnected = true;
          // call.arguments is a map from toConnectedJson(); show channel if present
          final m = (call.arguments is Map) ? Map<String, dynamic>.from(call.arguments) : const {};
          final ch = (m["channelNumber"] ?? "").toString();
          _connectionStatus = ch.isNotEmpty ? "Connected to G1_$ch" : "Connected";
          break;

        default:
          // ignore
          break;
      }
      onStatusChanged?.call();
    });
  }

  // ===== Events stream from Android (BLE data) =====
  void startListening() {
    _eventSubscription ??=
        _eventChannel.receiveBroadcastStream().listen((event) {
      // Shape: { "lr": "L"/"R", "data": <Uint8List>, "type": "VoiceChunk"/"Receive" }
      // Hook here if you need to forward to STT/AI.
      // print("BLE Event: $event");
    }, onError: (e) {
      // print("BLE Event error: $e");
    });
  }

  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  // ===== Flutter → Android calls =====
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod("startScan");
      _connectionStatus = "Scanning...";
      onStatusChanged?.call();
    } catch (e) {
      // print("startScan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod("stopScan");
      _connectionStatus = "Not connected";
      onStatusChanged?.call();
    } catch (e) {
      // print("stopScan error: $e");
    }
  }

  /// Your HomePage currently passes strings like "Pair_45".
  /// We accept both "45" and "Pair_45" and always send only "45" to Android.
  Future<void> connectToGlasses(String channelOrPair) async {
    try {
      final channel = _extractChannel(channelOrPair);
      await _methodChannel.invokeMethod("connectToGlass", {"deviceChannel": channel});
      _connectionStatus = "Connecting…";
      onStatusChanged?.call();
    } catch (e) {
      // print("connectToGlasses error: $e");
    }
  }

  Future<void> disconnectFromGlasses() async {
    try {
      await _methodChannel.invokeMethod("disconnectFromGlasses");
      isConnected = false;
      _connectionStatus = "Not connected";
      onStatusChanged?.call();
    } catch (e) {
      // print("disconnectFromGlasses error: $e");
    }
  }

  /// Send raw bytes to the glasses.
  /// [lr] can be "L", "R", or null (both).
  Future<void> sendData(Uint8List data, {String? lr}) async {
    try {
      await _methodChannel.invokeMethod("senData", {
        "data": data,
        "lr": lr,
      });
    } catch (e) {
      // print("sendData error: $e");
    }
  }

  // ===== Public getters =====
  String getConnectionStatus() => _connectionStatus;
  List<Map<String, String>> getPairedGlasses() => List.unmodifiable(_pairedGlasses);

  // ===== Helpers =====
  String _extractChannel(String s) {
    // Accept "45" or "Pair_45"
    if (s.startsWith("Pair_")) {
      return s.substring(5);
    }
    return s;
  }
}
// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef StatusChangedCallback = void Function();

class BleManager {
  // Singleton
  static final BleManager _instance = BleManager._internal();
  static BleManager get instance => _instance;
  static BleManager get() => _instance;
  BleManager._internal();

  // Native channels
  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel  = EventChannel("eventBleReceive");

  // State
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  String _connectionStatus = "Not connected";
  final List<Map<String, String>> _pairedGlasses = [];

  // Listeners
  StreamSubscription? _eventSubscription;
  StatusChangedCallback? onStatusChanged;

  /// Call once at startup (before runApp)
  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      // Debug log so CI shows what arrived
      // ignore: avoid_print
      print("[BleManager] Method: ${call.method}, args=${call.arguments}");

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
          isConnected.value = true;
          _connectionStatus = "Connected to ${call.arguments}";
          break;

        case "flutterGlassesDisconnected":
          isConnected.value = false;
          _connectionStatus = "Not connected";
          break;

        default:
          // ignore: avoid_print
          print("[BleManager] ⚠️ Unhandled method: ${call.method}");
      }

      onStatusChanged?.call();
    });
  }

  /// Begin listening to BLE events streamed from Android
  void startListening() {
    _eventSubscription ??=
        _eventChannel.receiveBroadcastStream().listen((event) {
      // event example: {"lr":"L","data":[...],"type":"VoiceChunk"}
      // ignore: avoid_print
      print("[BleManager] Event: $event");
    }, onError: (err) {
      // ignore: avoid_print
      print("[BleManager] EventChannel error: $err");
    });
  }

  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  // ===== Commands to Android =====

  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod("startScan");
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] startScan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod("stopScan");
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] stopScan error: $e");
    }
  }

  Future<void> connectToGlasses(String channel) async {
    try {
      await _methodChannel.invokeMethod("connectToGlass", {
        "deviceChannel": channel,
      });
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] connectToGlasses error: $e");
    }
  }

  Future<void> disconnectFromGlasses() async {
    try {
      await _methodChannel.invokeMethod("disconnectFromGlasses");
      isConnected.value = false;
      _connectionStatus = "Not connected";
      onStatusChanged?.call();
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] disconnectFromGlasses error: $e");
    }
  }

  /// Send bytes to glasses (lr: "L", "R", or null for both)
  Future<void> sendData(Uint8List data, {String? lr}) async {
    try {
      await _methodChannel.invokeMethod("senData", {
        "data": data,
        "lr": lr,
      });
      // ignore: avoid_print
      print("[BleManager] sendData ok: len=${data.length}, lr=$lr");
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] sendData error: $e");
    }
  }

  // ===== Helpers used by UI =====
  String getConnectionStatus() => _connectionStatus;
  List<Map<String, String>> getPairedGlasses() => List.unmodifiable(_pairedGlasses);
}
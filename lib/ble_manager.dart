// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BleManager {
  // ---------------- Singleton ----------------
  static final BleManager _instance = BleManager._internal();
  static BleManager get instance => _instance;
  static BleManager get() => _instance;
  BleManager._internal();

  // ---------------- Channels -----------------
  static const _methodChannel = MethodChannel("method.bluetooth");
  static const _eventChannel  = EventChannel("eventBleReceive");

  // ---------------- State --------------------
  /// Native signals this when glasses connect.
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  String _connectionStatus = "Not connected";
  final List<Map<String, String>> _pairedGlasses = [];

  StreamSubscription? _eventSubscription;

  // Lightweight heartbeat timer (compat for old code)
  Timer? _hbTimer;

  // --------------- Call this once ------------
  void setMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
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
          if (call.arguments is Map) {
            final args = Map<String, dynamic>.from(call.arguments);
            _connectionStatus = "Connected to ${args["deviceName"] ?? "Glasses"}";
          } else {
            _connectionStatus = "Connected";
          }
          break;

        case "flutterGlassesDisconnected":
          isConnected.value = false;
          _connectionStatus = "Not connected";
          break;

        default:
          // ignore: avoid_print
          print("[BleManager] ⚠️ Unhandled method: ${call.method}");
      }
    });
  }

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

  // --------------- Android commands ----------
  Future<void> startScan() async {
    try {
      _pairedGlasses.clear(); // reset each scan
      await _methodChannel.invokeMethod("startScan");
      // ignore: avoid_print
      print("[BleManager] startScan invoked");
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
      // ignore: avoid_print
      print("[BleManager] connectToGlasses($channel) invoked");
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
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] disconnectFromGlasses error: $e");
    }
  }

  /// Instance sender (preferred in new code)
  Future<void> sendData(Uint8List data, {String? lr}) async {
    try {
      await _methodChannel.invokeMethod("senData", {
        "data": data,
        "lr": lr, // "L","R", or null (both)
      });
      // ignore: avoid_print
      print("[BleManager] sendData ok: len=${data.length}, lr=$lr");
    } catch (e) {
      // ignore: avoid_print
      print("[BleManager] sendData error: $e");
    }
  }

  // --------------- COMPAT SHIMS --------------
  // Old code calls static BleManager.sendData(...) and BleManager.request(...).
  // These keep that code compiling by delegating to the singleton.

  static Future<void> sendDataStatic(Uint8List data, {String? lr}) =>
      BleManager.get().sendData(data, lr: lr);

  /// Compatible with old `BleManager.sendData(...)` static calls.
  static Future<void> sendDataCompat(Uint8List data, {String? lr}) =>
      BleManager.get().sendData(data, lr: lr);

  /// Some old code used `BleManager.sendData(...)` (static). Provide alias.
  static Future<void> sendDataLegacy(Uint8List data, {String? lr}) =>
      BleManager.get().sendData(data, lr: lr);

  /// Old calls: `BleManager.request([0x.., ...])`
  static Future<void> request(List<int> bytes, {String? lr}) =>
      BleManager.get().sendData(Uint8List.fromList(bytes), lr: lr);

  /// Old code may call: `BleManager.startSendBeatHeart()`
  static Future<void> startSendBeatHeart({Duration interval = const Duration(seconds: 5)}) async {
    final mgr = BleManager.get();
    mgr._hbTimer?.cancel();
    mgr._hbTimer = Timer.periodic(interval, (_) async {
      try {
        // Simple heartbeat frame (adjust to your protocol later)
        await mgr.sendData(Uint8List.fromList([0xF4, 0x02]));
      } catch (_) {}
    });
  }

  static void stopSendBeatHeart() {
    final mgr = BleManager.get();
    mgr._hbTimer?.cancel();
    mgr._hbTimer = null;
  }

  // --------------- UI Helpers ----------------
  String getConnectionStatus() => _connectionStatus;
  List<Map<String, String>> getPairedGlasses() =>
      List.unmodifiable(_pairedGlasses);
}
// lib/services/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'evenai.dart';
import 'gesture_handler.dart';

class BleManager extends GetxController {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _micCharacteristic;
  BluetoothCharacteristic? _gestureCharacteristic;

  final List<int> _micBuffer = [];
  Timer? _heartbeatTimer;

  var isConnected = false.obs;
  var connectionStatus = "Not connected".obs;

  /// 🔍 Scan for devices
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 5)}) async {
    final results = <BluetoothDevice>[];
    await _flutterBlue.startScan(timeout: timeout);

    await for (final scan in _flutterBlue.scanResults) {
      for (final r in scan) {
        if (!results.contains(r.device)) {
          results.add(r.device);
        }
      }
    }

    await _flutterBlue.stopScan();
    return results;
  }

  /// 🔗 Connect to a device and subscribe to services
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      connectionStatus.value = "Connecting…";

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          // 🎤 Mic characteristic (replace with actual UUID if needed)
          if (char.properties.notify && uuid.contains("abcd")) {
            _micCharacteristic = char;
            await char.setNotifyValue(true);
            char.value.listen((data) {
              _micBuffer.addAll(data);
            });
            print("🎤 Subscribed to mic");
          }

          // 🕹️ Gesture characteristic (replace with actual UUID if needed)
          if (char.properties.notify && uuid.contains("gest")) {
            _gestureCharacteristic = char;
            await char.setNotifyValue(true);
            char.value.listen((data) {
              final gesture = _decodeGesture(Uint8List.fromList(data));
              GestureHandler.handleGesture(gesture);
              print("🕹️ Gesture detected: $gesture");
            });
          }
        }
      }

      connectionStatus.value = "Connected";
      isConnected.value = true;
      _startHeartbeat();
    } catch (e) {
      print("⚠️ Failed to connect: $e");
      connectionStatus.value = "Error: $e";
    }
  }

  /// 🩺 Keep alive (heartbeat every 8s)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (t) {
      print("💓 Sending heartbeat…");
      // If your glasses expect a specific packet, send it here
    });
  }

  /// 🎤 Flush mic buffer → EvenAI pipeline
  Future<void> stopMicRecording() async {
    if (_micBuffer.isEmpty) {
      print("⚠️ No audio recorded");
      return;
    }
    final audioBytes = Uint8List.fromList(_micBuffer);
    _micBuffer.clear();

    try {
      await Get.find<EvenAI>().startListening(audioBytes);
    } catch (e) {
      print("⚠️ Error sending audio to EvenAI: $e");
    }
  }

  /// ❌ Disconnect
  Future<void> disconnect() async {
    try {
      await connectedDevice?.disconnect();
      isConnected.value = false;
      connectionStatus.value = "Not connected";
      _heartbeatTimer?.cancel();
    } catch (e) {
      print("⚠️ Failed to disconnect: $e");
    }
  }

  /// 🕹️ Decode raw gesture bytes
  String _decodeGesture(Uint8List data) {
    if (data.isEmpty) return "unknown";
    switch (data[0]) {
      case 0x01:
        return "singleTapRight";
      case 0x02:
        return "singleTapLeft";
      case 0x03:
        return "doubleTapRight";
      case 0x04:
        return "doubleTapLeft";
      case 0x05:
        return "tripleTap";
      case 0x06:
        return "longHold";
      default:
        return "unknown";
    }
  }
}
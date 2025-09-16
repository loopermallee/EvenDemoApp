// lib/services/ble.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/services/gesture_handler.dart';

class BLEService {
  static const _serviceChannel =
      MethodChannel("com.example.demo_ai_even/ble_service");

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;

  BluetoothCharacteristic? _micCharacteristic;
  BluetoothCharacteristic? _gestureCharacteristic;

  final List<int> _micBuffer = [];

  final EvenAI evenAI = Get.put(EvenAI());

  /// Scan for BLE devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    final results = <BluetoothDevice>[];
    await _flutterBlue.startScan(timeout: const Duration(seconds: 5));

    await for (final result in _flutterBlue.scanResults) {
      results.add(result.device);
    }

    await _flutterBlue.stopScan();
    return results;
  }

  /// Connect + discover UUIDs
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    // ✅ Try foreground service
    try {
      await _serviceChannel.invokeMethod("startForegroundService");
    } catch (e) {
      print("⚠️ Foreground service failed: $e");
    }

    // Discover services & dump UUIDs
    List<BluetoothService> services = await device.discoverServices();
    print("🔍 Found ${services.length} services");

    for (var service in services) {
      print("📡 Service UUID: ${service.uuid}");

      for (var char in service.characteristics) {
        print("   ↳ Characteristic UUID: ${char.uuid} "
            "[props: read=${char.properties.read}, "
            "write=${char.properties.write}, "
            "notify=${char.properties.notify}]");

        // 🎤 If looks like mic
        if (char.properties.notify && char.uuid.toString().contains("abcd")) {
          _micCharacteristic = char;
          await _micCharacteristic!.setNotifyValue(true);
          _micCharacteristic!.value.listen((data) {
            _micBuffer.addAll(data);
          });
          print("🎤 Mic characteristic subscribed → ${char.uuid}");
        }

        // 🕹️ If looks like gestures
        if (char.properties.notify && char.uuid.toString().contains("gest")) {
          _gestureCharacteristic = char;
          await _gestureCharacteristic!.setNotifyValue(true);
          _gestureCharacteristic!.value.listen((data) {
            try {
              final gestureCode = _decodeGesture(Uint8List.fromList(data));
              print("🕹️ Gesture detected: $gestureCode");
              GestureHandler.handleGesture(gestureCode);
            } catch (e) {
              print("⚠️ Failed to parse gesture: $e");
            }
          });
          print("🕹️ Gesture characteristic subscribed → ${char.uuid}");
        }
      }
    }
  }

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

  Future<void> stopMicRecording() async {
    if (_micBuffer.isEmpty) {
      print("⚠️ No audio captured");
      return;
    }

    final audioBytes = Uint8List.fromList(_micBuffer);
    try {
      await evenAI.startListening(audioBytes);
    } catch (e) {
      print("⚠️ Failed to process audio: $e");
    }

    _micBuffer.clear();
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      connectedDevice = null;
      await _serviceChannel.invokeMethod("stopForegroundService");
    } catch (e) {
      print("⚠️ Failed to stop service: $e");
      await evenAI.stopEvenAIByOS();
    }
  }

  Future<BluetoothDevice?> reconnectLastDevice() async {
    final connected = await _flutterBlue.connectedDevices;
    if (connected.isNotEmpty) {
      connectedDevice = connected.first;
      return connectedDevice;
    }
    return null;
  }

  Future<void> ensureConnected() async {
    try {
      await _serviceChannel.invokeMethod("ensureConnected");
      print("🔄 Ensuring BLE connection via ForegroundService");
    } catch (e) {
      print("⚠️ Failed to ensure reconnect: $e");
    }
  }
}
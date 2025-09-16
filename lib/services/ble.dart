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

  final List<int> _micBuffer = []; // 🎤 buffer incoming audio packets
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

  /// Connect + discover services + subscribe to mic + gestures
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    try {
      await _serviceChannel.invokeMethod("startForegroundService");
    } catch (e) {
      print("⚠️ Failed to start foreground service: $e");
    }

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var char in service.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();

        // 🎤 Mic notifications (replace with real UUID!)
        if (char.properties.notify && uuid.contains("mic")) {
          _micCharacteristic = char;
          await _micCharacteristic!.setNotifyValue(true);

          _micCharacteristic!.lastValueStream.listen((data) {
            if (data.isNotEmpty) {
              _micBuffer.addAll(data);
            }
          });

          print("🎤 Mic characteristic subscribed");
        }

        // 🕹️ Gesture notifications (replace with real UUID!)
        if (char.properties.notify && uuid.contains("gest")) {
          _gestureCharacteristic = char;
          await _gestureCharacteristic!.setNotifyValue(true);

          _gestureCharacteristic!.lastValueStream.listen((data) {
            if (data.isNotEmpty) {
              final gestureCode = _decodeGesture(Uint8List.fromList(data));
              print("🕹️ Gesture detected: $gestureCode");
              GestureHandler.handleGesture(gestureCode);
            }
          });

          print("🕹️ Gesture characteristic subscribed");
        }
      }
    }
  }

  /// Stop mic recording → flush buffer to EvenAI
  Future<void> stopMicRecording() async {
    if (_micBuffer.isEmpty) {
      print("⚠️ No audio captured");
      return;
    }

    final audioBytes = Uint8List.fromList(_micBuffer);
    _micBuffer.clear(); // ✅ reset buffer immediately

    try {
      await evenAI.startListening(audioBytes);
    } catch (e) {
      print("⚠️ Failed to process audio: $e");
    }
  }

  /// Map raw BLE gesture byte → friendly string
  String _decodeGesture(Uint8List data) {
    switch (data.firstOrNull) {
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

  /// Disconnect + stop Foreground Service
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

  /// Try reconnecting to last device
  Future<BluetoothDevice?> reconnectLastDevice() async {
    final connected = await _flutterBlue.connectedDevices;
    if (connected.isNotEmpty) {
      connectedDevice = connected.first;
      return connectedDevice;
    }
    return null;
  }

  /// Ensure connection (calls Kotlin side BleManager.ensureConnected)
  Future<void> ensureConnected() async {
    try {
      await _serviceChannel.invokeMethod("ensureConnected");
      print("🔄 Ensuring BLE connection via ForegroundService");
    } catch (e) {
      print("⚠️ Failed to ensure reconnect: $e");
    }
  }
}
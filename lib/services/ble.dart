import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:demo_ai_even/services/evenai.dart'; // 🆕 import EvenAI

class BLEService {
  static const _serviceChannel =
      MethodChannel("com.example.demo_ai_even/ble_service");

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;

  BluetoothCharacteristic? _micCharacteristic;
  final List<int> _micBuffer = []; // 🆕 store incoming audio

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

  /// Connect to device + discover services + start mic notifications
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    // ✅ Start foreground service (keeps BLE alive on lockscreen)
    try {
      await _serviceChannel.invokeMethod("startForegroundService");
    } catch (e) {
      print("⚠️ Failed to start foreground service: $e");
    }

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var char in service.characteristics) {
        // 🆕 Assume mic data characteristic UUID (replace with real UUID)
        if (char.properties.notify &&
            char.uuid.toString().toLowerCase().contains("abcd")) {
          _micCharacteristic = char;
          await _micCharacteristic!.setNotifyValue(true);

          _micCharacteristic!.value.listen((data) {
            _micBuffer.addAll(data);
          });

          print("🎤 Mic characteristic subscribed");
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

    // Send to EvenAI pipeline (STT → ChatGPT → HUD)
    await EvenAI.get.recordOverByOS(audioBytes);

    _micBuffer.clear();
  }

  /// Disconnect device + stop Foreground Service
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      connectedDevice = null;

      // ✅ Stop foreground service
      await _serviceChannel.invokeMethod("stopForegroundService");
    } catch (e) {
      print("⚠️ Failed to stop service: $e");
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

  /// ✅ Force ensure connection (calls Kotlin BleManager.ensureConnected)
  Future<void> ensureConnected() async {
    try {
      await _serviceChannel.invokeMethod("ensureConnected");
      print("🔄 Ensuring BLE connection via ForegroundService");
    } catch (e) {
      print("⚠️ Failed to ensure reconnect: $e");
    }
  }
}
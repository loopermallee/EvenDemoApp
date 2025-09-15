import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const _serviceChannel =
      MethodChannel("com.example.demo_ai_even/ble_service");

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;

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

  /// Connect to device + start Foreground Service
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    // ✅ Start foreground service (keeps BLE alive on lockscreen)
    try {
      await _serviceChannel.invokeMethod("startForegroundService");
    } catch (e) {
      print("⚠️ Failed to start foreground service: $e");
    }
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
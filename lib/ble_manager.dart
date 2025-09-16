// lib/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/services/gesture_handler.dart';

class BleManager {
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _micChar;
  BluetoothCharacteristic? _gestureChar;

  final List<BluetoothDevice> discoveredDevices = [];
  bool isConnected = false;

  /// Scan for glasses
  Future<void> startScan() async {
    discoveredDevices.clear();
    await _flutterBlue.startScan(timeout: const Duration(seconds: 5));

    _flutterBlue.scanResults.listen((results) {
      for (var r in results) {
        if (!discoveredDevices.contains(r.device)) {
          discoveredDevices.add(r.device);
        }
      }
    });
  }

  Future<void> stopScan() async {
    await _flutterBlue.stopScan();
  }

  /// Connect to selected device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      isConnected = true;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          // 🎤 Mic notifications
          if (uuid.contains("abcd")) {
            _micChar = char;
            await char.setNotifyValue(true);
            char.value.listen((data) {
              EvenAI().startListening(Uint8List.fromList(data));
            });
          }

          // 🕹️ Gesture notifications
          if (uuid.contains("gest")) {
            _gestureChar = char;
            await char.setNotifyValue(true);
            char.value.listen((data) {
              final gesture = _decodeGesture(Uint8List.fromList(data));
              GestureHandler.handleGesture(gesture);
            });
          }
        }
      }
    } catch (e) {
      print("⚠️ Failed to connect: $e");
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      isConnected = false;
      connectedDevice = null;
    }
  }

  /// Decode gesture from BLE bytes
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
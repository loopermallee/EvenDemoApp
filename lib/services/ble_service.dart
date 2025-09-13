import 'dart:async';
import 'package:flutter/services.dart';

class BleService {
  static const MethodChannel _methodChannel =
      MethodChannel('method.bluetooth');
  static const EventChannel _eventChannel =
      EventChannel('eventBleReceive');

  // Singleton
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Stream for BLE events
  Stream<Map<dynamic, dynamic>>? _bleStream;
  Stream<Map<dynamic, dynamic>> get bleStream {
    _bleStream ??=
        _eventChannel.receiveBroadcastStream().map((event) => event as Map);
    return _bleStream!;
  }

  /// Start scanning for devices
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod('startScan');
    } catch (e) {
      print("BLE startScan error: $e");
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod('stopScan');
    } catch (e) {
      print("BLE stopScan error: $e");
    }
  }

  /// Connect to glasses by channel number
  Future<void> connectToGlass(String channel) async {
    try {
      await _methodChannel.invokeMethod('connectToGlass', channel);
    } catch (e) {
      print("BLE connect error: $e");
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnectFromGlasses');
    } catch (e) {
      print("BLE disconnect error: $e");
    }
  }

  /// Send raw data
  Future<void> sendData(Map<String, dynamic> params) async {
    try {
      await _methodChannel.invokeMethod('sendData', params);
    } catch (e) {
      print("BLE sendData error: $e");
    }
  }
}
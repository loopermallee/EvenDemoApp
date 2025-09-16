// lib/services/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'evenai.dart';

class BleManager {
  static const _channel = MethodChannel('method.bluetooth');

  static Future<T?> invokeMethod<T>(String method, [dynamic params]) {
    return _channel.invokeMethod(method, params);
  }

  /// Example handler for BLE OS-triggered events
  static void handleBleEvent(int code, String lr) {
    final evenAI = EvenAI.to;

    switch (code) {
      case 1: // swipe / page
        if (lr == 'L') {
          evenAI.lastPageByTouchpad();
        } else {
          evenAI.nextPageByTouchpad();
        }
        break;
      case 23: // evenaiStart
        print("📡 EvenAI start requested by OS");
        break;
      case 24: // evenaiRecordOver
        print("📡 EvenAI record over by OS");
        break;
      default:
        print("⚠️ Unknown BLE event: $code");
    }
  }
}
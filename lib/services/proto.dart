// lib/services/proto.dart
//
// Minimal, compile-safe proto helpers that work with the new BleManager.
// We only "send" and do not block waiting for BLE replies.

import 'dart:typed_data';
import 'package:demo_ai_even/ble_manager.dart';

class Proto {
  /// Pick side for glasses: if connected, default to "R" (right), else "L".
  /// You can adjust logic later to match the real dual-rail rules.
  static String pickSide() {
    return BleManager.get().isConnected ? "R" : "L";
  }

  /// Send a *single* packet to the glasses.
  static Future<void> send(Uint8List data, {String? lr}) async {
    await BleManager.get().sendData(data, lr: lr ?? pickSide());
  }

  /// Send a *list* of packets to the glasses (sequentially).
  static Future<bool> sendList(List<Uint8List> packets, {String? lr}) async {
    for (final p in packets) {
      await BleManager.get().sendData(p, lr: lr ?? pickSide());
    }
    return true;
  }

  /// High-level helper used by EvenAI: package plain text for the HUD.
  /// You can replace this with your BMP/text-splitting + CRC framing later.
  static Future<void> sendEvenAIData(
    String text, {
    required int newScreen, // 1 for first page, else 0
    required int pos,
    required int current_page_num,
    required int max_page_num,
  }) async {
    // Very simple wire format for now:
    // [0xF5, newScreen, pos, curPage, maxPage, ...UTF8(text)]
    final header = Uint8List(5);
    header[0] = 0xF5;
    header[1] = newScreen & 0xFF;
    header[2] = pos & 0xFF;
    header[3] = current_page_num & 0xFF;
    header[4] = max_page_num & 0xFF;

    final payload = Uint8List.fromList(
      header + List<int>.from(text.codeUnits),
    );

    await send(payload);
  }
}
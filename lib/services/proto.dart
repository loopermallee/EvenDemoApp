// lib/services/proto.dart
//
// Minimal HUD sender used by EvenAI.
// Uses BleManager.sendData(...) only (no request/response).
// Safe with null-safety and current BleManager.

import 'dart:typed_data';
import 'package:demo_ai_even/ble_manager.dart';

class Proto {
  /// Send a text page to the glasses HUD.
  ///
  /// [text]              The page content
  /// [newScreen]         1 = open new HUD screen, 0 = update current
  /// [pos]               reserved: keep 0
  /// [current_page_num]  1-based page index
  /// [max_page_num]      total page count
  static Future<void> sendEvenAIData(
    String text, {
    required int newScreen,
    required int pos,
    required int current_page_num,
    required int max_page_num,
  }) async {
    // Header (simple/robust framing)
    final header = Uint8List.fromList(<int>[
      0xF5, // start / class
      0x17, // "Even AI activate" family per README
      newScreen & 0xFF,
      pos & 0xFF,
      current_page_num & 0xFF,
      max_page_num & 0xFF,
    ]);

    // Body (UTF-8 bytes)
    final body = Uint8List.fromList(text.codeUnits);

    // End marker (very small delimiter; replace with CRC if needed)
    final end = Uint8List.fromList(<int>[0x00]);

    // Compose [header | body | end]
    final data = Uint8List(header.length + body.length + end.length);
    data.setRange(0, header.length, header);
    data.setRange(header.length, header.length + body.length, body);
    data.setRange(header.length + body.length, data.length, end);

    // Send to BOTH sides (lr = null)
    await BleManager.get().sendData(data);
  }
}
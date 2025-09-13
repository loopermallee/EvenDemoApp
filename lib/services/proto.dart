// lib/services/proto.dart
//
// Minimal HUD sender used by EvenAI.
// Replaces old calls to BleManager.isBothConnected(), request(), requestList()
// with BleManager.get().sendData(...) so it matches your current BleManager.

import 'dart:typed_data';
import 'package:demo_ai_even/ble_manager.dart';

class Proto {
  /// Send a text page to the glasses HUD.
  ///
  /// [text]            The page content
  /// [newScreen]       1 to open a new HUD screen, 0 to update current
  /// [pos]             reserved: keep 0
  /// [current_page_num]1-based index
  /// [max_page_num]    total pages
  static Future<void> sendEvenAIData(
    String text, {
    required int newScreen,
    required int pos,
    required int current_page_num,
    required int max_page_num,
  }) async {
    // Build the payload according to your device text protocol.
    // Simple, robust framing for now. Replace with your CRC/sequence if needed.
    final header = Uint8List.fromList([
      0xF5, // start
      0x17, // "Even AI activate" class (matches your README flow)
      newScreen & 0xFF,
      pos & 0xFF,
      (current_page_num & 0xFF),
      (max_page_num & 0xFF),
    ]);

    // Encode body as UTF-8
    final body = Uint8List.fromList(text.codeUnits);

    // Very small delimiter; in your full protocol you likely
    // split, add CRC, etc. This is a working stub to unblock builds.
    final end = Uint8List.fromList([0x00]);

    // Concatenate: [header | body | end]
    final data = Uint8List(header.length + body.length + end.length);
    data.setRange(0, header.length, header);
    data.setRange(header.length, header.length + body.length, body);
    data.setRange(header.length + body.length, data.length, end);

    // Send to BOTH sides (lr = null) using your method channel
    await BleManager.get().sendData(data, lr: null);
  }
}
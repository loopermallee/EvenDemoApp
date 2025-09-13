// lib/services/proto.dart
//
// Minimal HUD sender used by EvenAI + compatibility stubs for legacy calls
// (sendHeartBeat, exit, sendNotify, sendNewAppWhiteListJson).

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
    final header = Uint8List.fromList([
      0xF5, // start (Even AI channel group)
      0x17, // op: "Even AI activate" family
      newScreen & 0xFF,
      pos & 0xFF,
      (current_page_num & 0xFF),
      (max_page_num & 0xFF),
    ]);

    final body = Uint8List.fromList(text.codeUnits);
    final end  = Uint8List.fromList([0x00]); // simple terminator

    final data = Uint8List(header.length + body.length + end.length)
      ..setRange(0, header.length, header)
      ..setRange(header.length, header.length + body.length, body)
      ..setRange(header.length + body.length, header.length + body.length + end.length, end);

    await BleManager.get().sendData(data, lr: null); // to both lenses
  }

  // ----------------- COMPAT STUBS -----------------

  /// Old code calls this to keep BLE link alive.
  static Future<void> sendHeartBeat() async {
    await BleManager.request([0xF4, 0x02]);
  }

  /// Old code calls this to exit HUD features.
  static Future<void> exit() async {
    await BleManager.request([0xF5, 0x00]); // generic "exit" op
  }

  /// Old code: push a simple notification
  static Future<void> sendNotify(String title, String body) async {
    // Minimal: [F5, 0x20, len(title), bytes(title), len(body), bytes(body)]
    final t = Uint8List.fromList(title.codeUnits);
    final b = Uint8List.fromList(body.codeUnits);
    final frame = Uint8List(2 + 1 + t.length + 1 + b.length);
    frame[0] = 0xF5;
    frame[1] = 0x20; // notify op
    frame[2] = t.length & 0xFF;
    frame.setRange(3, 3 + t.length, t);
    frame[3 + t.length] = b.length & 0xFF;
    frame.setRange(4 + t.length, 4 + t.length + b.length, b);
    await BleManager.sendDataLegacy(frame);
  }

  /// Old code: whitelist json for app(s) allowed to draw
  static Future<void> sendNewAppWhiteListJson(String json) async {
    final j = Uint8List.fromList(json.codeUnits);
    final frame = Uint8List(2 + j.length);
    frame[0] = 0xF5;
    frame[1] = 0x30; // whitelist op
    frame.setRange(2, 2 + j.length, j);
    await BleManager.sendDataCompat(frame);
  }
}
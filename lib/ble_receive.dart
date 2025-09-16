// lib/ble_receive.dart
import 'dart:typed_data';

class BleReceive {
  String lr; // Left or Right channel (e.g. "L" or "R")
  Uint8List data;
  bool isTimeout;

  BleReceive({
    this.lr = "",
    this.data = Uint8List(0),
    this.isTimeout = false,
  });

  /// Factory to build from native event map
  factory BleReceive.fromMap(dynamic map) {
    if (map is Map) {
      return BleReceive(
        lr: map['lr']?.toString() ?? "",
        data: map['data'] is Uint8List
            ? map['data']
            : Uint8List.fromList(List<int>.from(map['data'] ?? [])),
        isTimeout: map['isTimeout'] == true,
      );
    }
    return BleReceive();
  }

  /// Extract command (first byte of data)
  int getCmd() {
    if (data.isEmpty) return 0;
    return data[0];
  }
}
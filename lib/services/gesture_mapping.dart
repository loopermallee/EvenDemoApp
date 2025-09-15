// lib/services/gesture_mapping.dart
import 'package:shared_preferences/shared_preferences.dart';

class GestureMappingService {
  // Default BLE code → action map
  static Map<int, String> _gestureMap = {
    0x01: "singleTapRight",
    0x02: "singleTapLeft",
    0x03: "doubleTapRight",
    0x04: "doubleTapLeft",
    0x05: "tripleTap",
    0x06: "longHold",
  };

  /// Load mapping from SharedPreferences
  static Future<void> loadMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("gesture_mapping");

    if (stored != null) {
      _gestureMap = {};
      for (final entry in stored) {
        final parts = entry.split(":");
        if (parts.length == 2) {
          final code = int.tryParse(parts[0]);
          if (code != null) {
            _gestureMap[code] = parts[1];
          }
        }
      }
    }
  }

  /// Save mapping to SharedPreferences
  static Future<void> saveMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _gestureMap.entries.map((e) => "${e.key}:${e.value}").toList();
    await prefs.setStringList("gesture_mapping", list);
  }

  /// Get current mapping
  static Map<int, String> get mapping => _gestureMap;

  /// Update one mapping
  static Future<void> updateMapping(int code, String action) async {
    _gestureMap[code] = action;
    await saveMapping();
  }

  /// Decode raw BLE packet into action string
  static String decodeGesture(List<int> data) {
    if (data.isEmpty) return "unknown";
    return _gestureMap[data[0]] ?? "unknown";
  }
}
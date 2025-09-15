import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/evenai.dart';  // ✅ hook into EvenAI

/// Handles tap gestures coming from glasses (via BLE or simulated).
/// Now directly controls EvenAI page navigation.
class GestureHandler {
  static final ValueNotifier<String?> hudMessage = ValueNotifier(null);

  /// Triggered when a gesture is detected (from BLE or emulator).
  static Future<void> onGesture(String gesture) async {
    // Load mapping (still useful if we want to remap later)
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString("gesture_$gesture") ?? _defaultMapping[gesture];

    switch (gesture) {
      case "single_right":
        _showHUD("➡️ Next Page");
        EvenAI.get.nextPageByTouchpad();
        break;

      case "single_left":
        _showHUD("⬅️ Previous Page");
        EvenAI.get.lastPageByTouchpad();
        break;

      case "double_right":
        _showHUD("❌ Closing Dialogue");
        await EvenAI.get.stopEvenAIByOS();
        break;

      case "long":
        _showHUD("⏹️ Cancel Listening");
        await EvenAI.get.stopEvenAIByOS();
        break;

      default:
        _showHUD("👉 $gesture → $action");
        break;
    }

    // Auto-clear HUD
    await Future.delayed(const Duration(seconds: 2));
    _clearHUD();
  }

  /// Show retro HUD message
  static void _showHUD(String message) {
    hudMessage.value = message;
  }

  /// Clear HUD
  static void _clearHUD() {
    hudMessage.value = null;
  }

  /// Default mapping (still kept for future use)
  static const Map<String, String> _defaultMapping = {
    "single_right": "Next",
    "single_left": "Previous",
    "double_right": "Close",
    "long": "Cancel",
  };
}
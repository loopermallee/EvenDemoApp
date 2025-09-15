import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles tap gestures coming from glasses (via BLE or simulated for now).
/// Also shows a retro HUD overlay on screen.
class GestureHandler {
  static final ValueNotifier<String?> hudMessage = ValueNotifier(null);

  /// Triggered when a gesture is detected (from BLE or emulator).
  static Future<void> onGesture(String gesture) async {
    // Load mapping from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString("gesture_$gesture") ?? _defaultMapping[gesture];

    // Show gesture first
    _showHUD(_gestureSymbols[gesture] ?? gesture);

    // Then show launching
    await Future.delayed(const Duration(milliseconds: 800));
    _showHUD("Launching $action...");

    // TODO: actually launch tile / screen here
    // e.g. Navigator.pushNamed(context, "/ai") if action == "AI"
    await Future.delayed(const Duration(seconds: 1));
    _clearHUD();
  }

  /// Show retro HUD message
  static void _showHUD(String message) {
    hudMessage.value = message;
  }

  /// Clear HUD after a delay
  static void _clearHUD() {
    hudMessage.value = null;
  }

  /// Default mapping
  static const Map<String, String> _defaultMapping = {
    "single": "AI",
    "double": "Translate",
    "triple": "Commute",
    "long": "Teleprompt",
  };

  /// HUD-friendly gesture symbols
  static const Map<String, String> _gestureSymbols = {
    "single": "• Single Tap",
    "double": "•• Double Tap",
    "triple": "••• Triple Tap",
    "long": "⌛ Hold",
  };
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_ai_even/services/evenai.dart';

/// Handles tap gestures coming from glasses (via BLE or simulated for now).
/// Also shows a retro HUD overlay on screen.
class GestureHandler {
  static final ValueNotifier<String?> hudMessage = ValueNotifier(null);

  static Timer? _countdownTimer;
  static int _secondsRemaining = 0;

  /// Triggered when a gesture is detected (from BLE or emulator).
  static Future<void> onGesture(String gesture) async {
    // Load mapping from SharedPreferences (fallback to default)
    final prefs = await SharedPreferences.getInstance();
    final action =
        prefs.getString("gesture_$gesture") ?? _defaultMapping[gesture];

    // 🎛️ If EvenAI is running, intercept gestures for paging
    if (EvenAI.isRunning) {
      switch (gesture) {
        case "single": // 👉 Next page (right tap)
          EvenAI.get.nextPageByTouchpad();
          _showHUD("➡️ Next Page");
          _stopCountdown();
          return;
        case "long": // 👈 Last page (left hold/tap)
          EvenAI.get.lastPageByTouchpad();
          _showHUD("⬅️ Previous Page");
          _stopCountdown();
          return;
        case "double": // ❌ Close AI
          await EvenAI.get.stopEvenAIByOS();
          _showHUD("❌ Closed AI");
          _stopCountdown();
          return;
      }
    }

    // 🕹️ Otherwise: normal tile launching flow
    _showHUD(_gestureSymbols[gesture] ?? gesture);
    await Future.delayed(const Duration(milliseconds: 800));
    _showHUD("Launching $action...");

    // TODO: actually launch tile/screen here
    await Future.delayed(const Duration(seconds: 1));
    _clearHUD();
  }

  /// HUD auto-scroll countdown (called by EvenAI when new page shows)
  static void startCountdown(int seconds) {
    _stopCountdown();
    _secondsRemaining = seconds;

    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        hudMessage.value = null;
      } else {
        hudMessage.value =
            "⌛ Next page in $_secondsRemaining s\n(Tap to skip/rewind)";
        _secondsRemaining--;
      }
    });
  }

  static void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Show retro HUD message
  static void _showHUD(String message) {
    hudMessage.value = message;
  }

  /// Clear HUD after a delay
  static void _clearHUD() {
    hudMessage.value = null;
    _stopCountdown();
  }

  /// Default mapping when nothing is saved
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
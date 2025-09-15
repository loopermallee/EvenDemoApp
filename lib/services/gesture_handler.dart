import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles tap gestures coming from glasses (via BLE or simulated for now).
/// Also shows a retro HUD overlay on screen.
class GestureHandler {
  static final ValueNotifier<String?> hudMessage = ValueNotifier(null);

  // Paging state
  static List<String> _pages = [];
  static int _currentPage = 0;
  static Timer? _autoTimer;
  static int _countdown = 0;
  static bool _blinkOn = true; // ✅ blinking state

  /// Triggered when a gesture is detected (from BLE or emulator).
  static Future<void> onGesture(String gesture) async {
    // 🔹 If pages are active, gestures control HUD navigation
    if (_pages.isNotEmpty) {
      if (gesture == "right") {
        _showNextPage();
        return;
      } else if (gesture == "left") {
        _showPrevPage();
        return;
      } else if (gesture == "double_right") {
        _clearPagedHUD();
        return;
      }
    }

    // 🔹 Otherwise, fall back to tile launching
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString("gesture_$gesture") ?? _defaultMapping[gesture];

    // Show gesture first
    _showHUD(_gestureSymbols[gesture] ?? gesture);

    // Then show launching
    await Future.delayed(const Duration(milliseconds: 800));
    _showHUD("Launching $action...");

    // TODO: actually launch tile / screen here
    await Future.delayed(const Duration(seconds: 1));
    _clearHUD();
  }

  /// Show retro HUD message
  static void _showHUD(String message) {
    hudMessage.value = message;
  }

  /// Show paginated HUD
  static void showPagedHUD(List<String> pages) {
    _pages = pages;
    _currentPage = 0;
    _startCountdown();
    _showHUD(_formatPage());
  }

  /// Go to next page
  static void _showNextPage() {
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      _startCountdown();
      _showHUD(_formatPage());
    } else {
      _clearPagedHUD();
    }
  }

  /// Go to previous page
  static void _showPrevPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _startCountdown();
      _showHUD(_formatPage());
    }
  }

  /// Format page with counter + countdown
  static String _formatPage() {
    final pageText = _pages[_currentPage];

    // ✅ Blink effect in last 2 seconds
    final countdownDisplay = (_countdown <= 2 && !_blinkOn)
        ? "⏳ " // show only icon when blink-off
        : "⏳$_countdown";

    return "$pageText   [${_currentPage + 1}/${_pages.length}] $countdownDisplay";
  }

  /// Start countdown timer
  static void _startCountdown() {
    _autoTimer?.cancel();

    // Adjust time based on text length (shorter text = faster flip)
    final textLength = _pages[_currentPage].length;
    final seconds = (textLength / 40).clamp(3, 7).toInt(); // 3–7 seconds window

    _countdown = seconds;
    _blinkOn = true;

    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        _showNextPage();
        return;
      }

      // ✅ toggle blink state in last 2 seconds
      if (_countdown <= 2) {
        _blinkOn = !_blinkOn;
      }

      _showHUD(_formatPage());
      _countdown--;
    });
  }

  /// Clear HUD after paging
  static void _clearPagedHUD() {
    _autoTimer?.cancel();
    _pages = [];
    _currentPage = 0;
    hudMessage.value = null;
  }

  /// Clear simple HUD
  static void _clearHUD() {
    hudMessage.value = null;
  }

  /// Default mapping
  static const Map<String, String> _defaultMapping = {
    "single": "AI",
    "double": "Translate",
    "triple": "Commute",
    "long": "Teleprompt",
    "left": "Navigate",
    "right": "AI",
    "double_right": "Close",
  };

  /// HUD-friendly gesture symbols
  static const Map<String, String> _gestureSymbols = {
    "single": "• Single Tap",
    "double": "•• Double Tap",
    "triple": "••• Triple Tap",
    "long": "⌛ Hold",
    "left": "⬅ Left Tap",
    "right": "➡ Right Tap",
    "double_right": "⏹ Double Right",
  };
}
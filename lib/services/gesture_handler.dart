import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles tap gestures coming from glasses (via BLE or simulated).
/// Also manages HUD overlay with paging + auto-advance.
class GestureHandler {
  static final ValueNotifier<String?> hudMessage = ValueNotifier(null);

  // Internal state for paged HUD
  static List<String> _pages = [];
  static int _currentPage = 0;
  static Timer? _pageTimer;

  /// Triggered when a gesture is detected (from BLE or emulator).
  static Future<void> onGesture(String gesture) async {
    // Load mapping from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString("gesture_$gesture") ?? _defaultMapping[gesture];

    // Show gesture first
    showHUD(_gestureSymbols[gesture] ?? gesture);

    // Then show launching
    await Future.delayed(const Duration(milliseconds: 800));
    showHUD("Launching $action...");

    // TODO: actually launch tile / screen here
    await Future.delayed(const Duration(seconds: 1));
    clearHUD();
  }

  /// Show single HUD message
  static void showHUD(String message) {
    _stopPaging();
    hudMessage.value = message;
  }

  /// Show paged HUD messages
  static void showPagedHUD(dynamic messages) {
    _stopPaging();
    _pages = messages is String ? [messages] : List<String>.from(messages);
    _currentPage = 0;
    _showPage();

    // Auto-advance timer
    _pageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      nextPage();
    });
  }

  /// Move to next page (auto or tap)
  static void nextPage() {
    if (_pages.isEmpty) return;
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      _showPage();
    } else {
      clearHUD();
    }
  }

  /// Show current page with countdown indicator
  static void _showPage() {
    if (_pages.isEmpty) return;
    final secondsLeft = 4; // default auto-advance
    hudMessage.value = "${_pages[_currentPage]}\n\n⏳ $secondsLeft sec...";
  }

  /// Clear HUD + stop paging
  static void clearHUD() {
    _stopPaging();
    hudMessage.value = null;
  }

  static void _stopPaging() {
    _pageTimer?.cancel();
    _pageTimer = null;
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
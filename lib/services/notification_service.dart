// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_handler.dart';
import 'evenai.dart';

class NotificationService {
  static const _channel =
      MethodChannel("com.example.demo_ai_even/notifications");

  static Timer? _clearTimer;
  static final List<String> _pendingNotifications = [];

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onNotification") {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool("notifications_enabled") ?? true;

        if (!enabled) {
          print("🔕 Notifications disabled, skipping HUD message");
          return;
        }

        final msg = call.arguments as String;
        if (msg.isEmpty) return;

        // If AI is running, hold notification
        if (EvenAI().isRunning.value) {
          _pendingNotifications.add(msg);
          print("📥 Queued notification (AI active): $msg");
          return;
        }

        // Otherwise show immediately
        _showNotification(msg, 1);
      }
    });
  }

  /// Called when AI finishes → show queued notifications
  static void showPending() {
    if (_pendingNotifications.isEmpty) return;

    final count = _pendingNotifications.length;
    final lastMsg = _pendingNotifications.last;
    final display =
        count > 1 ? "🔔($count) $lastMsg" : "🔔 $lastMsg";

    GestureHandler.showHUD(display);
    print("🔔 Restored notifications → HUD: $display");

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 6), () {
      GestureHandler.hudMessage.value = null;
      _pendingNotifications.clear();
      print("🧹 Pending notifications cleared from HUD");
    });
  }

  /// Helper: show a single notification
  static void _showNotification(String msg, int count) {
    final display = count > 1 ? "🔔($count) $msg" : "🔔 $msg";
    GestureHandler.showHUD(display);

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 6), () {
      GestureHandler.hudMessage.value = null;
      print("🧹 Notification cleared from HUD");
    });
  }
}
// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_handler.dart';

class NotificationService {
  static const _channel =
      MethodChannel("com.example.demo_ai_even/notifications");

  static Timer? _clearTimer;

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
        if (msg.isNotEmpty) {
          // ✅ Show notification on HUD
          GestureHandler.showHUD("🔔 $msg");
          print("🔔 Notification → HUD: $msg");

          // ✅ Auto-clear after 6 seconds
          _clearTimer?.cancel();
          _clearTimer = Timer(const Duration(seconds: 6), () {
            GestureHandler.hudMessage.value = null;
            print("🧹 Notification cleared from HUD");
          });
        }
      }
    });
  }
}
// lib/services/notification_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_handler.dart';

class NotificationService {
  static const _channel =
      MethodChannel("com.example.demo_ai_even/notifications");

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
          // ✅ Show notifications on HUD
          GestureHandler.showHUD("🔔 $msg");
          print("🔔 Notification → HUD: $msg");
        }
      }
    });
  }
}
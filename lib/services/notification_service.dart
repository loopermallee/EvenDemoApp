// lib/services/notification_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_handler.dart';
import 'package:get/get.dart';

class NotificationService {
  static const _channel =
      MethodChannel("com.example.demo_ai_even/notifications");

  // ✅ Persistent notification count
  static final RxInt notificationCount = 0.obs;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onNotification") {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool("notifications_enabled") ?? true;

        if (!enabled) {
          print("🔕 Notifications disabled, skipping HUD counter");
          return;
        }

        final msg = call.arguments as String;
        if (msg.isEmpty) return;

        // ✅ Increment counter
        notificationCount.value++;
        print("🔔 Notification received (count: ${notificationCount.value}) $msg");

        // ✅ Also show latest notification briefly in HUD text
        GestureHandler.showHUD("🔔 $msg");
      }
    });
  }

  /// Manually clear notifications (resets counter + HUD)
  static void clearNotifications() {
    notificationCount.value = 0;
    print("🧹 Notifications cleared");
  }
}
// lib/services/notification_service.dart
import 'package:flutter/services.dart';
import 'gesture_handler.dart';

class NotificationService {
  static const _channel = MethodChannel("com.example.demo_ai_even/notifications");

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onNotification") {
        final msg = call.arguments as String;
        // ✅ Show notifications on HUD
        GestureHandler.showHUD("🔔 $msg");
      }
    });
  }
}
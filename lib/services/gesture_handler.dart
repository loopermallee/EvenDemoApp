// lib/services/gesture_handler.dart
import 'package:get/get.dart';

class GestureHandler {
  // ✅ HUD message state
  static final hudMessage = RxnString();

  // ✅ HUD navigation callbacks (set by HUDOverlay)
  static void Function()? onNextPage;
  static void Function()? onPrevPage;
  static void Function()? onCloseHUD;

  /// Show a new message on HUD
  static void showHUD(String message) {
    hudMessage.value = message;
  }

  /// Wrapper for backward compatibility with old code
  static void showPagedHUD(String message) {
    // Forward to showHUD (pagination handled inside HUDOverlay)
    showHUD(message);
  }

  /// Close HUD overlay
  static void closeHUD() {
    hudMessage.value = null;
  }

  /// Called when BLE detects a gesture event
  static void handleGesture(String gesture) {
    switch (gesture) {
      case "singleTapRight": // ✅ next page
        onNextPage?.call();
        break;
      case "singleTapLeft": // ✅ previous page
        onPrevPage?.call();
        break;
      case "doubleTapRight": // ✅ close HUD
        onCloseHUD?.call();
        break;

      // 🔹 Default gesture bindings
      case "singleTap":
        showHUD("🤖 Launching AI...");
        break;
      case "doubleTap":
        showHUD("🌐 Launching Translate...");
        break;
      case "tripleTap":
        showHUD("🚌 Launching Commute...");
        break;
      case "longHold":
        showHUD("📜 Launching Teleprompt...");
        break;

      default:
        break;
    }
  }
}
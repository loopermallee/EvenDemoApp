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

      // 🔹 You can extend these:
      case "singleTap": // default AI launch
        showHUD("🤖 Launching AI...");
        break;
      case "doubleTap": // default Translate
        showHUD("🌐 Launching Translate...");
        break;
      case "tripleTap": // default Commute
        showHUD("🚌 Launching Commute...");
        break;
      case "longHold": // default Teleprompt
        showHUD("📜 Launching Teleprompt...");
        break;

      default:
        break;
    }
  }
}
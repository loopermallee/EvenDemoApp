class GestureHandler {
  static final hudMessage = "".obs;

  // ✅ HUD navigation callbacks
  static void Function()? onNextPage;
  static void Function()? onPrevPage;
  static void Function()? onCloseHUD;

  static void showHUD(String message) {
    hudMessage.value = message;
  }

  static void closeHUD() {
    hudMessage.value = "";
  }

  // Example gesture mapping
  static void handleGesture(String gesture) {
    switch (gesture) {
      case "singleTap":
        onNextPage?.call();
        break;
      case "doubleTap":
        onCloseHUD?.call();
        break;
      case "tripleTap":
        onPrevPage?.call();
        break;
      default:
        break;
    }
  }
}
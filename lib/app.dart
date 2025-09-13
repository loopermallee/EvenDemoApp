// lib/app.dart
import 'package:get/get.dart';

// Prefer relative import so renaming the package won’t break it.
// If your file is actually at lib/services/evenai.dart keep this:
import 'services/evenai.dart';

class App {
  static App? _instance;
  static App get get => _instance ??= App._();
  App._();

  /// Layman’s terms:
  /// This is a tiny “remote control” for global actions.
  /// Right now it only knows how to cleanly stop Even AI.
  Future<void> exitAll({bool isNeedBackHome = true}) async {
    // If Even AI is active, stop it gracefully so the glasses don’t get stuck.
    if (EvenAI.isEvenAIOpen.value) {
      await EvenAI.stopEvenAIByOS();
    }

    // Optionally navigate back home (you can wire this later if needed)
    if (isNeedBackHome && Get.currentRoute != '/') {
      Get.offAllNamed('/');
    }
  }
}
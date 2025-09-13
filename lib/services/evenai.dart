// lib/services/evenai.dart

import 'package:demo_ai_even/ble_manager.dart';

class EvenAI {
  // ... your existing fields and methods ...

  /// Stops the Even AI process due to an OS-level interrupt or app closure.
  Future<void> stopEvenAIByOS() async {
    try {
      // 1. Tell glasses to stop recording/mic
      // Adjust to your BLE command format; this is a safe placeholder
      await BleManager.get().sendData(
        Uint8List.fromList([0x0E, 0x00]), // stop mic command
        lr: null,
      );

      // 2. Cancel any running AI or audio work
      // If you have controllers, cancel them here.
      // Example placeholders:
      // _audioBuffer.clear();
      // _currentTranscription?.cancel();
      // _currentChatRequest?.cancel();

      // 3. Mark inactive / notify UI
      // If you’re using a ValueNotifier or RxBool, update it here.
      // isActive.value = false;

      // ignore: avoid_print
      print("✅ EvenAI stopped by OS event.");
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ stopEvenAIByOS error: $e");
    }
  }
}
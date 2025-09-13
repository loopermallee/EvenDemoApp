// lib/app.dart
import 'package:flutter/material.dart';

// Keep your Even AI service import (as you had)
import 'package:demo_ai_even/services/evenai.dart';

// Use relative imports for the test scaffolding we added
import 'pages/ble_test_page.dart';
import 'services/ble_service.dart';

/// Root widget for the app.
/// Right now we point home to the BLE Test Page so you can verify BLE end-to-end.
/// Later, you can change `home:` to your real dashboard once tests pass.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure BLE event stream is hooked once at app start
    BleService.instance; // lazy singleton
    return MaterialApp(
      title: 'Even Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const BleTestPage(),
    );
  }
}

/// Small utility singleton you already had.
/// We keep it as-is so any existing calls continue to work.
class App {
  static App? _instance;
  static App get get => _instance ??= App._();

  App._();

  /// exit features by receiving [0xF5, 0]
  Future<void> exitAll({bool isNeedBackHome = true}) async {
    if (EvenAI.isEvenAIOpen.value) {
      await EvenAI.stopEvenAIByOS();
    }
    // If you later want to pop back to a home screen, you can add Navigator logic here.
  }
}
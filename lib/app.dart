// lib/app.dart
import 'package:flutter/material.dart';
import 'services/evenai.dart';
import 'services/ble_service.dart';
import 'pages/ble_test_page.dart';
import 'views/home_page.dart';

/// Toggle this flag to pick which screen to boot into:
const bool kDebugBleTest = true; // 👈 set false to go to HomePage

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure BLE event stream is hooked once
    BleService.instance;

    return MaterialApp(
      title: 'Even Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: kDebugBleTest ? const BleTestPage() : const HomePage(),
    );
  }
}

/// Utility singleton you already had
class App {
  static App? _instance;
  static App get get => _instance ??= App._();

  App._();

  Future<void> exitAll({bool isNeedBackHome = true}) async {
    if (EvenAI.isEvenAIOpen.value) {
      await EvenAI.stopEvenAIByOS();
    }
  }
}
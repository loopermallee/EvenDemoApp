// lib/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Matches your provided evenai.dart (class name is EvenAI and exports isEvenAIOpen + stopEvenAIByOS)
import 'services/evenai.dart';

// If you have the BLE test page and your real home page, keep these.
// Otherwise, temporarily change `home:` below to a page you have.
import 'views/home_page.dart';
// import 'pages/ble_test_page.dart'; // uncomment if you created it

/// Flip this to quickly boot into a test page vs your real app.
/// If you don't have a test page, leave this as false.
const bool kDebugBleTest = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Even AI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // If you don't have BleTestPage, keep only HomePage here.
      // initialRoute: kDebugBleTest ? '/bleTest' : '/',
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        // If you created a BLE test page, add its route:
        // GetPage(name: '/bleTest', page: () => const BleTestPage()),
      ],
    );
  }
}

/// Simple global helper you already had.
/// Now it strictly uses the API exposed by your evenai.dart.
class App {
  static App? _instance;
  static App get get => _instance ??= App._();
  App._();

  /// Called when you want to force-stop Even AI and (optionally) go home.
  Future<void> exitAll({bool isNeedBackHome = true}) async {
    if (EvenAI.isEvenAIOpen.value) {
      await EvenAI.stopEvenAIByOS(); // static method on your EvenAI
    }

    if (isNeedBackHome && Get.currentRoute != '/') {
      // Return to app root if not already there
      Get.offAllNamed('/');
    }
  }
}
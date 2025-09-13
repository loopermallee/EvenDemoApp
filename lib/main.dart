// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your app files
import 'ble_manager.dart';
import 'controllers/evenai_model_controller.dart';
import 'views/home_page.dart';

void main() {
  // Make sure Flutter bindings are ready (safe for channel setup)
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Start listening to Android channels BEFORE UI builds.
  //    This prevents missing early events like "found glasses" or "connected".
  BleManager.get().setMethodCallHandler();
  BleManager.get().startListening();

  // 2) Set up your GetX controller(s)
  Get.put(EvenaiModelController());

  // 3) Robust error logging (so CI logs are clearer)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // Last-resort catcher for async errors
    // (kept simple so logs show up clearly in CI)
    // ignore: avoid_print
    print('Zoned error: $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If you later add themes/localization, keep this simple scaffold as-is.
    return MaterialApp(
      title: 'Even AI Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
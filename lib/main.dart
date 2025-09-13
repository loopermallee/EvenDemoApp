import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your app files
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup BLE channels early
  BleManager.get().setMethodCallHandler();
  BleManager.get().startListening();

  // Setup GetX state
  Get.put(EvenaiModelController());

  // Error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // ignore: avoid_print
    print('Zoned error: $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use GetMaterialApp if you want GetX navigation
    return GetMaterialApp(
      title: 'Even AI Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
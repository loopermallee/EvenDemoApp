// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'controllers/evenai_model_controller.dart';
import 'ble_manager.dart';
import 'views/home_page.dart';

void main() {
  // Initialize BLE channels immediately
  BleManager.get().setMethodCallHandler();
  BleManager.get().startListening();

  // Initialize EvenAI controller
  Get.put(EvenaiModelController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Even AI Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
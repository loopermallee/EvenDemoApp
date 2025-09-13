// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart'; // contains MyApp and App singleton
import 'controllers/evenai_model_controller.dart';

void main() {
  // Ensure Flutter binding is ready (good for async setup later)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global GetX controller for EvenAI model
  Get.put(EvenaiModelController(), permanent: true);

  // Run the app
  runApp(const MyApp());
}
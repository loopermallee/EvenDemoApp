// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart'; // MyApp + App singleton
import 'controllers/evenai_model_controller.dart';

void main() {
  // Make sure Flutter is fully ready before we touch channels/controllers
  WidgetsFlutterBinding.ensureInitialized();

  // Register your EvenAI state controller once, keep it alive for whole app
  Get.put(EvenaiModelController(), permanent: true);

  // Touch the App singleton (handy if you later add global boot logic)
  App.get;

  runApp(const MyApp());
}
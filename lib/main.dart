// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your own imports
import 'app.dart';
import 'controllers/evenai_model_controller.dart';

void main() {
  // Initialize your GetX controller (EvenAI model state)
  Get.put(EvenaiModelController());

  // Run the app
  runApp(const MyApp());
}
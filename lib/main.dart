// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your own files (use relative imports so package name changes don’t break)
// If you don’t have BleTestPage yet, you can comment that import & route.
import 'app.dart';
import 'controllers/evenai_model_controller.dart';
import 'views/home_page.dart';
import 'pages/ble_test_page.dart'; // <-- comment out if you didn’t create it

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register global state (EvenAI model/controller)
  Get.put(EvenaiModelController(), permanent: true);

  // Make App singleton available early (even if it’s just helpers)
  App.get;

  runApp(const MyApp());
}

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
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        // Remove this route if you didn’t add the test screen
        GetPage(name: '/bleTest', page: () => const BleTestPage()),
      ],
    );
  }
}
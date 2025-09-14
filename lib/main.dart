import 'package:flutter/material.dart';
import 'screens/test_screen.dart';

void main() {
  runApp(const EvenDemoApp());
}

class EvenDemoApp extends StatelessWidget {
  const EvenDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Even Demo App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.greenAccent,
        fontFamily: 'PixelFont', // ✅ matches pubspec.yaml
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.greenAccent, fontSize: 14),
          bodyMedium: TextStyle(color: Colors.greenAccent, fontSize: 12),
          bodySmall: TextStyle(color: Colors.greenAccent, fontSize: 10),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.greenAccent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TestScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "LOADING...",
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
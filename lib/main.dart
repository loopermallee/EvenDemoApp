import 'package:flutter/material.dart';
import 'home_page.dart'; // your starting screen

void main() {
  runApp(const EvenDemoApp());
}

class EvenDemoApp extends StatelessWidget {
  const EvenDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Even Demo App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.greenAccent,
        fontFamily: 'PressStart2P',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.greenAccent),
          bodyMedium: TextStyle(color: Colors.greenAccent),
          bodySmall: TextStyle(color: Colors.greenAccent),
          headlineMedium: TextStyle(color: Colors.greenAccent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.greenAccent,
            side: const BorderSide(color: Colors.greenAccent, width: 2),
            textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 12),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PressStart2P',
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
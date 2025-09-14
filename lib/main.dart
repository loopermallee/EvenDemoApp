import 'package:flutter/material.dart';
import 'screens/test_screen.dart'; // Make sure this path exists: lib/screens/test_screen.dart

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
          bodyLarge: TextStyle(
            color: Colors.greenAccent,
            fontSize: 14,
            fontFamily: 'PixelFont',
          ),
          bodyMedium: TextStyle(
            color: Colors.greenAccent,
            fontSize: 12,
            fontFamily: 'PixelFont',
          ),
          bodySmall: TextStyle(
            color: Colors.greenAccent,
            fontSize: 10,
            fontFamily: 'PixelFont',
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.greenAccent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 14,
            color: Colors.greenAccent,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PixelFont',
          ),
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PixelFont',
            fontSize: 14,
          ),
          contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PixelFont',
            fontSize: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.greenAccent,
            textStyle: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 12,
            ),
            side: const BorderSide(color: Colors.greenAccent, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PixelFont',
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.greenAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.greenAccent, width: 2),
          ),
        ),
      ),
      home: const TestScreen(),
    );
  }
}
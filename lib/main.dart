import 'package:flutter/material.dart';
import 'screens/test_screen.dart'; // Make sure this path exists

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
        fontFamily: 'PressStart2P', // Make sure the font is added in pubspec.yaml
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.greenAccent,
            fontSize: 14,
            fontFamily: 'PressStart2P',
          ),
          bodyMedium: TextStyle(
            color: Colors.greenAccent,
            fontSize: 12,
            fontFamily: 'PressStart2P',
          ),
          bodySmall: TextStyle(
            color: Colors.greenAccent,
            fontSize: 10,
            fontFamily: 'PressStart2P',
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.greenAccent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
            color: Colors.greenAccent,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PressStart2P',
          ),
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PressStart2P',
            fontSize: 14,
          ),
          contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'PressStart2P',
            fontSize: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.greenAccent,
            textStyle: const TextStyle(
              fontFamily: 'PressStart2P',
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
            fontFamily: 'PressStart2P',
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
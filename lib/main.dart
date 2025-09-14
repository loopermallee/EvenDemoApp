import 'package:flutter/material.dart';

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
        fontFamily: 'PixelFont',

        // Global text theme
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF00FF00)),
          bodyMedium: TextStyle(color: Color(0xFF00FF00)),
          bodySmall: TextStyle(color: Color(0xFF00FF00)),
        ),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFF00FF00),
          elevation: 0,
        ),

        // Elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFF00FF00),
            textStyle: const TextStyle(fontFamily: 'PixelFont'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),

        // Text buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00FF00),
            textStyle: const TextStyle(fontFamily: 'PixelFont'),
          ),
        ),

        // Input fields (TextFormField, TextField)
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.black,
          hintStyle: TextStyle(color: Color(0xFF00FF00)),
          labelStyle: TextStyle(color: Color(0xFF00FF00)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00FF00)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00FF00), width: 2),
          ),
        ),

        // Snackbars
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'PixelFont',
          ),
          actionTextColor: Color(0xFF00FF00),
        ),

        // Dialogs
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'PixelFont',
          ),
          contentTextStyle: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'PixelFont',
          ),
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
            ),
            SizedBox(height: 16),
            Text(
              "LOADING...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00FF00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
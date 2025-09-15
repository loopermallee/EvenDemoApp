import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ble_screen.dart';
import 'screens/evenai_screen.dart';
import 'screens/settings_screen.dart';

// ✅ Import ChatGPT service
import 'services/chatgpt_service.dart';

// ✅ Import HUD overlay
import 'widgets/hud_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load saved ChatGPT API key at startup
  await ChatGPTService.init();

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
        fontFamily: 'PixelFont',
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
      builder: (context, child) {
        // ✅ Global overlay: show HUD on top of any screen
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const HUDOverlay(),
          ],
        );
      },
      home: const LoadingScreen(), // ✅ Start with retro loading boot
      routes: {
        '/home': (context) => const HomeScreen(),
        '/ble': (context) => const BLESScreen(),
        '/evenai': (context) => const EvenAIScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
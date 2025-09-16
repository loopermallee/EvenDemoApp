// lib/main.dart
import 'package:flutter/material.dart';

// ✅ Screens
import 'screens/loading_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ble_screen.dart';
import 'screens/evenai_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/navigate_screen.dart';
import 'screens/teleprompt_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/transcribe_screen.dart';
import 'screens/todo_screen.dart'; // ✅ Make sure class is TodoScreen
import 'screens/commute_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/gesture_settings_screen.dart'; // ✅ NEW import

// ✅ Services
import 'services/chatgpt_service.dart';
import 'services/notification_service.dart';
import 'services/gesture_mapping.dart';

// ✅ HUD overlay
import 'widgets/hud_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load saved ChatGPT API key at startup
  await ChatGPTService.init();

  // ✅ Initialize notification listener (Android)
  NotificationService.init();

  // ✅ Ensure gesture mappings exist (defaults if none saved)
  await GestureMappingService.loadMapping();

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
        // ✅ Global overlay HUD (AI replies + notifications)
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const HUDOverlay(),
          ],
        );
      },
      home: const LoadingScreen(), // ✅ Boot screen first
      routes: {
        // 🔥 After loading, navigate to Dashboard
        '/dashboard': (context) => const DashboardScreen(),

        // Core app screens
        '/ble': (context) => const BLESScreen(),
        '/evenai': (context) => const EvenAIScreen(),
        '/settings': (context) => const SettingsScreen(),

        // Tiles
        '/translate': (context) => const TranslateScreen(),
        '/navigate': (context) => const NavigateScreen(),
        '/teleprompt': (context) => const TelepromptScreen(),
        '/ai': (context) => const AIScreen(),
        '/transcribe': (context) => const TranscribeScreen(),
        '/todo': (context) => const TodoScreen(), // ✅ fixed casing
        '/commute': (context) => const CommuteScreen(),
        '/notifications': (context) => const NotificationsScreen(),

        // ✅ Gesture Settings
        '/gesture-settings': (context) => const GestureSettingsScreen(),
      },
    );
  }
}
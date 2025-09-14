import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final List<String> bootLogs = [
    "EVEN DEMO SYSTEM v1.0",
    "Initializing hardware...",
    "Checking Bluetooth module...",
    "Loading AI core services...",
    "Mounting assets...",
    "System check: OK",
    "BOOT COMPLETE",
  ];

  List<String> displayedLogs = [];
  String cursor = "";

  @override
  void initState() {
    super.initState();

    // Blinking cursor effect
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        cursor = cursor.isEmpty ? "█" : "";
      });
    });

    // Sequentially show boot logs
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (index < bootLogs.length) {
        setState(() {
          displayedLogs.add(bootLogs[index]);
        });
        index++;
      } else {
        timer.cancel();
        // Navigate to Home after short delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Retro black background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            for (final log in displayedLogs)
              Text(
                log,
                style: const TextStyle(
                  fontFamily: 'PixelFont', // ✅ Pixel retro font
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
            Text(
              cursor, // ✅ Blinking cursor at end
              style: const TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String displayText = "BOOTING SYSTEM";
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
    // Navigate after 3s
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Retro black background
      body: Center(
        child: Text(
          "$displayText$cursor",
          style: const TextStyle(
            fontFamily: 'PixelFont', // ✅ Pixel retro font
            color: Colors.greenAccent, // ✅ Neon green
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
// lib/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "EvenDemoApp",
          style: TextStyle(
            fontFamily: "PressStart2P", // Retro pixel font (make sure it's added in pubspec.yaml)
            fontSize: 14,
            color: Colors.greenAccent,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "👓 Welcome to EvenDemoApp!",
          style: TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 12,
            color: Colors.greenAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
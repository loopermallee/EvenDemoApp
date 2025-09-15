import 'dart:async';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate retro boot delay (2.5s), then go to Dashboard
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Text(
            "BOOTING EVEN OS...",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: Colors.greenAccent,
              fontFamily: 'PixelFont',
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "🤖 AI Assistant\n(Placeholder)",
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.greenAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
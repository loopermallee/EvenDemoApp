import 'package:flutter/material.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "🌐 Translate\n(Placeholder)",
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
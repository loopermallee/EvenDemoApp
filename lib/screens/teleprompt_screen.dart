import 'package:flutter/material.dart';

class TelepromptScreen extends StatelessWidget {
  const TelepromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "📜 Teleprompter\n(Placeholder)",
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
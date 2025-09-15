import 'package:flutter/material.dart';

class CommuteScreen extends StatelessWidget {
  const CommuteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚌 COMMUTE"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "🚏 Bus/MRT timings will appear here",
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: "PixelFont",
            color: Colors.greenAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
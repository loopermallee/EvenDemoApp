import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("TEST SCREEN")),
      body: Center(
        child: Text(
          "HELLO WORLD",
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}
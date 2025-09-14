import 'package:flutter/material.dart';
import 'ble_screen.dart';
import 'evenai_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HOME")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EvenAIScreen())),
              child: const Text("🤖 EVEN AI"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const BLESScreen())),
              child: const Text("🔌 BLUETOOTH"),
            ),
          ],
        ),
      ),
    );
  }
}
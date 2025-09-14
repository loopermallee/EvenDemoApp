import 'package:flutter/material.dart';

class BleScreen extends StatelessWidget {
  const BleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Manager")),
      body: const Center(
        child: Text(
          "📡 BLE Features Coming Soon...",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
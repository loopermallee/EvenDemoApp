import 'package:flutter/material.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Display Manager")),
      body: const Center(
        child: Text(
          "🖥️ Display Features Coming Soon...",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
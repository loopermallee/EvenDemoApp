import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Even Demo App"),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 40),
            const Text(
              "👓 MAIN MENU",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 18,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 40),

            // 🔹 BLE Manager (Glasses Connectivity)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("BLE Manager Coming Soon...")),
                );
              },
              child: const Text("BLUETOOTH MANAGER"),
            ),
            const SizedBox(height: 20),

            // 🔹 EvenAI (Voice/Chat AI)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("EvenAI Coming Soon...")),
                );
              },
              child: const Text("EVEN AI"),
            ),
            const SizedBox(height: 20),

            // 🔹 Image/Display Features
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Image/Display Coming Soon...")),
                );
              },
              child: const Text("DISPLAY FEATURES"),
            ),
            const SizedBox(height: 20),

            // 🔹 Settings
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings Coming Soon...")),
                );
              },
              child: const Text("SETTINGS"),
            ),
          ],
        ),
      ),
    );
  }
}
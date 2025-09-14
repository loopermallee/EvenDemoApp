import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Screen"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "👓 Even Demo App",
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Test Button Pressed!"),
                  ),
                );
              },
              child: const Text("PRESS ME"),
            ),
          ],
        ),
      ),
    );
  }
}
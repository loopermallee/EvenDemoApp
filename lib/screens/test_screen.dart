import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Retro Test Screen"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text input
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Type something...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Snackbar test
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This is a Snackbar!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text("Show Snackbar"),
            ),
            const SizedBox(height: 10),

            // Dialog test
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Retro Dialog"),
                    content: Text(
                      "You typed: ${controller.text}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CLOSE"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Show Dialog"),
            ),
          ],
        ),
      ),
    );
  }
}
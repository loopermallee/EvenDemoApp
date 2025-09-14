import 'package:flutter/material.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key});

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  String response = "";

  void sendQuery() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => response = "🤖 Thinking...");

    // TODO: integrate with real evenai_service
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        response = "AI says: 'Hello from EvenAI (mock response)!'";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🤖 EVEN AI")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Ask me anything...", // ✅ inherits PixelFont + green
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: sendQuery,
              child: const Text("SEND"),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(response),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
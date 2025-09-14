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

    setState(() {
      response = "🤖 THINKING...";
    });

    // TODO: integrate with evenai_service.dart call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        response = "AI SAYS: 'HELLO FROM EVENAI (MOCK RESPONSE)!'";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 EVENAI"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: theme.textTheme.bodyLarge,
              cursorColor: Colors.greenAccent,
              decoration: InputDecoration(
                hintText: "ASK ME ANYTHING...",
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.green.shade700,
                ),
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
                child: Text(
                  response,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
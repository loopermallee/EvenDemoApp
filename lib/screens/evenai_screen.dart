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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 EVEN AI"),
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
                hintText: "Ask me anything...",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent.shade200, width: 2),
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 1),
                    color: Colors.black,
                  ),
                  child: Text(
                    response,
                    style: theme.textTheme.bodyLarge,
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
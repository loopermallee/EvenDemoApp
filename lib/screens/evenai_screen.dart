import 'package:flutter/material.dart';
import '../services/chatgpt_service.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key});

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  String response = "";

  Future<void> sendQuery() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => response = "🤖 Thinking...");

    final reply = await ChatGPTService.askChatGPT(query);

    setState(() => response = reply);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🤖 EVEN AI")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: "Ask me anything...",
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
                child: Text(response, style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
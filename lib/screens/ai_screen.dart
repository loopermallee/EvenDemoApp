// lib/screens/ai_screen.dart
import 'package:flutter/material.dart';
import '../services/chatgpt_service.dart';
import '../services/gesture_handler.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  String response = "";
  bool isLoading = false;

  Future<void> _sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      response = "";
    });

    final reply = await ChatGPTService.askChatGPT(query);

    setState(() {
      isLoading = false;
      response = reply;
    });

    // ✅ Send reply to HUD
    GestureHandler.showHUD(reply);
  }

  /// Placeholder for voice input
  Future<void> _startVoiceInput() async {
    // In future: integrate STT → text
    _sendQuery("🎤 [Voice input simulated]");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🤖 Ershin AI")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input box
            TextField(
              controller: _controller,
              style: theme.textTheme.bodyLarge,
              cursorColor: Colors.greenAccent,
              decoration: const InputDecoration(
                hintText: "Ask Ershin or Fou-Lu...",
              ),
              onSubmitted: _sendQuery,
            ),
            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sendQuery(_controller.text),
                    child: const Text("SEND"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startVoiceInput,
                    child: const Text("🎤 VOICE"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Response area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  color: Colors.black,
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.greenAccent),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          response.isEmpty ? "No reply yet." : response,
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
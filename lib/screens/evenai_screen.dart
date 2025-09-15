// lib/screens/evenai_screen.dart
import 'package:flutter/material.dart';
import '../services/evenai_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key, this.connectedDevice});

  final BluetoothDevice? connectedDevice;

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final EvenAIService _evenAI = EvenAIService();

  String response = "";
  bool isConnecting = false;
  bool isListening = false; // ✅ Glasses mic state

  Future<void> sendQuery() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      response = "🤖 Thinking...";
    });

    final reply = await _evenAI.sendQuery(query);

    if (mounted) {
      setState(() => response = reply);
    }
  }

  /// ✅ Triggered when glasses mic starts
  Future<void> startMic() async {
    setState(() {
      isListening = true;
      response = "🎤 Listening via glasses mic...";
    });
    await _evenAI.startListening();
  }

  /// ✅ Triggered when glasses mic stops
  Future<void> stopMic() async {
    setState(() {
      isListening = false;
      response = "🤖 Thinking...";
    });
    final reply = await _evenAI.stopAndSend();

    if (mounted) {
      setState(() => response = reply);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isConnecting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 EVEN AI"),
        centerTitle: true,
        actions: [
          // ✅ Mic control buttons (for testing until glasses auto-trigger is wired)
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.greenAccent),
            onPressed: startMic,
            tooltip: "Start Listening",
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            onPressed: stopMic,
            tooltip: "Stop & Send",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ BLE Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: widget.connectedDevice != null
                  ? Colors.green.shade900
                  : Colors.red.shade900,
              child: Text(
                widget.connectedDevice != null
                    ? "🟢 Connected to ${widget.connectedDevice!.name.isNotEmpty ? widget.connectedDevice!.name : widget.connectedDevice!.id}"
                    : "🔴 Not Connected",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Listening indicator
            if (isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "🎤 Glasses mic active... speak now!",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.greenAccent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // ✅ Debug input field (manual queries)
            TextField(
              controller: _controller,
              style: theme.textTheme.bodyLarge,
              cursorColor: Colors.greenAccent,
              decoration: const InputDecoration(
                hintText: "Type here (debug only)...",
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Send button
            ElevatedButton(
              onPressed: sendQuery,
              child: const Text("SEND"),
            ),
            const SizedBox(height: 24),

            // ✅ AI Response
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  response.isEmpty ? "No reply yet." : response,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.greenAccent,
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
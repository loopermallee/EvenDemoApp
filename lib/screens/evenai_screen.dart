// lib/screens/evenai_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/evenai.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key, this.connectedDevice});

  final BluetoothDevice? connectedDevice;

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final EvenAI evenAI = EvenAI.to;

  String response = "";
  bool isListening = false; // ✅ Glasses mic state

  /// Manual query (debug mode only)
  Future<void> sendQuery() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      response = "🤖 Thinking...";
    });

    final result = await evenAI.processTranscript(query);

    if (mounted) {
      setState(() => response = "Manual: $query\n\n$result");
    }
  }

  /// ✅ Triggered when glasses mic starts
  Future<void> startMic() async {
    setState(() {
      isListening = true;
      response = "🎤 Listening via glasses mic...";
    });
    // Instead of processing here, we just notify EvenAI
    await evenAI.startListening(Uint8List(0));
  }

  /// ✅ Triggered when glasses mic stops
  Future<void> stopMic() async {
    setState(() {
      isListening = false;
      response = "🤖 Processing...";
    });

    // Simulate receiving a transcript (in real case, Kotlin plugin sends it)
    await evenAI.processTranscript("Example transcript from glasses");

    if (mounted) {
      setState(() => response = evenAI.lastTranscript.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              onSubmitted: (_) => sendQuery(),
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
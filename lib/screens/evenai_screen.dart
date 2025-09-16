// lib/screens/evenai_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../services/evenai.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key, this.connectedDevice});

  final BluetoothDevice? connectedDevice;

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final EvenAI _evenAI = Get.put(EvenAI());

  String response = "";
  bool isListening = false; // ✅ Glasses mic state

  Future<void> sendQuery() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      response = "🤖 Thinking...";
    });

    final result = await _evenAI._processAudio(
      // ✅ Simulate text input by converting query → fake audio
      Uint8List.fromList(query.codeUnits),
    );

    setState(() {
      response = result != null ? result.toString() : "⚠️ No reply";
    });
  }

  /// ✅ Triggered when glasses mic starts
  Future<void> startMic() async {
    setState(() {
      isListening = true;
      response = "🎤 Listening via glasses mic...";
    });
    // Normally triggered automatically via BLE → here we simulate
    await _evenAI.startListening(Uint8List(0));
  }

  /// ✅ Triggered when glasses mic stops
  Future<void> stopMic() async {
    setState(() {
      isListening = false;
      response = "🤖 Processing...";
    });

    // Flush BLE buffer → AI pipeline handles it
    final fakeAudio = Uint8List.fromList("Hello from glasses mic".codeUnits);
    await _evenAI.startListening(fakeAudio);

    setState(() {
      response = "✅ Processed via EvenAI (see HUD)";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 EVEN AI"),
        centerTitle: true,
        actions: [
          // ✅ Mic control buttons (manual debug triggers)
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
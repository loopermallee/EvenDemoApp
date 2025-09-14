import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble.dart';

class EvenAIScreen extends StatefulWidget {
  const EvenAIScreen({super.key});

  @override
  State<EvenAIScreen> createState() => _EvenAIScreenState();
}

class _EvenAIScreenState extends State<EvenAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final BLEService _bleService = BLEService();

  String response = "";
  BluetoothDevice? connectedDevice;
  bool isConnecting = true;

  @override
  void initState() {
    super.initState();
    _ensureBleConnection();
  }

  /// Ensure BLE is connected before AI use
  Future<void> _ensureBleConnection() async {
    final device = await _bleService.reconnectLastDevice();
    if (mounted) {
      setState(() {
        connectedDevice = device;
        isConnecting = false;
      });

      if (device == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No glasses connected. Please connect via Bluetooth.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Connected to ${device.name.isNotEmpty ? device.name : device.id}")),
        );
      }
    }
  }

  void sendQuery() {
    if (connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Glasses not connected. Please connect via Bluetooth.")),
      );
      return;
    }

    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => response = "🤖 Thinking...");

    // TODO: integrate with your ChatGPT API BYOK service
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        response = "AI says: 'Hello from EvenAI (mock response)!'";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isConnecting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("🤖 EVEN AI")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: theme.textTheme.bodyLarge,
              cursorColor: Colors.greenAccent,
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
                child: Text(
                  response,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
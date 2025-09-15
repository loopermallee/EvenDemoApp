import 'package:flutter/material.dart';
import '../services/chatgpt_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved API key into text field when opening settings
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final savedKey = await ChatGPTService.loadApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = savedKey ?? "";
      });
    }
  }

  Future<void> _saveApiKey() async {
    await ChatGPTService.setApiKey(_apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ API Key saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ SETTINGS")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: true, // hide API key
              decoration: const InputDecoration(
                labelText: "Enter ChatGPT API Key",
                hintText: "sk-xxxx...",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveApiKey,
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }
}
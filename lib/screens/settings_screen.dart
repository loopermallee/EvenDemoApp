import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chatgpt_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _hasSavedKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString("chatgpt_api_key");

    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _hasSavedKey = true;
        // ✅ Instead of showing the real key, show a glitchy placeholder
        _apiKeyController.text = "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒";
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();

    if (key.isEmpty || key == "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter a valid API Key")),
      );
      return;
    }

    await ChatGPTService.setApiKey(key);

    setState(() {
      _hasSavedKey = true;
      _apiKeyController.text = "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"; // ✅ Show glitch placeholder
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ API Key saved & in use")),
    );
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
              obscureText: false, // ✅ show placeholder as text, not dots
              style: const TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.greenAccent,
              ),
              decoration: InputDecoration(
                labelText: "Enter ChatGPT API Key",
                hintText: "sk-xxxx...",
                helperText: _hasSavedKey
                    ? "🔒 Key is saved & active (hidden for security)"
                    : "Enter a new API key to activate",
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
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
  bool _editingKey = false;

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
        _editingKey = false;
        _apiKeyController.text = "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"; // glitchy placeholder
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
      _editingKey = false;
      _apiKeyController.text = "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"; // revert to placeholder
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ API Key saved & in use")),
    );
  }

  void _enableEditing() {
    setState(() {
      _editingKey = true;
      _apiKeyController.clear();
    });
  }

  void _openGestureSettings() {
    Navigator.pushNamed(context, "/gesture-settings");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ SETTINGS")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔑 API Key section
          TextField(
            controller: _apiKeyController,
            obscureText: false, // ✅ show placeholder as text
            enabled: !_hasSavedKey || _editingKey,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.greenAccent,
            ),
            decoration: InputDecoration(
              labelText: "Enter ChatGPT API Key",
              hintText: "sk-xxxx...",
              helperText: _hasSavedKey
                  ? _editingKey
                      ? "✍️ Enter a new key to replace the old one"
                      : "🔒 Key is saved & active (hidden for security)"
                  : "Enter a new API key to activate",
            ),
          ),
          const SizedBox(height: 16),
          if (_hasSavedKey && !_editingKey) ...[
            ElevatedButton(
              onPressed: _enableEditing,
              child: const Text("CHANGE API KEY"),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _saveApiKey,
              child: const Text("SAVE"),
            ),
          ],

          const Divider(height: 32, thickness: 1, color: Colors.greenAccent),

          // 🎛️ Gesture Mapping tile
          ListTile(
            title: const Text(
              "🎛️ Gesture Mapping",
              style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 14),
            onTap: _openGestureSettings,
          ),
        ],
      ),
    );
  }
}
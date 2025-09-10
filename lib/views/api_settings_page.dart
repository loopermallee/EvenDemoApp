// lib/views/api_settings_page.dart
//
// Simple screen to paste/save the user's OpenAI API key securely on-device.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});
  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  static const _kKeyName = 'openai_api_key';
  final _storage = const FlutterSecureStorage();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await _storage.read(key: _kKeyName);
    setState(() => _controller.text = existing ?? '');
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty || !key.startsWith('sk-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a valid OpenAI API key (starts with sk-)')),
      );
      return;
    }
    setState(() => _saving = true);
    await _storage.write(key: _kKeyName, value: key);
    setState(() => _saving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved locally (secure storage).')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatGPT (BYOK) Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Paste your OpenAI API key. It stays only on this device.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
              obscureText: true, // hide like a password
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get a key at https://platform.openai.com → API keys.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
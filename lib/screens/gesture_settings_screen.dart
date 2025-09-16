// lib/screens/gesture_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:demo_ai_even/services/gesture_mapping.dart';

class GestureSettingsScreen extends StatefulWidget {
  const GestureSettingsScreen({super.key});

  @override
  State<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends State<GestureSettingsScreen> {
  final Map<int, String> _mapping = Map.from(GestureMappingService.mapping);

  final List<String> _actions = [
    "singleTapRight",
    "singleTapLeft",
    "doubleTapRight",
    "doubleTapLeft",
    "tripleTap",
    "longHold",
    "ai",
    "translate",
    "commute",
    "teleprompt",
    "closeHUD",
    "unknown",
  ];

  Future<void> _save() async {
    for (final entry in _mapping.entries) {
      await GestureMappingService.updateMapping(entry.key, entry.value);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Gesture mapping saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🎛️ Gesture Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _mapping.entries.map((entry) {
          final code = entry.key;
          final current = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 1),
              color: Colors.black,
            ),
            child: ListTile(
              title: Text("Gesture Code: 0x${code.toRadixString(16).toUpperCase()}",
                  style: theme.textTheme.bodyLarge),
              trailing: DropdownButton<String>(
                dropdownColor: Colors.black,
                value: current,
                items: _actions.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(action,
                        style: const TextStyle(
                            fontFamily: "PixelFont",
                            color: Colors.greenAccent,
                            fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _mapping[code] = value;
                    });
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _save,
          child: const Text("💾 Save Mapping"),
        ),
      ),
    );
  }
}
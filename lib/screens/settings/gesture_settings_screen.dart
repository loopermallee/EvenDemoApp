// lib/screens/settings/gesture_settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/gesture_mapping.dart';

class GestureSettingsScreen extends StatefulWidget {
  const GestureSettingsScreen({super.key});

  @override
  State<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends State<GestureSettingsScreen> {
  Map<String, String> mapping = {};
  final actions = ["ai", "translate", "commute", "teleprompt", "notifications", "none"];

  @override
  void initState() {
    super.initState();
    _loadMapping();
  }

  Future<void> _loadMapping() async {
    final data = await GestureMappingService.loadMapping();
    setState(() {
      mapping = data;
    });
  }

  Future<void> _updateMapping(String gesture, String action) async {
    await GestureMappingService.saveMapping(gesture, action);
    await _loadMapping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎛 Gesture Mapping")),
      body: mapping.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: mapping.keys.map((gesture) {
                return ListTile(
                  title: Text("Gesture: $gesture"),
                  trailing: DropdownButton<String>(
                    value: mapping[gesture],
                    items: actions
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateMapping(gesture, value);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("⚙ SETTINGS"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(
                "Option 1",
                style: theme.textTheme.bodyLarge,
              ),
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.green.shade700,
                inactiveTrackColor: Colors.black,
              ),
            ),
            const Divider(color: Colors.greenAccent),
            ListTile(
              title: Text(
                "Option 2",
                style: theme.textTheme.bodyLarge,
              ),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("APPLY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
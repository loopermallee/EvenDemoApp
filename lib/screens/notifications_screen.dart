import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🔔 NOTIFICATIONS")),
      body: Center(
        child: Text(
          "📩 Notifications placeholder\n\nThis will display selected app notifications (e.g., WhatsApp).",
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
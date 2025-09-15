// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ✅ Stub: Allowed apps filter (expand later in Settings)
  final List<String> allowedApps = const [
    "WhatsApp",
    "Telegram",
    "SMS",
    "Email",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🔔 NOTIFICATIONS")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📱 Notifications (Placeholder)",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // ✅ Stub: Show which apps are enabled
            Text(
              "Allowed apps:",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final app in allowedApps)
              Text("• $app", style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
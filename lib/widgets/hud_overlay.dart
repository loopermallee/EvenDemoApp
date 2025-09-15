import 'package:flutter/material.dart';
import '../services/gesture_handler.dart';

/// A floating retro HUD that shows tap feedback + launching text.
class HUDOverlay extends StatelessWidget {
  const HUDOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String?>(
      valueListenable: GestureHandler.hudMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6), // semi-transparent overlay
            alignment: Alignment.center,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
                shadows: const [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.green,
                    offset: Offset(0, 0),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/gesture_handler.dart';

/// A floating retro HUD that shows tap feedback + launching text.
/// Now with a Matrix-style glitch effect (0s and 1s).
/// Auto-clears after 2 seconds.
class HUDOverlay extends StatefulWidget {
  const HUDOverlay({super.key});

  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  Timer? _hideTimer;
  Timer? _glitchTimer;
  String? _displayText;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _glitchTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      GestureHandler.hudMessage.value = null;
    });
  }

  void _startGlitchEffect(String realText) {
    _glitchTimer?.cancel();
    const glitchDuration = Duration(milliseconds: 300);
    const glitchInterval = Duration(milliseconds: 50);
    final rand = Random();

    _glitchTimer = Timer.periodic(glitchInterval, (timer) {
      if (timer.tick * glitchInterval >= glitchDuration) {
        timer.cancel();
        setState(() => _displayText = realText); // reveal final message
      } else {
        final scrambled = List.generate(
          realText.length,
          (_) => rand.nextBool() ? "0" : "1", // matrix style glitch
        ).join();
        setState(() => _displayText = scrambled);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String?>(
      valueListenable: GestureHandler.hudMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();

        // Restart glitch + auto-hide whenever a new message comes
        _scheduleAutoHide();
        if (_displayText != message) {
          _startGlitchEffect(message);
        }

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6), // retro HUD overlay
            alignment: Alignment.center,
            child: Text(
              _displayText ?? "",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    blurRadius: 10,
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
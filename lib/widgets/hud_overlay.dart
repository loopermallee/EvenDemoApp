import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gesture_handler.dart';

/// Retro HUD with a scrolling marquee (Breath of Fire vibe).
/// Message slides left once across the screen, then disappears.
class HUDOverlay extends StatefulWidget {
  const HUDOverlay({super.key});

  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  Timer? _scrollTimer;
  String? _message;
  double _position = 1.2; // start off-screen (right)

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _startMarquee(String text) {
    _scrollTimer?.cancel();
    _position = 1.2;
    _message = text;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _position -= 0.01;
        if (_position < -1.5) {
          timer.cancel();
          GestureHandler.hudMessage.value = null;
          _message = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String?>(
      valueListenable: GestureHandler.hudMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();

        if (_message != message) {
          _startMarquee(message);
        }

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6),
            alignment: Alignment.center,
            child: FractionalTranslation(
              translation: Offset(_position, 0),
              child: Text(
                _message ?? "",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.green,
                      offset: Offset(0, 0),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
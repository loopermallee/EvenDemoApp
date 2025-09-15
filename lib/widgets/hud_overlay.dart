import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gesture_handler.dart';

/// Retro HUD overlay with multi-page support + auto page advance.
/// - Shows current page text
/// - Advances automatically after 5s (reset if user taps manually)
/// - Displays (1/3) page indicator and countdown [5s]
class HUDOverlay extends StatefulWidget {
  const HUDOverlay({super.key});

  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  Timer? _autoPageTimer;
  int _remainingSeconds = 5;

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startAutoAdvance() {
    _cancelTimer();
    _remainingSeconds = 5;
    _autoPageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        GestureHandler.nextPage();
        _startAutoAdvance(); // restart for next page
      }
    });
  }

  void _cancelTimer() {
    _autoPageTimer?.cancel();
    _autoPageTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<String>?>(
      valueListenable: GestureHandler.hudPages,
      builder: (context, pages, _) {
        if (pages == null || pages.isEmpty) {
          _cancelTimer();
          return const SizedBox.shrink();
        }

        // Start/restart timer whenever new pages appear
        if (_autoPageTimer == null) {
          _startAutoAdvance();
        }

        final currentText = GestureHandler.currentPage ?? "";
        final pageIndicator = GestureHandler.pageIndicator();

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      currentText,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Footer: page indicator + countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pageIndicator, // e.g. (1/3)
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.greenAccent,
                      ),
                    ),
                    Text(
                      "[${_remainingSeconds}s]", // countdown timer
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.greenAccent.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
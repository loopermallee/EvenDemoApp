import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gesture_handler.dart';

/// Retro HUD overlay with multi-page support + auto page advance.
/// - Pages auto-advance dynamically (3–6s depending on text length)
/// - User can tap left/right to flip manually
/// - Clears automatically after last page
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

    // ⏳ Adjust countdown based on text length
    final text = GestureHandler.currentPage ?? "";
    if (text.length < 60) {
      _remainingSeconds = 3; // short message
    } else if (text.length < 150) {
      _remainingSeconds = 4; // medium
    } else {
      _remainingSeconds = 6; // long message
    }

    _autoPageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        GestureHandler.nextPage();
        if (GestureHandler.isHUDActive) {
          _startAutoAdvance(); // restart for next page
        }
      }
    });
  }

  void _cancelTimer() {
    _autoPageTimer?.cancel();
    _autoPageTimer = null;
  }

  void _onTapLeft() {
    GestureHandler.prevPage();
    _startAutoAdvance();
  }

  void _onTapRight() {
    GestureHandler.nextPage();
    if (GestureHandler.isHUDActive) {
      _startAutoAdvance();
    }
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

        if (_autoPageTimer == null) {
          _startAutoAdvance();
        }

        final currentText = GestureHandler.currentPage ?? "";
        final pageIndicator = GestureHandler.pageIndicator();

        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.localPosition.dx < width / 2) {
                _onTapLeft();
              } else {
                _onTapRight();
              }
            },
            child: Container(
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text page
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
                        "[${_remainingSeconds}s]",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.greenAccent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
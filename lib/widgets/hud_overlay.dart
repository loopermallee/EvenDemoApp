// lib/widgets/hud_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/gesture_handler.dart';

class HUDOverlay extends StatefulWidget {
  const HUDOverlay({super.key});

  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  List<String> _pages = [];
  int _currentPage = 0;
  String _displayedText = "";
  double _opacity = 0.0;

  Timer? _textTimer;
  Timer? _countdownTimer;
  int _charIndex = 0;
  int _countdown = 0;
  bool _isManual = false; // ✅ track manual control

  @override
  void initState() {
    super.initState();

    // 🔄 Listen for HUD messages
    GestureHandler.hudMessage.listen((msg) {
      if (msg == null || msg.isEmpty) {
        _hideHUD();
      } else {
        _showHUD(msg);
      }
    });

    // 🔄 Listen for gesture overrides
    GestureHandler.onNextPage = _nextPage;
    GestureHandler.onPrevPage = _prevPage;
    GestureHandler.onCloseHUD = _hideHUD;
  }

  /// Split into RPG-style pages (~120 chars per page)
  List<String> _paginate(String text) {
    final words = text.split(' ');
    List<String> pages = [];
    String buffer = "";

    for (final word in words) {
      if ((buffer + word).length > 120) {
        pages.add(buffer.trim());
        buffer = "";
      }
      buffer += "$word ";
    }
    if (buffer.isNotEmpty) {
      pages.add(buffer.trim());
    }
    return pages;
  }

  void _showHUD(String text) {
    _pages = _paginate(text);
    _currentPage = 0;
    _isManual = false;
    _startPage(_pages[_currentPage]);
    setState(() => _opacity = 1.0); // fade in
  }

  void _startPage(String pageText) {
    setState(() {
      _displayedText = "";
      _charIndex = 0;
    });

    _textTimer?.cancel();
    _textTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (_charIndex < pageText.length) {
        setState(() {
          _displayedText += pageText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        if (!_isManual) _startCountdown(_estimateTime(pageText));
      }
    });
  }

  void _startCountdown(int seconds) {
    _countdown = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        _countdownTimer?.cancel();
        if (_currentPage < _pages.length - 1) {
          _nextPage();
        } else {
          _hideHUD();
        }
      } else {
        setState(() => _countdown--);
      }
    });
  }

  int _estimateTime(String text) {
    if (text.length < 60) return 3;
    if (text.length < 150) return 5;
    return 8;
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _isManual = true;
      _countdownTimer?.cancel();
      _currentPage++;
      _startPage(_pages[_currentPage]);
    } else {
      _hideHUD();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _isManual = true;
      _countdownTimer?.cancel();
      _currentPage--;
      _startPage(_pages[_currentPage]);
    }
  }

  void _hideHUD() {
    _textTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _opacity = 0.0; // fade out
      _pages = [];
      _displayedText = "";
      _currentPage = 0;
      _isManual = false;
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty && _opacity == 0.0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true, // HUD is passive overlay
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border.all(color: Colors.greenAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text
                Text(
                  _displayedText,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontFamily: 'PixelFont',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Countdown
                if (_pages.length > 1 && _countdown > 0 && !_isManual)
                  Text(
                    "Next page in $_countdown…",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontFamily: 'PixelFont',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
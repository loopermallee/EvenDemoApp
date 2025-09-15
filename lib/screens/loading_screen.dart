import 'dart:async';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final String _bootText = "BOOTING EVEN OS...";
  String _visibleText = "";
  int _charIndex = 0;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();

    // Start typing effect
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_charIndex < _bootText.length) {
        setState(() {
          _visibleText += _bootText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        // After full text is shown, wait then go to dashboard
        Timer(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/dashboard');
        });
      }
    });

    // Blinking cursor effect
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cursorVisible = !_cursorVisible;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Text(
            "$_visibleText${_cursorVisible ? ' █' : ''}", // retro cursor
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: Colors.greenAccent,
              fontFamily: 'PixelFont',
            ),
          ),
        ),
      ),
    );
  }
}
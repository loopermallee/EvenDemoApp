// lib/services/stt_service.dart
//
// Minimal-latency bridge to Android SpeechRecognizer via
//   - MethodChannel('method.speech')  → start/stop/cancel
//   - EventChannel('eventSpeechRecognize') → partial/final text
//
// Optimized to quickly return a final transcript after stop()
// with a short timeout fallback.

import 'dart:async';
import 'package:flutter/services.dart';

class STTService {
  STTService._() {
    _listenNativeStream();
  }
  static final STTService instance = STTService._();

  final _method = const MethodChannel('method.speech');
  final _event = const EventChannel('eventSpeechRecognize');

  String _latestPartial = '';
  String _finalText = '';
  StreamSubscription? _sub;
  final _finalController = StreamController<String>.broadcast();

  void _listenNativeStream() {
    _sub ??= _event.receiveBroadcastStream().listen((data) {
      if (data is Map) {
        final text = (data['script'] ?? '').toString();
        final isFinal = data['isFinal'] == true;
        if (isFinal) {
          _finalText = text;
          if (!_finalController.isClosed) _finalController.add(_finalText);
        } else {
          _latestPartial = text;
        }
      } else if (data is String) {
        _latestPartial = data;
      }
    }, onError: (_) {
      // no-op
    });
  }

  Future<bool> startListening() async {
    _latestPartial = '';
    _finalText = '';
    try {
      await _method.invokeMethod('start');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> stopAndGetTranscript() async {
    try {
      await _method.invokeMethod('stop');
    } catch (_) {}

    try {
      final text = await _finalController.stream.first.timeout(
        const Duration(milliseconds: 900),
        onTimeout: () => _finalText.isNotEmpty ? _finalText : _latestPartial,
      );
      return (text ?? '').trim();
    } catch (_) {
      if (_finalText.trim().isNotEmpty) return _finalText.trim();
      if (_latestPartial.trim().isNotEmpty) return _latestPartial.trim();
      return '';
    }
  }

  Future<void> cancel() async {
    try { await _method.invokeMethod('cancel'); } catch (_) {}
    _latestPartial = '';
    _finalText = '';
  }
}
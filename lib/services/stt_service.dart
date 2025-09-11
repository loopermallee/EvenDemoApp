// lib/services/stt_service.dart
//
// Flutter STT bridge that tells Android when to start/stop,
// while Android streams partial/final transcripts over EventChannel "eventSpeechRecognize".

import 'dart:async';
import 'package:flutter/services.dart';

class STTService {
  STTService._() {
    _listenNativeStream(); // listen to Android partial/final results
  }
  static final STTService instance = STTService._();

  final _method = const MethodChannel('method.speech');
  // NOTE: BleManager already listens to 'eventSpeechRecognize' and forwards to EvenAI.setTranscript().
  // We also listen here so stopAndGetTranscript() can return a final string if EvenAI asks for it.
  final _event = const EventChannel('eventSpeechRecognize');

  String _latestPartial = '';
  String _finalText = '';
  StreamSubscription? _sub;

  void _listenNativeStream() {
    _sub ??= _event.receiveBroadcastStream().listen((data) {
      if (data is Map) {
        final text = (data['script'] ?? '').toString();
        final isFinal = data['isFinal'] == true;
        if (isFinal) {
          _finalText = text;
        } else {
          _latestPartial = text;
        }
      } else if (data is String) {
        // If native ever sends plain string
        _latestPartial = data;
      }
    }, onError: (_) {
      // ignore for now
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
    } catch (_) {
      // ignored
    }
    // Prefer final; if not present, return best partial
    if (_finalText.trim().isNotEmpty) return _finalText.trim();
    if (_latestPartial.trim().isNotEmpty) return _latestPartial.trim();
    return '';
  }

  Future<void> cancel() async {
    try {
      await _method.invokeMethod('cancel');
    } catch (_) {
      // ignored
    }
    _latestPartial = '';
    _finalText = '';
  }
}

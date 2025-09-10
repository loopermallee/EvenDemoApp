// lib/services/stt_service.dart
import 'dart:async';

class STTService {
  STTService._();
  static final STTService instance = STTService._();

  bool _isListening = false;
  final StreamController<String> _transcriptController = StreamController.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;

  Future<void> startListening({String language = "en-US"}) async {
    _isListening = true;
    // TODO: Call into platform (iOS/Android) via MethodChannel/EventChannel
    print("STTService: startListening in $language");
  }

  Future<String> stopAndGetTranscript() async {
    _isListening = false;
    // TODO: return final recognized text from native side
    print("STTService: stopAndGetTranscript");
    return "Stub transcript"; // Replace with real result
  }

  Future<void> cancel() async {
    _isListening = false;
    print("STTService: cancel");
  }

  bool get isListening => _isListening;

  void dispose() {
    _transcriptController.close();
  }
}
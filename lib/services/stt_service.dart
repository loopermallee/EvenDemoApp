// lib/services/stt_service.dart
//
// Minimal no-op STT stub so EvenAI compiles.
// Real transcripts come from Android via EventChannel "eventSpeechRecognize".

class STTService {
  STTService._();
  static final STTService instance = STTService._();

  Future<bool> startListening() async => true;
  Future<String> stopAndGetTranscript() async => '';
  Future<void> cancel() async {}
}
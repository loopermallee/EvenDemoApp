// lib/services/stt_service.dart
//
// Minimal no-op STT stub so EvenAI compiles.
// We already get transcripts from Android via the EventChannel
// "eventSpeechRecognize", so this stub just does nothing.

class STTService {
  STTService._();
  static final STTService instance = STTService._();

  // Pretend to start listening; Android native handles real capture.
  Future<bool> startListening() async => true;

  // Return empty so EvenAI falls back to the native transcript
  // (set via EvenAI.setTranscript(...)).
  Future<String> stopAndGetTranscript() async => '';

  // Nothing to cancel in the stub, but keep the API.
  Future<void> cancel() async {}
}
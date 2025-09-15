// lib/services/stt_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to handle Speech-to-Text (STT) via OpenAI Whisper API.
/// You pass it audio bytes (PCM/WAV), it sends to API, and gives you text back.
class STTService {
  static final _storage = const FlutterSecureStorage();

  /// Transcribes audio using OpenAI Whisper.
  /// [audioBytes] should be valid PCM/WAV bytes.
  static Future<String?> transcribe(Uint8List audioBytes) async {
    try {
      final apiKey = await _storage.read(key: "openai_api_key");
      if (apiKey == null) {
        throw Exception("❌ No OpenAI API key found in secure storage.");
      }

      // Build request to OpenAI Whisper
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.openai.com/v1/audio/transcriptions"),
      );

      request.headers["Authorization"] = "Bearer $apiKey";

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: "audio.wav",
        ),
      );

      request.fields["model"] = "whisper-1";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["text"] ?? "";
      } else {
        print("❌ STT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ STT error: $e");
      return null;
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bananatalk_app/models/ai/speech_model.dart';
import 'package:bananatalk_app/services/ai_service.dart';

/// Fetches a spoken version of one line and plays it.
///
/// Deliberately not TutorVoiceService: that one owns a FlutterSoundRecorder and
/// microphone permissions for the tutor's voice chat, and a listening station
/// never records. The backend's speech/tts endpoint already deduplicates by
/// content hash through AudioCache, so each distinct sentence is synthesized
/// once for every learner who ever hears it.
class ClipAudio {
  final AudioPlayer _player = AudioPlayer();

  /// Returns the audio URL for [text], or null when TTS is unavailable.
  static Future<String?> fetchUrl(String text, String language) async {
    try {
      final result = await AIService.generateTTS(
        TTSRequest(text: text, language: language),
      );
      if (result['success'] != true) return null;
      final data = result['data'];
      return data is TTSResponse ? data.audioUrl : null;
    } catch (e) {
      debugPrint('[clipAudio] TTS failed: $e');
      return null;
    }
  }

  Future<void> play(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      debugPrint('[clipAudio] playback failed: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

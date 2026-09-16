import 'package:audio_session/audio_session.dart';
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

  /// Claims the audio session for speech playback before the first clip.
  ///
  /// Without this the station is silent on iPhone in two ways that both read as
  /// "the button does nothing": the default category is silenced by the ring/
  /// silent switch, and flutter_sound, WebRTC and CallKit each leave the shared
  /// session in playAndRecord — which routes to the earpiece, not the speaker —
  /// once voice chat, a call or the tutor has run. just_audio does not touch
  /// AVAudioSession itself, so nothing else restores it.
  static Future<void> _claimSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      ));
      await session.setActive(true);
    } catch (e) {
      // A session we could not claim still often plays; failing here must not
      // cost the learner the clip.
      debugPrint('[clipAudio] audio session unavailable: $e');
    }
  }

  Future<void> play(String url) async {
    try {
      await _claimSession();
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

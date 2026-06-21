import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Recorder + player wrapper for the Pronunciation Coach drill.
/// Scoped to drill flows so the chat recorder lifecycle stays clean.
class PronunciationVoiceService {
  FlutterSoundRecorder? _recorder;
  AudioPlayer? _player;
  String? _currentRecordingPath;

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _ensureRecorder() async {
    if (_recorder != null) return;
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    // Configure AVAudioSession so iOS hands over the microphone hardware.
    // Without this the recorder silently fails on real devices — the same
    // configuration is used by the chat VoiceRecorderWidget.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    await _recorder!.setSubscriptionDuration(
      const Duration(milliseconds: 100),
    );
  }

  Future<String> startRecording() async {
    // Stop any active TTS playback first — just_audio and flutter_sound
    // both compete for AVAudioSession on iOS, and leaving the player active
    // causes startRecorder to throw or silently fail.
    await stopPlayback();
    await _ensureRecorder();
    final tmp = await getTemporaryDirectory();
    // Codec.aacMP4 → .m4a. Whisper rejects raw aacADTS (.aac) with
    // 400 "Invalid file format". MP4-wrapped AAC is on its accepted list.
    final path =
        '${tmp.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacMP4);
    _currentRecordingPath = path;
    return path;
  }

  Future<String?> stopRecording() async {
    if (_recorder == null) return _currentRecordingPath;
    try {
      if (_recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
    } catch (e) {
      debugPrint('[pron] stopRecording: $e');
    }
    return _currentRecordingPath;
  }

  Future<void> stopPlayback() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[pron] stopPlayback: $e');
    }
  }

  /// Plays a TTS reference clip from its remote URL.
  Future<void> playReference(String url) async {
    if (url.isEmpty) return;
    _player ??= AudioPlayer();
    try {
      await _player!.setUrl(url);
      await _player!.play();
    } catch (e) {
      debugPrint('[pron] playReference: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder?.closeRecorder();
    } catch (e) {
      debugPrint('[pron] recorder close: $e');
    }
    _recorder = null;
    try {
      await _player?.dispose();
    } catch (e) {
      debugPrint('[pron] player dispose: $e');
    }
    _player = null;
  }
}

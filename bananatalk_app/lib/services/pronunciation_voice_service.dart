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
  }

  Future<String> startRecording() async {
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
    if (_recorder == null || !(_recorder!.isRecording)) {
      return _currentRecordingPath;
    }
    await _recorder!.stopRecorder();
    return _currentRecordingPath;
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

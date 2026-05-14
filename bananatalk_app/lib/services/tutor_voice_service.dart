import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bananatalk_app/services/api_client.dart';

/// Records short voice utterances, posts them to the tutor STT endpoint,
/// and plays back TTS audio for assistant replies.
///
/// This is a session-scoped service: one instance per chat screen. Holds
/// the underlying [FlutterSoundRecorder] and [AudioPlayer] across the
/// session and disposes both on [dispose].
class TutorVoiceService {
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _player = AudioPlayer();
  bool _recorderReady = false;
  String? _currentPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  /// Lazy-init the recorder (opens audio session). Returns true on success.
  Future<bool> ensureRecorder() async {
    if (_recorderReady) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    _recorder = FlutterSoundRecorder();
    try {
      await _recorder!.openRecorder();
      _recorderReady = true;
      return true;
    } catch (e) {
      debugPrint('[tutorVoice] openRecorder failed: $e');
      return false;
    }
  }

  /// Begin recording to a temp .m4a file. Returns false if permissions
  /// were denied or recorder init failed.
  ///
  /// Codec.aacMP4 (NOT aacADTS) — Whisper rejects raw AAC streams with
  /// 400 "Invalid file format" because aacADTS isn't in its accepted
  /// container list. The MP4 wrapper is what makes the file .m4a, which
  /// Whisper does accept.
  Future<bool> startRecording() async {
    if (_isRecording) return true;
    final ok = await ensureRecorder();
    if (!ok) return false;

    final tmpDir = await getTemporaryDirectory();
    _currentPath =
        '${tmpDir.path}/tutor_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder!.startRecorder(
      toFile: _currentPath,
      codec: Codec.aacMP4,
      bitRate: 96000,
      sampleRate: 44100,
    );
    _isRecording = true;
    return true;
  }

  /// Stop recording and return the local file path (or null on failure).
  Future<String?> stopRecording() async {
    if (!_isRecording || _recorder == null) return null;
    try {
      await _recorder!.stopRecorder();
      _isRecording = false;
      return _currentPath;
    } catch (e) {
      debugPrint('[tutorVoice] stopRecorder failed: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Upload the recorded audio to the tutor's transcribe endpoint and
  /// return the transcribed text. Returns null on failure.
  Future<String?> transcribe(String sessionId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      // MultipartFile.fromPath does NOT infer content type — the comment
      // here was wrong and the file was being sent as octet-stream, which
      // the backend multer filter rejects. Sniff explicitly.
      final mime = lookupMimeType(filePath) ?? 'audio/aac';
      final multipart = await http.MultipartFile.fromPath(
        'audio',
        filePath,
        contentType: MediaType.parse(mime),
      );
      final res = await ApiClient().postMultipart(
        'tutor/sessions/$sessionId/transcribe',
        fields: const {},
        files: [multipart],
      );
      if (!res.success || res.data == null) return null;
      final data = res.data is Map ? res.data as Map : const {};
      final inner = data['data'] is Map ? data['data'] as Map : data;
      return inner['text']?.toString();
    } catch (e) {
      debugPrint('[tutorVoice] transcribe failed: $e');
      return null;
    }
  }

  /// Monotonic token bumped on every speakAndPlay / stopPlayback so an
  /// in-flight TTS HTTP request can be cancelled mid-await — without it,
  /// the user toggles voice OFF, _player.stop() is a no-op (nothing is
  /// playing yet), then the TTS response arrives and playUrl starts
  /// audio anyway. Each speakAndPlay captures its token; if the field
  /// has moved by the time the request resolves, the playback is
  /// skipped.
  int _playGen = 0;

  /// Ask the backend to TTS the most-recent (or specified) assistant
  /// message and play it. Returns the audioUrl on success.
  Future<String?> speakAndPlay(String sessionId, {int? messageIndex}) async {
    final gen = ++_playGen;
    try {
      final res = await ApiClient().post(
        'tutor/sessions/$sessionId/speak',
        body: messageIndex != null ? {'messageIndex': messageIndex} : null,
      );
      if (gen != _playGen) return null; // cancelled by stopPlayback / newer call
      if (!res.success || res.data == null) return null;
      final raw = res.data;
      final data = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};
      final url = data['audioUrl']?.toString();
      if (url == null || url.isEmpty) return null;
      if (gen != _playGen) return null;
      await playUrl(url, gen: gen);
      return url;
    } catch (e) {
      debugPrint('[tutorVoice] speakAndPlay failed: $e');
      return null;
    }
  }

  Future<void> playUrl(String url, {int? gen}) async {
    try {
      _isPlaying = true;
      await _player.setUrl(url);
      if (gen != null && gen != _playGen) {
        _isPlaying = false;
        return; // cancelled between setUrl and play
      }
      await _player.play();
      _player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed)
          .then((_) => _isPlaying = false);
    } catch (e) {
      _isPlaying = false;
      debugPrint('[tutorVoice] playUrl failed: $e');
    }
  }

  Future<void> stopPlayback() async {
    _playGen++; // invalidate any in-flight speakAndPlay
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  Future<void> dispose() async {
    try {
      if (_recorder != null) {
        if (_isRecording) await _recorder!.stopRecorder();
        await _recorder!.closeRecorder();
      }
    } catch (_) {}
    _recorder = null;
    _recorderReady = false;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}

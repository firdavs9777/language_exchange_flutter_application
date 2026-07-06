import 'dart:async';
import 'dart:io';

import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
// flutter_sound re-exports neither Level nor Logger, so pull Level in directly
// (it ships as a transitive dependency of flutter_sound).
import 'package:logger/logger.dart' show Level;
import 'package:path_provider/path_provider.dart';

/// Stateful audio-record widget for the Speaking practice screen.
///
/// Three states:
///  1. idle      — big circular Record button. No file yet.
///  2. recording — pulsing red dot + mm:ss timer + Stop button.
///  3. recorded  — Play / Re-record / Submit row.
///
/// The widget OWNS the [FlutterSoundRecorder] lifecycle (init in
/// initState, close in dispose) so callers never see it leak.
///
/// Callbacks bubble up the recorded file. Parents are expected to
/// upload it on Submit.
class AudioRecorder extends StatefulWidget {
  const AudioRecorder({
    super.key,
    required this.onRecorded,
    this.maxDuration = const Duration(minutes: 3),
  });

  /// Fired when the user taps Submit after stopping a recording.
  final ValueChanged<File> onRecorded;

  /// Hard ceiling — the recorder auto-stops if reached.
  final Duration maxDuration;

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

enum _RecorderState { idle, recording, recorded }

class _AudioRecorderState extends State<AudioRecorder> {
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(logLevel: Level.error);
  final FlutterSoundPlayer _player =
      FlutterSoundPlayer(logLevel: Level.error);

  _RecorderState _state = _RecorderState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  File? _recordedFile;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    if (!mounted) return;
    final filename =
        'exam_speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${dir.path}/$filename';
    await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
    if (!mounted) return;
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= widget.maxDuration) {
        _stopRecording();
      }
    });
    setState(() {
      _state = _RecorderState.recording;
      _recordedFile = null;
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stopRecorder();
    if (path == null || !mounted) return;
    setState(() {
      _state = _RecorderState.recorded;
      _recordedFile = File(path);
    });
  }

  Future<void> _playRecording() async {
    final file = _recordedFile;
    if (file == null) return;
    if (_player.isPlaying) {
      await _player.stopPlayer();
      if (mounted) setState(() {});
      return;
    }
    await _player.startPlayer(
      fromURI: file.path,
      whenFinished: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    if (_player.isPlaying) await _player.stopPlayer();
    if (!mounted) return;
    setState(() {
      _state = _RecorderState.idle;
      _recordedFile = null;
      _elapsed = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    switch (_state) {
      case _RecorderState.idle:
        return _buildIdle(context);
      case _RecorderState.recording:
        return _buildRecording(context);
      case _RecorderState.recorded:
        return _buildRecorded(context);
    }
  }

  Widget _buildIdle(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to start recording',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecording(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRecorded(BuildContext context) {
    final isPlaying = _player.isPlaying;
    return Column(
      children: [
        Text(
          _formatDuration(_elapsed),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _playRecording,
              icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
              label: Text(isPlaying ? 'Stop' : 'Play'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-record'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final file = _recordedFile;
              if (file != null) widget.onRecorded(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Submit recording',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

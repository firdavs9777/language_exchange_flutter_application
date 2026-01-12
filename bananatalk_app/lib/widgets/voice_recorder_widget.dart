import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File voiceFile, int durationSeconds, List<double> waveform)?
      onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    Key? key,
    this.onRecordingComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderSubscription;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  String? _recordingPath;
  Duration _duration = Duration.zero;
  List<double> _amplitudes = [];
  String? _error;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() {
        _error = 'Microphone permission is required';
      });
      Future.delayed(const Duration(seconds: 2), () {
        widget.onCancel?.call();
      });
      return;
    }

    try {
      await _recorder!.openRecorder();

      // Configure audio session
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
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Set subscription duration for progress updates
      await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));

      setState(() => _isInitialized = true);

      // Auto-start recording
      await _startRecording();
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      setState(() {
        _error = 'Failed to initialize recorder';
      });
      Future.delayed(const Duration(seconds: 2), () {
        widget.onCancel?.call();
      });
    }
  }

  Future<void> _startRecording() async {
    if (_recorder == null || !_isInitialized) return;

    try {
      _recordingPath = await VoiceMessageService.generateRecordingPath();

      // Subscribe to recorder progress
      _recorderSubscription = _recorder!.onProgress!.listen((event) {
        if (mounted) {
          setState(() {
            _duration = event.duration;

            // Get decibel level for waveform
            final db = event.decibels ?? -60;
            // Normalize decibels to 0-1 range (assuming -60 to 0 dB range)
            final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
            _amplitudes.add(normalized);

            // Keep only last 100 samples to prevent memory issues
            if (_amplitudes.length > 100) {
              _amplitudes.removeAt(0);
            }
          });

          // Auto-stop at 5 minutes
          if (_duration.inMinutes >= 5) {
            _stopAndSend();
          }
        }
      });

      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 44100,
      );

      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() {
        _error = 'Failed to start recording';
      });
    }
  }

  Future<void> _pauseRecording() async {
    if (_recorder == null || !_isRecording || _isPaused) return;

    try {
      await _recorder!.pauseRecorder();
      setState(() => _isPaused = true);
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    if (_recorder == null || !_isRecording || !_isPaused) return;

    try {
      await _recorder!.resumeRecorder();
      setState(() => _isPaused = false);
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  Future<void> _stopAndSend() async {
    if (_recorder == null || !_isRecording) return;

    try {
      _recorderSubscription?.cancel();
      final path = await _recorder!.stopRecorder();

      setState(() => _isRecording = false);

      if (path != null && _duration.inSeconds >= 1) {
        final file = File(path);
        if (await file.exists()) {
          // Generate waveform from amplitudes
          final waveform = VoiceMessageService.generateWaveformFromSamples(
            _amplitudes,
            50, // Target 50 bars for waveform display
          );

          widget.onRecordingComplete?.call(
            file,
            _duration.inSeconds,
            waveform,
          );
        } else {
          _showError('Recording file not found');
          widget.onCancel?.call();
        }
      } else {
        _showError('Recording too short (minimum 1 second)');
        widget.onCancel?.call();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      widget.onCancel?.call();
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recorderSubscription?.cancel();

      if (_recorder != null && _isRecording) {
        await _recorder!.stopRecorder();
      }

      // Delete the temp file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }

    widget.onCancel?.call();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _pulseController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),

            // Waveform visualization
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: _buildWaveformVisualization(),
            ),

            // Duration and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                IconButton(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Cancel',
                ),

                // Duration display with recording indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRecording && !_isPaused)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(
                                0.5 + _pulseController.value * 0.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      )
                    else if (_isPaused)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      VoiceMessageService.formatDuration(_duration.inSeconds),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),

                // Pause/Resume and Send buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_duration.inSeconds > 0) ...[
                      IconButton(
                        onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          size: 28,
                        ),
                        tooltip: _isPaused ? 'Resume' : 'Pause',
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _stopAndSend,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Instructions
            const SizedBox(height: 8),
            Text(
              _isPaused
                  ? 'Recording paused - tap play to continue'
                  : _isRecording
                      ? 'Recording... tap pause or send when done'
                      : 'Initializing...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformVisualization() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const barWidth = 3.0;
        const spacing = 2.0;
        final maxBars = ((constraints.maxWidth) / (barWidth + spacing)).floor();

        // Get the last maxBars amplitudes
        final displayAmplitudes = _amplitudes.length > maxBars
            ? _amplitudes.sublist(_amplitudes.length - maxBars)
            : _amplitudes;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padding bars on the left if not enough data
            ...List.generate(
              (maxBars - displayAmplitudes.length).clamp(0, maxBars),
              (index) => Container(
                width: barWidth,
                height: 4,
                margin: const EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(
                  color: Colors.red.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Actual amplitude bars
            ...displayAmplitudes.asMap().entries.map((entry) {
              final amplitude = entry.value;
              return Container(
                width: barWidth,
                height: 4 + (amplitude * 40), // Min 4, max 44
                margin: const EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(
                  color: _isPaused ? Colors.red.shade300 : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// Compact voice record button for chat input
class VoiceRecordButton extends StatefulWidget {
  final Function(File voiceFile, int durationSeconds, List<double> waveform)?
      onRecordingComplete;
  final bool enabled;

  const VoiceRecordButton({
    Key? key,
    this.onRecordingComplete,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  bool _isRecording = false;

  void _showRecordingSheet() {
    setState(() => _isRecording = true);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderWidget(
        onRecordingComplete: (file, duration, waveform) {
          Navigator.pop(context);
          setState(() => _isRecording = false);
          widget.onRecordingComplete?.call(file, duration, waveform);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _isRecording = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.enabled && !_isRecording ? _showRecordingSheet : null,
      icon: Icon(
        _isRecording ? Icons.mic : Icons.mic_none,
        color: _isRecording
            ? Colors.red
            : (widget.enabled ? Colors.grey[600] : Colors.grey[400]),
      ),
      tooltip: 'Voice message',
    );
  }
}

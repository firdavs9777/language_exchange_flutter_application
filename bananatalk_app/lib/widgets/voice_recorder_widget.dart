import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
  VoiceRecordingState _recordingState = const VoiceRecordingState();
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _startRecording();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final filePath = await VoiceMessageService.generateRecordingPath();
      
      setState(() {
        _recordingState = _recordingState.copyWith(
          isRecording: true,
          filePath: filePath,
          duration: Duration.zero,
          amplitudes: [],
        );
      });

      // Note: In production, use the 'record' package to actually record
      // For now, we simulate the recording
      
      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_recordingState.isRecording || _recordingState.isPaused) return;
        
        setState(() {
          _recordingState = _recordingState.copyWith(
            duration: _recordingState.duration + const Duration(seconds: 1),
          );
        });

        // Auto-stop at 5 minutes
        if (_recordingState.duration.inMinutes >= 5) {
          _stopRecording();
        }
      });

      // Simulate amplitude updates for waveform
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_recordingState.isRecording || _recordingState.isPaused) return;
        
        // Generate random amplitude for visualization
        // In production, get actual amplitude from recorder
        final amplitude = 0.2 + (DateTime.now().millisecondsSinceEpoch % 80) / 100;
        
        setState(() {
          _recordingState = _recordingState.copyWith(
            amplitudes: [..._recordingState.amplitudes, amplitude.clamp(0.0, 1.0)],
          );
        });
      });
    } catch (e) {
      setState(() {
        _recordingState = _recordingState.copyWith(
          error: 'Failed to start recording: $e',
        );
      });
    }
  }

  void _pauseRecording() {
    setState(() {
      _recordingState = _recordingState.copyWith(isPaused: true);
    });
  }

  void _resumeRecording() {
    setState(() {
      _recordingState = _recordingState.copyWith(isPaused: false);
    });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    if (_recordingState.filePath != null && 
        _recordingState.duration.inSeconds > 0) {
      // In production, stop the actual recorder and get the file
      // For now, create a placeholder file
      try {
        final file = File(_recordingState.filePath!);
        
        // Generate waveform from amplitudes
        final waveform = VoiceMessageService.generateWaveformFromSamples(
          _recordingState.amplitudes,
          50, // Target 50 bars for waveform
        );

        widget.onRecordingComplete?.call(
          file,
          _recordingState.duration.inSeconds,
          waveform,
        );
      } catch (e) {
        setState(() {
          _recordingState = _recordingState.copyWith(
            error: 'Failed to save recording: $e',
          );
        });
      }
    }

    setState(() {
      _recordingState = _recordingState.copyWith(isRecording: false);
    });
  }

  void _cancelRecording() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    
    // Delete the file if it exists
    if (_recordingState.filePath != null) {
      try {
        final file = File(_recordingState.filePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Error deleting recording: $e');
      }
    }

    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message
          if (_recordingState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _recordingState.error!,
                style: TextStyle(color: Colors.red.shade700),
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

              // Duration display
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(
                            0.5 + _pulseController.value * 0.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    VoiceMessageService.formatDuration(
                      _recordingState.duration.inSeconds,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),

              // Pause/Resume and Send buttons
              Row(
                children: [
                  if (_recordingState.duration.inSeconds > 0) ...[
                    IconButton(
                      onPressed: _recordingState.isPaused
                          ? _resumeRecording
                          : _pauseRecording,
                      icon: Icon(
                        _recordingState.isPaused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      tooltip: _recordingState.isPaused ? 'Resume' : 'Pause',
                    ),
                    IconButton(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).primaryColor,
                      tooltip: 'Send',
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Instructions
          Text(
            _recordingState.isPaused
                ? 'Recording paused'
                : 'Recording... Slide left to cancel',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualization() {
    final amplitudes = _recordingState.amplitudes;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 3.0;
        final spacing = 2.0;
        final maxBars = ((constraints.maxWidth) / (barWidth + spacing)).floor();
        
        // Get the last maxBars amplitudes
        final displayAmplitudes = amplitudes.length > maxBars
            ? amplitudes.sublist(amplitudes.length - maxBars)
            : amplitudes;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padding bars on the left if not enough data
            ...List.generate(
              (maxBars - displayAmplitudes.length).clamp(0, maxBars),
              (index) => Container(
                width: barWidth,
                height: 4,
                margin: EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(
                  color: Colors.red.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Actual amplitude bars
            ...displayAmplitudes.map((amplitude) {
              return Container(
                width: barWidth,
                height: 4 + (amplitude * 40), // Min 4, max 44
                margin: EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(
                  color: _recordingState.isPaused
                      ? Colors.red.shade300
                      : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
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
            : (widget.enabled ? null : Colors.grey),
      ),
      tooltip: 'Voice message',
    );
  }
}


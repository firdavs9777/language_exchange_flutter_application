import 'dart:io';
import 'package:flutter/material.dart';

/// Stub implementation of VoiceRecorderWidget for platforms that don't support recording
class VoiceRecorderWidget extends StatelessWidget {
  final Function(File voiceFile, int durationSeconds, List<double> waveform)?
      onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    Key? key,
    this.onRecordingComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show message and auto-cancel after delay
    Future.delayed(const Duration(seconds: 2), () {
      onCancel?.call();
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.mic_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Voice Recording Not Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voice recording is only available on mobile devices.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stub implementation of VoiceRecordButton for desktop
class VoiceRecordButton extends StatelessWidget {
  final Function(File voiceFile, int durationSeconds, List<double> waveform)?
      onRecordingComplete;
  final bool enabled;

  const VoiceRecordButton({
    Key? key,
    this.onRecordingComplete,
    this.enabled = true,
  }) : super(key: key);

  void _showNotSupportedMessage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderWidget(
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? () => _showNotSupportedMessage(context) : null,
      icon: Icon(
        Icons.mic_none,
        color: enabled ? Colors.grey[400] : Colors.grey[300],
      ),
      tooltip: 'Voice recording not available on desktop',
    );
  }
}

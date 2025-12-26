import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final List<double>? waveform;
  final bool isFromMe;
  final String? messageId;
  final String? senderId;
  final VoidCallback? onPlayed;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    required this.durationSeconds,
    this.waveform,
    this.isFromMe = false,
    this.messageId,
    this.senderId,
    this.onPlayed,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  VoicePlaybackState _playbackState = const VoicePlaybackState();
  bool _hasNotifiedPlayed = false;

  @override
  void initState() {
    super.initState();
    _playbackState = VoicePlaybackState(
      duration: Duration(seconds: widget.durationSeconds),
    );
  }

  @override
  void dispose() {
    // Clean up audio player if using one
    super.dispose();
  }

  void _togglePlayback() async {
    if (_playbackState.isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() async {
    // Note: This is a simplified implementation
    // In production, you would use just_audio or audioplayers package
    
    setState(() {
      _playbackState = _playbackState.copyWith(
        isPlaying: true,
        isLoading: false,
      );
    });

    // Notify that voice message was played
    if (!_hasNotifiedPlayed && widget.messageId != null && widget.senderId != null) {
      _hasNotifiedPlayed = true;
      widget.onPlayed?.call();
    }

    // Simulate playback progress (replace with actual audio player)
    _simulatePlayback();
  }

  void _pausePlayback() {
    setState(() {
      _playbackState = _playbackState.copyWith(isPlaying: false);
    });
  }

  void _simulatePlayback() async {
    // This is a placeholder - in production use an actual audio player
    final totalDuration = Duration(seconds: widget.durationSeconds);
    final stepDuration = const Duration(milliseconds: 100);
    
    while (_playbackState.isPlaying && 
           _playbackState.position < totalDuration) {
      await Future.delayed(stepDuration);
      if (!mounted || !_playbackState.isPlaying) break;
      
      setState(() {
        _playbackState = _playbackState.copyWith(
          position: _playbackState.position + stepDuration,
        );
      });
    }

    if (mounted && _playbackState.position >= totalDuration) {
      setState(() {
        _playbackState = _playbackState.copyWith(
          isPlaying: false,
          position: Duration.zero,
        );
      });
    }
  }

  void _seekTo(double value) {
    final newPosition = Duration(
      milliseconds: (value * widget.durationSeconds * 1000).toInt(),
    );
    setState(() {
      _playbackState = _playbackState.copyWith(position: newPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isFromMe 
        ? Colors.white.withOpacity(0.9)
        : Theme.of(context).primaryColor;
    final secondaryColor = widget.isFromMe
        ? Colors.white.withOpacity(0.5)
        : Theme.of(context).primaryColor.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isFromMe 
                    ? Theme.of(context).primaryColor 
                    : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Waveform or progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform visualization
                SizedBox(
                  height: 32,
                  child: widget.waveform != null && widget.waveform!.isNotEmpty
                      ? _buildWaveform(primaryColor, secondaryColor)
                      : _buildProgressBar(primaryColor, secondaryColor),
                ),
                const SizedBox(height: 4),
                // Duration
                Text(
                  _playbackState.isPlaying
                      ? VoiceMessageService.formatDuration(
                          _playbackState.position.inSeconds)
                      : VoiceMessageService.formatDuration(widget.durationSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isFromMe 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Speed indicator (optional)
          const SizedBox(width: 4),
          Icon(
            Icons.mic,
            size: 16,
            color: secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Color primaryColor, Color secondaryColor) {
    final waveform = widget.waveform!;
    final progress = _playbackState.progress;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 3.0;
        final spacing = 2.0;
        final totalBars = ((constraints.maxWidth) / (barWidth + spacing)).floor();
        final displayWaveform = VoiceMessageService.generateWaveformFromSamples(
          waveform, 
          totalBars,
        );

        return GestureDetector(
          onTapDown: (details) {
            final tapProgress = details.localPosition.dx / constraints.maxWidth;
            _seekTo(tapProgress.clamp(0.0, 1.0));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(displayWaveform.length, (index) {
              final amplitude = displayWaveform[index];
              final isPlayed = index / displayWaveform.length <= progress;
              
              return Container(
                width: barWidth,
                height: 4 + (amplitude * 28), // Min 4, max 32
                decoration: BoxDecoration(
                  color: isPlayed ? primaryColor : secondaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTapDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final tapProgress = details.localPosition.dx / renderBox.size.width;
        _seekTo(tapProgress.clamp(0.0, 1.0));
      },
      child: Container(
        height: 32,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background track
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Progress track
            FractionallySizedBox(
              widthFactor: _playbackState.progress.clamp(0.0, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: null,
              child: FractionallySizedBox(
                widthFactor: _playbackState.progress.clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


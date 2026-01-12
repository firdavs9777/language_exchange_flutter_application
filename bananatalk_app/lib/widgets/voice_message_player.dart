import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasNotifiedPlayed = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = Duration(seconds: widget.durationSeconds);
    _setupPlayer();
  }

  void _setupPlayer() {
    _positionSubscription = _player.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _duration = duration);
      }
    });

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        // Reset position when completed
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_player.audioSource == null) {
        setState(() => _isLoading = true);
        await _player.setUrl(widget.audioUrl);
      }

      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
        if (!_hasNotifiedPlayed) {
          _hasNotifiedPlayed = true;
          widget.onPlayed?.call();
        }
      }
    } catch (e) {
      debugPrint('Error playing voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play voice message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _seekTo(double progress) {
    if (_duration.inMilliseconds > 0) {
      final position = Duration(
        milliseconds: (progress * _duration.inMilliseconds).round(),
      );
      _player.seek(position);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  double get _progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isFromMe
        ? Colors.white.withOpacity(0.9)
        : Theme.of(context).primaryColor;
    final secondaryColor = widget.isFromMe
        ? Colors.white.withOpacity(0.4)
        : Theme.of(context).primaryColor.withOpacity(0.25);
    final textColor = widget.isFromMe
        ? Colors.white.withOpacity(0.7)
        : Colors.grey[600];

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          widget.isFromMe
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isFromMe
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      size: 22,
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
                  height: 28,
                  child: widget.waveform != null && widget.waveform!.isNotEmpty
                      ? _buildWaveform(primaryColor, secondaryColor)
                      : _buildProgressBar(primaryColor, secondaryColor),
                ),
                const SizedBox(height: 2),
                // Duration
                Text(
                  _isPlaying || _position.inSeconds > 0
                      ? '${VoiceMessageService.formatDuration(_position.inSeconds)} / ${VoiceMessageService.formatDuration(_duration.inSeconds)}'
                      : VoiceMessageService.formatDuration(_duration.inSeconds),
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Color primaryColor, Color secondaryColor) {
    final waveform = widget.waveform!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 2.5;
        final spacing = 1.5;
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
          onHorizontalDragUpdate: (details) {
            final tapProgress = details.localPosition.dx / constraints.maxWidth;
            _seekTo(tapProgress.clamp(0.0, 1.0));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(displayWaveform.length, (index) {
              final amplitude = displayWaveform[index];
              final isPlayed = index / displayWaveform.length <= _progress;

              return Container(
                width: barWidth,
                height: 4 + (amplitude * 20), // Min 4, max 24
                decoration: BoxDecoration(
                  color: isPlayed ? primaryColor : secondaryColor,
                  borderRadius: BorderRadius.circular(1.5),
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
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final tapProgress = details.localPosition.dx / box.size.width;
          _seekTo(tapProgress.clamp(0.0, 1.0));
        }
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final tapProgress = details.localPosition.dx / box.size.width;
          _seekTo(tapProgress.clamp(0.0, 1.0));
        }
      },
      child: Container(
        height: 28,
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
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

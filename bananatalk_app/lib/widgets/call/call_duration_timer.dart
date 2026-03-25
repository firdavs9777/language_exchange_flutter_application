import 'dart:async';
import 'package:flutter/material.dart';

class CallDurationTimer extends StatefulWidget {
  final DateTime startTime;
  final TextStyle? style;

  const CallDurationTimer({
    super.key,
    required this.startTime,
    this.style,
  });

  @override
  State<CallDurationTimer> createState() => _CallDurationTimerState();
}

class _CallDurationTimerState extends State<CallDurationTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    setState(() {
      _duration = DateTime.now().difference(widget.startTime);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_duration),
      style: widget.style ??
          const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}

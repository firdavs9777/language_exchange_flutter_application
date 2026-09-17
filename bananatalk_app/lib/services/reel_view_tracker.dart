import 'package:flutter/foundation.dart';

/// Accumulates what was actually watched, and posts it in batches.
///
/// Telemetry, deliberately: a dropped batch costs a data point and must never
/// cost a frame. Every failure path here swallows rather than rethrows.
///
/// Exists because nothing recorded that a reel was seen. The server counted
/// likes, comments, saves and shares but never a view, so every engagement
/// RATE — completion, likes-per-view — had no denominator.
class ReelViewTracker {
  ReelViewTracker({required this.send, this.flushEvery = 10});

  /// Injected so tests never reach the network.
  final Future<void> Function(List<Map<String, dynamic>> batch) send;

  /// Flush after this many queued events, on top of pause and background.
  final int flushEvery;

  final List<Map<String, dynamic>> _queue = [];
  String? _current;

  /// A view is one second, not an impression.
  ///
  /// Counting on render would include every reel scrolled past before the
  /// video decoded. Those are not views, and including them deflates every
  /// rate uniformly until good and bad content converge.
  static const int _minViewMs = 1000;

  /// Long reels complete at 15s rather than 90%, so a two-minute reel is not
  /// called incomplete by someone who watched a long time.
  static const int _longReelCompleteMs = 15000;

  void onReelStarted(String momentId) => _current = momentId;

  void onReelEnded({required Duration watched, required Duration total}) {
    final id = _current;
    _current = null;
    if (id == null) return;

    final watchedMs = watched.inMilliseconds;
    if (watchedMs < _minViewMs) return;

    final totalMs = total.inMilliseconds;
    final completed = totalMs > 0
        ? (watchedMs >= totalMs * 0.9 || watchedMs >= _longReelCompleteMs)
        : false;

    _queue.add({
      'momentId': id,
      'watchedMs': watchedMs,
      'completed': completed,
    });

    if (_queue.length >= flushEvery) flush();
  }

  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_queue);
    // Cleared BEFORE the await: a flush triggered while one is in flight must
    // not send the same events twice.
    _queue.clear();
    try {
      await send(batch);
    } catch (e) {
      // Swallowed on purpose. Re-queueing would grow without bound offline,
      // and losing telemetry is cheaper than losing the scroll.
      debugPrint(
        '[reelViews] flush failed, ${batch.length} event(s) dropped: $e',
      );
    }
  }
}

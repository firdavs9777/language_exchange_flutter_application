import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

/// Tells the server which feed posts a person actually opened.
///
/// The ranking has likes, comments and saves already; "opened" is the signal
/// for posts someone cared about without reacting to. Same policy as
/// ReelViewTracker: telemetry, so a failed batch is dropped, never retried,
/// and nothing here may delay or throw into the caller.
class FeedOpenTracker {
  FeedOpenTracker({required this.send, this.flushEvery = 10});

  /// Injected so tests never reach the network.
  final Future<void> Function(List<Map<String, dynamic>> batch) send;

  /// Flush after this many queued ids, on top of app pause and the idle timer.
  final int flushEvery;

  /// Quiet period after the last [opened] before the batch is sent.
  static const Duration idleFlush = Duration(seconds: 5);

  final List<Map<String, dynamic>> _queue = [];

  /// Every id seen this session, including ones whose batch failed: a dropped
  /// batch is not re-sent, and one post is one signal.
  final Set<String> _seen = {};
  Timer? _timer;

  /// Records that [momentId] was opened. Synchronous and non-throwing.
  void opened(String momentId) {
    if (momentId.isEmpty || !_seen.add(momentId)) return;
    _queue.add({'momentId': momentId, 'opened': true});
    if (_queue.length >= flushEvery) {
      flush();
      return;
    }
    _timer?.cancel();
    _timer = Timer(idleFlush, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_queue);
    // Cleared BEFORE the await so a concurrent flush cannot send it twice.
    _queue.clear();
    try {
      await send(batch);
    } catch (e) {
      debugPrint(
        '[feedOpen] flush failed, ${batch.length} item(s) dropped: $e',
      );
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Flushes on app pause: leaving the app usually ends a session, and the
/// idle timer alone would lose that batch.
class _PauseFlush with WidgetsBindingObserver {
  _PauseFlush(this._tracker);
  final FeedOpenTracker _tracker;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _tracker.flush();
  }
}

/// One app-wide instance. Call `ref.read(feedOpenTrackerProvider).opened(id)`.
final feedOpenTrackerProvider = Provider<FeedOpenTracker>((ref) {
  final service = ref.read(momentsServiceProvider);
  final tracker = FeedOpenTracker(send: service.recordReelViews);
  final observer = _PauseFlush(tracker);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    tracker.dispose();
  });
  return tracker;
});

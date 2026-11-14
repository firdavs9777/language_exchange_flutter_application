import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/app_provider_container.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/study/study_events_api.dart';

/// The event names the server accepts.
class StudyEvent {
  static const tabOpened = 'tab_opened';
  static const sessionStarted = 'session_started';
  static const stepStarted = 'step_started';
  static const stepFinished = 'step_finished';
  static const sessionFinished = 'session_finished';
  static const featureOpened = 'feature_opened';
  static const levelCheckStarted = 'level_check_started';
  static const levelCheckFinished = 'level_check_finished';
}

/// Sends a batch; true when accepted. A false result or a throw drops it.
typedef StudySend = Future<bool> Function(List<Map<String, dynamic>> events);

/// In-memory, batched AI Study events. Same behaviour as the paywall tracker
/// (mirrored, not shared: the queue is ~60 lines and the paywall tracker's
/// tests pin its exact behaviour). Telemetry: nothing is retried, nothing is
/// written to disk, and nothing here may throw into the caller.
class StudyTracker {
  StudyTracker({
    required this.send,
    required this.enabled,
    DateTime Function()? now,
    this.flushAfter = const Duration(seconds: 10),
    this.maxQueue = 20,
  }) : _now = now ?? DateTime.now;

  final StudySend send;

  /// Read at every [log], so a config refresh applies without a rebuild.
  final bool Function() enabled;
  final DateTime Function() _now;
  final Duration flushAfter;
  final int maxQueue;

  static const int _maxBatch = 50;
  static const int _maxDetail = 40;
  static const int _maxKind = 24;
  static const int _maxScore = 1000;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;

  /// Set by [dispose] (sign-out): nothing more is queued or sent.
  bool _disposed = false;

  void _drop() {
    _queue.clear();
    _timer?.cancel();
    _timer = null;
  }

  static String? _clip(String? s, int max) =>
      s == null ? null : (s.length > max ? s.substring(0, max) : s);

  static int? _count(int? n) => n?.clamp(0, _maxScore).toInt();

  void log(
    String name, {
    String? language,
    String? kind,
    int? score,
    int? total,
    String? detail,
  }) {
    if (_disposed) return;
    if (!enabled()) {
      _drop();
      return;
    }
    final k = _clip(kind, _maxKind);
    final d = _clip(detail, _maxDetail);
    final s = _count(score);
    final t = _count(total);
    // The server rejects a language outside 2..10 characters.
    final lang = (language != null && language.length >= 2 && language.length <= 10)
        ? language
        : null;
    _queue.add({
      'name': name,
      if (lang != null) 'language': lang,
      if (k != null) 'kind': k,
      if (s != null) 'score': s,
      if (t != null) 'total': t,
      if (d != null) 'detail': d,
      'clientAt': _now().toUtc().toIso8601String(),
    });
    if (_queue.length >= maxQueue) {
      flush();
      return;
    }
    _timer ??= Timer(flushAfter, flush);
  }

  Future<void> flush() async {
    // The flag may have turned off since these were queued (a config
    // refresh): the timer and the pause observer must not post them.
    if (_disposed || !enabled()) {
      _drop();
      return;
    }
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final all = List<Map<String, dynamic>>.from(_queue);
    // Cleared BEFORE any await so a concurrent flush cannot send it twice.
    _queue.clear();
    for (var i = 0; i < all.length; i += _maxBatch) {
      if (_disposed) return;
      final end = i + _maxBatch < all.length ? i + _maxBatch : all.length;
      final chunk = all.sublist(i, end);
      try {
        final ok = await send(chunk);
        if (!ok) debugPrint('[study] batch refused, ${chunk.length} dropped');
      } catch (e) {
        debugPrint('[study] flush failed, ${chunk.length} dropped: $e');
      }
    }
  }

  /// Drops what is queued (it belonged to the account signing out).
  void dispose() {
    _disposed = true;
    _drop();
  }
}

/// Flushes when the app leaves the foreground.
class _PauseFlush with WidgetsBindingObserver {
  _PauseFlush(this._tracker);
  final StudyTracker _tracker;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _tracker.flush();
  }
}

/// One app-wide instance (user-scoped: reset on sign-out).
final studyTrackerProvider = Provider<StudyTracker>((ref) {
  final api = StudyEventsApi();
  final tracker = StudyTracker(
    send: api.send,
    enabled: () => ref.read(studyEventsEnabledProvider),
  );
  final observer = _PauseFlush(tracker);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    tracker.dispose();
  });
  return tracker;
});

/// Test seam: sees every [studyLog] call, whatever the flag says.
@visibleForTesting
void Function(String name, Map<String, Object?> fields)? studyLogSpy;

/// Test seam: the container [studyLog] reads (defaults to the app's).
@visibleForTesting
ProviderContainer? studyLogContainer;

/// Fire-and-forget entry point for any surface. Never throws. While the
/// events flag is off nothing is built: no tracker, no client, no observer.
void studyLog(
  String name, {
  String? language,
  String? kind,
  int? score,
  int? total,
  String? detail,
}) {
  try {
    studyLogSpy?.call(name, {
      'language': language,
      'kind': kind,
      'score': score,
      'total': total,
      'detail': detail,
    });
    final container = studyLogContainer ?? appProviderContainer;
    if (!container.read(studyEventsEnabledProvider)) return;
    container.read(studyTrackerProvider).log(
          name,
          language: language,
          kind: kind,
          score: score,
          total: total,
          detail: detail,
        );
  } catch (e) {
    debugPrint('[study] log skipped: $e');
  }
}

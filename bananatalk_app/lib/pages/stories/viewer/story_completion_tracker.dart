import 'dart:async';

/// Tells the server a story was watched to its end, once per story per viewer
/// session. Telemetry: a failed send is dropped, never retried, and nothing
/// here may delay or throw into the caller.
class StoryCompletionTracker {
  StoryCompletionTracker({required this.send});

  /// Injected so tests never reach the network.
  final Future<void> Function(String storyId) send;

  /// Every id reported this session, including ones whose send failed: one
  /// story is one signal.
  final Set<String> _seen = {};

  void completed(String storyId) {
    if (storyId.isEmpty || !_seen.add(storyId)) return;
    try {
      unawaited(send(storyId).catchError((Object _) {}));
    } catch (_) {
      // A sender that throws before returning a future is still telemetry.
    }
  }
}

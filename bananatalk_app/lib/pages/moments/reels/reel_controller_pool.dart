import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Owns at most **3** live [VideoPlayerController]s for the Reels vertical
/// swipe feed (Workstream G, Task 5) — current, previous, next — so a long
/// swipe session never accumulates unbounded native video decoders (the
/// orphaned `VideoFeedItem` in `explore_main.dart` this screen was adapted
/// from eagerly initializes every controller, which would OOM here).
///
/// Usage: call [activate] for the current index, [preload] for the next
/// index, then [releaseOutside] to dispose anything outside the
/// `[current-1, current+1]` window. Call [pauseAll] on app background /
/// route change, and [disposeAll] from the feed screen's `dispose()`.
class ReelControllerPool {
  final Map<int, VideoPlayerController> _controllers = {};

  /// Indices currently being disposed — guards against double-dispose if
  /// `releaseOutside` and `disposeAll` race, or a fast swipe evicts an
  /// index twice before the first dispose completes.
  final Set<int> _disposing = {};

  VideoPlayerController? controllerAt(int index) => _controllers[index];

  /// Activates (creating + initializing if needed) the controller at
  /// [index] for [url], and starts looped playback.
  Future<VideoPlayerController> activate(int index, String url) async {
    var controller = _controllers[index];
    if (controller == null) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controllers[index] = controller;
      try {
        await controller.initialize();
      } catch (e) {
        debugPrint('ReelControllerPool: failed to init reel $index: $e');
        // Evict the failed controller so a later swipe-back retries instead
        // of finding a permanently-uninitialized cached instance (gate
        // review minor: otherwise this reel shows a spinner forever).
        if (_controllers[index] == controller) {
          _controllers.remove(index);
        }
        try {
          await controller.dispose();
        } catch (_) {}
        return controller;
      }
    }

    // The controller may have been evicted (releaseOutside) while the
    // `await controller.initialize()` above was in flight — don't touch a
    // controller that's no longer ours to touch.
    if (_controllers[index] != controller) return controller;

    try {
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      // Non-fatal — playback errors surface via the widget's own
      // ValueListenableBuilder on `controller`, if the caller wired one up.
    }
    return controller;
  }

  /// Preloads (creates + initializes, but does not play) the controller at
  /// [index] so it's ready the instant the user swipes to it.
  Future<void> preload(int index, String url) async {
    if (_controllers.containsKey(index)) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;
    try {
      await controller.initialize();
      if (_controllers[index] != controller) return; // evicted meanwhile
      await controller.setLooping(true);
    } catch (e) {
      debugPrint('ReelControllerPool: failed to preload reel $index: $e');
      // Same eviction-on-failure as activate(): let a later attempt retry.
      if (_controllers[index] == controller) {
        _controllers.remove(index);
      }
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  /// Pauses every live controller (app background / route change) without
  /// disposing them, so playback resumes instantly on return.
  void pauseAll() {
    for (final controller in _controllers.values) {
      try {
        if (controller.value.isInitialized) controller.pause();
      } catch (_) {}
    }
  }

  /// Disposes every controller outside the `[current-1, current, current+1]`
  /// window — the hard cap of 3 live controllers.
  void releaseOutside(int current) {
    final keep = {current - 1, current, current + 1};
    final toRemove =
        _controllers.keys.where((i) => !keep.contains(i)).toList();
    for (final index in toRemove) {
      _disposeController(index);
    }
  }

  void _disposeController(int index) {
    if (_disposing.contains(index)) return;
    final controller = _controllers.remove(index);
    if (controller == null) return;
    _disposing.add(index);
    try {
      controller.pause();
    } catch (_) {}
    controller.dispose().whenComplete(() => _disposing.remove(index));
  }

  /// Disposes all controllers — call from the feed screen's `dispose()`.
  void disposeAll() {
    final indices = _controllers.keys.toList();
    for (final index in indices) {
      _disposeController(index);
    }
  }
}

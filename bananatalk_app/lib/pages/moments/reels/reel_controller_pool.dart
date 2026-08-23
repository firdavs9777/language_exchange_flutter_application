import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';

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
  ReelControllerPool({ReelVideoCache? cache})
      : _cache = cache ?? ReelVideoCache.instance;

  final ReelVideoCache _cache;

  final Map<int, VideoPlayerController> _controllers = {};

  /// Indices currently being disposed — guards against double-dispose if
  /// `releaseOutside` and `disposeAll` race, or a fast swipe evicts an
  /// index twice before the first dispose completes.
  final Set<int> _disposing = {};

  /// Creation in flight per index, keyed before the first `await` inside
  /// [_createController] runs. `activate` and `preload` both funnel through
  /// [_getOrCreateController], so if one is already building the controller
  /// for an index, the other joins that same future instead of starting a
  /// second construction — otherwise two callers racing the same slot (e.g.
  /// a `preload` suspended on the cache probe while a swipe triggers
  /// `activate` for the same index) would each build a controller and the
  /// loser's write to `_controllers[index]` would silently orphan the
  /// winner's, leaking a live decoder (and, if it was already playing,
  /// ghost audio).
  final Map<int, Future<VideoPlayerController?>> _pendingCreations = {};

  /// Set by [disposeAll]. Checked after every `await` in
  /// [_createController] so a controller build that was suspended when the
  /// screen tore down bails out — and disposes anything it already
  /// constructed — instead of registering a decoder into a pool nobody will
  /// ever dispose again.
  bool _disposed = false;

  VideoPlayerController? controllerAt(int index) => _controllers[index];

  /// Returns the live controller for [index], joining an in-flight build for
  /// the same index if one exists, or starting exactly one otherwise.
  Future<VideoPlayerController?> _getOrCreateController(
    int index,
    String url,
  ) {
    final existing = _controllers[index];
    if (existing != null) return Future.value(existing);
    if (_disposed) return Future.value(null);

    final pending = _pendingCreations[index];
    if (pending != null) return pending;

    final future = _createController(index, url);
    _pendingCreations[index] = future;
    future.whenComplete(() => _pendingCreations.remove(index));
    return future;
  }

  /// Builds, registers and initializes the controller for [index]/[url].
  /// Never called directly — only through [_getOrCreateController], which
  /// guarantees at most one of these runs per index at a time.
  Future<VideoPlayerController?> _createController(
    int index,
    String url,
  ) async {
    // Play from disk when we already have the bytes: instant start, no
    // network. On a miss stream as before AND warm the cache, so the next
    // view of this reel is local. Cache failure is always soft.
    final cached = await _cache.cachedFileFor(url);
    if (_disposed) return null;

    final usingCache = cached != null;
    var controller = cached == null
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.file(cached);
    if (!usingCache) _cache.warm(url);
    _controllers[index] = controller;

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint(
        'ReelControllerPool: failed to init reel $index (cached=$usingCache): $e',
      );
      // Evict the failed controller so a later swipe-back retries instead
      // of finding a permanently-uninitialized cached instance (gate
      // review minor: otherwise this reel shows a spinner forever).
      if (_controllers[index] == controller) {
        _controllers.remove(index);
      }
      try {
        await controller.dispose();
      } catch (_) {}

      if (!usingCache || _disposed) return null;

      // The probe found a file, but it was gone, truncated, or otherwise
      // unplayable by the time we tried to use it. A cache problem must
      // never make a reel unplayable, so fall back to streaming exactly as
      // a cache miss would — the miss path already degrades this way, the
      // hit path should too.
      debugPrint(
        'ReelControllerPool: cached file for reel $index failed to init, '
        'falling back to network',
      );
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controllers[index] = controller;
      try {
        await controller.initialize();
      } catch (e2) {
        debugPrint(
          'ReelControllerPool: network fallback failed for reel $index: $e2',
        );
        if (_controllers[index] == controller) {
          _controllers.remove(index);
        }
        try {
          await controller.dispose();
        } catch (_) {}
        return null;
      }
    }

    // The controller may have been evicted (releaseOutside) or the pool
    // torn down (disposeAll) while an `await` above was in flight — don't
    // leave a decoder running that nothing will ever release.
    if (_disposed || _controllers[index] != controller) {
      if (_controllers[index] == controller) {
        _controllers.remove(index);
      }
      try {
        await controller.dispose();
      } catch (_) {}
      return null;
    }

    try {
      await controller.setLooping(true);
    } catch (_) {}
    return controller;
  }

  /// Activates (creating + initializing if needed) the controller at
  /// [index] for [url], and starts looped playback.
  Future<VideoPlayerController?> activate(int index, String url) async {
    final controller = await _getOrCreateController(index, url);
    if (controller == null) return null;

    // Same eviction/disposal race as inside `_createController` — the
    // await above may have crossed a `releaseOutside`/`disposeAll`.
    if (_disposed || _controllers[index] != controller) return controller;

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
    await _getOrCreateController(index, url);
  }

  /// Downloads [urls] into the cache **without** creating controllers.
  ///
  /// Prefetching bytes and creating decoders are separate concerns: a cached
  /// file costs disk, a controller costs a native decoder. Keeping them apart
  /// is what lets prefetch reach further ahead than the ±1 controller window
  /// without raising the live-controller ceiling.
  Future<void> prefetchAhead(List<String> urls) async {
    for (final url in urls) {
      if (url.isNotEmpty) _cache.prefetch(url);
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
  ///
  /// Also latches [_disposed], so any `activate`/`preload` build still in
  /// flight (suspended on a cache probe or `initialize()`) bails out on its
  /// next check instead of registering a fresh controller after the pool is
  /// meant to be dead. This pool is one-shot per feed screen instance, so
  /// the flag is never expected to be un-set.
  void disposeAll() {
    _disposed = true;
    final indices = _controllers.keys.toList();
    for (final index in indices) {
      _disposeController(index);
    }
  }
}

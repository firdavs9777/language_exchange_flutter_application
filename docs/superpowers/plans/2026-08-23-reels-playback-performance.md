# Reels Playback Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make reels start instantly — cache video bytes on disk, prefetch upcoming reels by connection type, and bring the grid to life with bounded autoplay.

**Architecture:** A new `ReelVideoCache` owns a dedicated `CacheManager` and de-duplicates in-flight downloads. A pure `reelPrefetchDepth()` maps connectivity to how far ahead to fetch. `ReelControllerPool` consults the cache and plays from a local `File` when one exists, falling back to streaming otherwise — byte prefetching and controller creation stay separate concerns, so peak live controllers is unchanged at 3. The grid gets its own bounded, settle-gated autoplay coordinator driven by pure viewport arithmetic.

**Tech Stack:** Flutter 3.38.7 / Dart 3.10.7, `video_player: ^2.8.2`, `flutter_cache_manager: ^3.3.1`, `connectivity_plus: ^7.0.0` — all already in `pubspec.yaml`. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-23-reels-performance-and-sharing-design.md`

## Global Constraints

- **No new dependencies.** `flutter_cache_manager` and `connectivity_plus` are already present; adding packages is out of scope.
- **Live controller window stays `±1`.** Peak live `VideoPlayerController`s must remain 3 in the viewer, regardless of prefetch depth. This cap exists to avoid exhausting native video decoders.
- **Prefetch depth:** `wifi`/`ethernet` → 3, `mobile` → 1, `none` → 0.
- **Cache failure is always soft.** A miss, failed download or full disk falls back to `VideoPlayerController.networkUrl`. The cache must never make a reel unplayable.
- **Dedicated cache store.** Reel videos must not share a store with images: `AppImageCacheManager.instance` is `DefaultCacheManager()` (`lib/utils/image_utils.dart:10`), so using the default would let videos evict images and vice versa.
- **Cache config:** store key `bananatalkReelVideoCache`, `stalePeriod: Duration(days: 7)`, `maxNrOfCacheObjects: 60`.
- **Grid autoplay:** at most 3 tiles, nearest viewport centre, muted and looping, only while scrolling is settled, tiles keyed by **reel id** not index.
- **Grid data policy:** on Wi-Fi a tile may fetch; on cellular a tile animates **only if already cached**, otherwise it stays a thumbnail.
- **connectivity_plus v7 API:** both `checkConnectivity()` and `onConnectivityChanged` deal in `List<ConnectivityResult>`, not a bare enum (see `lib/services/chat_socket_service.dart:151-164`).
- Dart, not TypeScript. Existing analysis options apply; `flutter analyze` on touched files must report no new issues.
- **Working directories.** `flutter analyze` / `flutter test` run from `bananatalk_app/` (the pubspec lives there — running them from the repo root fails with "No pubspec.yaml found"). `git` commands run from the repo root `BananaTalk/`, which is why every `git add` path is prefixed `bananatalk_app/`.

---

## File Structure

| File | Responsibility |
|---|---|
| Create `lib/pages/moments/reels/reel_prefetch_policy.dart` | Pure connectivity → depth mapping |
| Create `lib/pages/moments/reels/reel_video_cache.dart` | Dedicated video byte cache + in-flight de-duplication |
| Create `lib/pages/moments/reels/reel_grid_autoplay.dart` | Pure viewport arithmetic for which tiles play |
| Create `lib/pages/moments/reels/widgets/reel_grid_tile.dart` | One grid tile: thumbnail, optional muted playback, play badge |
| Modify `lib/pages/moments/reels/reel_controller_pool.dart` | Prefer cached files; keep the ±1 window |
| Modify `lib/pages/moments/reels/reels_feed_screen.dart` | Depth-driven prefetch, connectivity subscription |
| Modify `lib/pages/moments/reels/reels_grid_screen.dart` | Host the autoplay coordinator; release on navigation |
| Create `test/moments/reel_prefetch_policy_test.dart` | Task 1 tests |
| Create `test/moments/reel_video_cache_test.dart` | Task 2 tests |
| Create `test/moments/reel_grid_autoplay_test.dart` | Task 4 tests |
| Create `lib/utils/compact_count.dart` | The one Instagram-style compact count formatter |
| Create `test/utils/compact_count_test.dart` | Task 7 tests |
| Modify 7 files carrying a hand-rolled `_formatCount` | Task 8 replaces them all |

Tasks 1, 2 and 4 are pure/injectable and fully unit-tested. Tasks 3, 5 and 6 touch platform video and have no unit-test harness in this repo; they end in `flutter analyze` plus explicit manual simulator verification.

---

### Task 1: Prefetch policy

**Files:**
- Create: `lib/pages/moments/reels/reel_prefetch_policy.dart`
- Test: `test/moments/reel_prefetch_policy_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `int reelPrefetchDepth(List<ConnectivityResult> status)` — returns `3` for wifi/ethernet, `1` for mobile, `0` when offline or the list is empty. Also `const int kReelMaxPrefetchDepth = 3;`.

- [ ] **Step 1: Write the failing test**

```dart
// test/moments/reel_prefetch_policy_test.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_prefetch_policy.dart';

void main() {
  group('reelPrefetchDepth', () {
    test('wifi prefetches three ahead', () {
      expect(reelPrefetchDepth([ConnectivityResult.wifi]), 3);
    });

    test('ethernet is treated as unmetered', () {
      expect(reelPrefetchDepth([ConnectivityResult.ethernet]), 3);
    });

    test('mobile prefetches only one ahead', () {
      expect(reelPrefetchDepth([ConnectivityResult.mobile]), 1);
    });

    test('offline prefetches nothing', () {
      expect(reelPrefetchDepth([ConnectivityResult.none]), 0);
    });

    test('an empty list is treated as offline, not as unmetered', () {
      expect(reelPrefetchDepth([]), 0);
    });

    test('mixed wifi and mobile takes the unmetered path', () {
      expect(
        reelPrefetchDepth([ConnectivityResult.mobile, ConnectivityResult.wifi]),
        3,
      );
    });

    test('an unrecognised transport is treated as metered, not unmetered', () {
      // Safer to under-fetch on something we do not understand than to burn
      // a user's data allowance on it.
      expect(reelPrefetchDepth([ConnectivityResult.bluetooth]), 1);
    });

    test('never exceeds the documented maximum', () {
      expect(reelPrefetchDepth([ConnectivityResult.wifi]),
          lessThanOrEqualTo(kReelMaxPrefetchDepth));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/moments/reel_prefetch_policy_test.dart`
Expected: FAIL — `Error: Method not found: 'reelPrefetchDepth'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/moments/reels/reel_prefetch_policy.dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// Most reels we will ever fetch ahead of the one being watched.
const int kReelMaxPrefetchDepth = 3;

/// How many upcoming reels to download ahead of the current one.
///
/// Unmetered connections buy latency hiding cheaply; on mobile data the same
/// aggressiveness would spend a user's allowance on reels they may never
/// watch. An unrecognised transport is treated as metered — under-fetching is
/// the cheaper mistake.
///
/// connectivity_plus v7 reports a *list* of active transports, so a device on
/// both Wi-Fi and cellular resolves to the unmetered path.
int reelPrefetchDepth(List<ConnectivityResult> status) {
  if (status.isEmpty || status.every((r) => r == ConnectivityResult.none)) {
    return 0;
  }
  final unmetered = status.any((r) =>
      r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
  return unmetered ? kReelMaxPrefetchDepth : 1;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/moments/reel_prefetch_policy_test.dart`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/reel_prefetch_policy.dart \
        bananatalk_app/test/moments/reel_prefetch_policy_test.dart
git commit -m "feat(reels): connectivity-aware prefetch depth policy"
```

---

### Task 2: Video byte cache

**Files:**
- Create: `lib/pages/moments/reels/reel_video_cache.dart`
- Test: `test/moments/reel_video_cache_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: class `ReelVideoCache` with:
  - `ReelVideoCache({ReelVideoDownloader? downloader, ReelVideoCacheProbe? probe})`
  - `static final ReelVideoCache instance`
  - `Future<File?> cachedFileFor(String url)` — on-disk hit or `null`, never downloads
  - `Future<File?> prefetch(String url)` — downloads, de-duplicated per URL
  - `void warm(String url)` — fire-and-forget `prefetch`
  - typedefs `typedef ReelVideoDownloader = Future<File?> Function(String url);` and `typedef ReelVideoCacheProbe = Future<File?> Function(String url);`

The injected `downloader`/`probe` exist so the de-duplication logic is testable without a filesystem; production defaults wrap the `CacheManager`.

- [ ] **Step 1: Write the failing test**

```dart
// test/moments/reel_video_cache_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';

void main() {
  group('ReelVideoCache', () {
    test('concurrent prefetches of one url download only once', () async {
      var calls = 0;
      final gate = Completer<File?>();
      final cache = ReelVideoCache(
        downloader: (url) {
          calls++;
          return gate.future;
        },
        probe: (url) async => null,
      );

      final a = cache.prefetch('https://x/reel.mp4');
      final b = cache.prefetch('https://x/reel.mp4');
      gate.complete(File('/tmp/reel.mp4'));

      expect((await a)?.path, '/tmp/reel.mp4');
      expect((await b)?.path, '/tmp/reel.mp4');
      expect(calls, 1, reason: 'the second caller must join the first download');
    });

    test('different urls download independently', () async {
      final seen = <String>[];
      final cache = ReelVideoCache(
        downloader: (url) async {
          seen.add(url);
          return File('/tmp/${seen.length}.mp4');
        },
        probe: (url) async => null,
      );

      await Future.wait([
        cache.prefetch('https://x/a.mp4'),
        cache.prefetch('https://x/b.mp4'),
      ]);

      expect(seen, hasLength(2));
    });

    test('a completed download is no longer held as in-flight', () async {
      var calls = 0;
      final cache = ReelVideoCache(
        downloader: (url) async {
          calls++;
          return File('/tmp/reel.mp4');
        },
        probe: (url) async => null,
      );

      await cache.prefetch('https://x/reel.mp4');
      await cache.prefetch('https://x/reel.mp4');

      expect(calls, 2,
          reason: 'sequential calls re-ask the downloader, which is itself '
              'cache-backed in production; only concurrent calls coalesce');
    });

    test('a failed download does not poison later attempts', () async {
      var calls = 0;
      final cache = ReelVideoCache(
        downloader: (url) async {
          calls++;
          if (calls == 1) throw const SocketException('offline');
          return File('/tmp/reel.mp4');
        },
        probe: (url) async => null,
      );

      expect(await cache.prefetch('https://x/reel.mp4'), isNull);
      expect((await cache.prefetch('https://x/reel.mp4'))?.path,
          '/tmp/reel.mp4');
    });

    test('cachedFileFor never downloads', () async {
      var downloads = 0;
      final cache = ReelVideoCache(
        downloader: (url) async {
          downloads++;
          return File('/tmp/reel.mp4');
        },
        probe: (url) async => null,
      );

      expect(await cache.cachedFileFor('https://x/reel.mp4'), isNull);
      expect(downloads, 0);
    });

    test('cachedFileFor returns the probe hit', () async {
      final cache = ReelVideoCache(
        downloader: (url) async => null,
        probe: (url) async => File('/tmp/hit.mp4'),
      );

      expect((await cache.cachedFileFor('https://x/reel.mp4'))?.path,
          '/tmp/hit.mp4');
    });

    test('a probe failure degrades to a miss rather than throwing', () async {
      final cache = ReelVideoCache(
        downloader: (url) async => null,
        probe: (url) async => throw const FileSystemException('disk full'),
      );

      expect(await cache.cachedFileFor('https://x/reel.mp4'), isNull);
    });

    test('an empty url is a miss and never reaches the downloader', () async {
      var downloads = 0;
      final cache = ReelVideoCache(
        downloader: (url) async {
          downloads++;
          return File('/tmp/reel.mp4');
        },
        probe: (url) async => File('/tmp/should-not-be-asked.mp4'),
      );

      expect(await cache.cachedFileFor(''), isNull);
      expect(await cache.prefetch(''), isNull);
      expect(downloads, 0);
    });
  });
}
```

Add `import 'dart:async';` at the top of the test file for `Completer`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/moments/reel_video_cache_test.dart`
Expected: FAIL — `Error: Couldn't find constructor 'ReelVideoCache'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/moments/reels/reel_video_cache.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Downloads [url] and returns the local file, or null on failure.
typedef ReelVideoDownloader = Future<File?> Function(String url);

/// Returns the already-cached local file for [url], or null on a miss.
typedef ReelVideoCacheProbe = Future<File?> Function(String url);

/// On-disk cache for reel video bytes.
///
/// Reels are short and re-watched often, but every controller was previously
/// built with `networkUrl`, so swiping back re-downloaded the whole clip.
///
/// Uses a **dedicated** store rather than the default one: images go through
/// `AppImageCacheManager.instance`, which is `DefaultCacheManager()`
/// (`lib/utils/image_utils.dart:10`). Sharing that store would let a handful of
/// videos evict the entire image cache, and vice versa.
class ReelVideoCache {
  ReelVideoCache({
    ReelVideoDownloader? downloader,
    ReelVideoCacheProbe? probe,
  })  : _downloader = downloader ?? _defaultDownloader,
        _probe = probe ?? _defaultProbe;

  static const String storeKey = 'bananatalkReelVideoCache';

  static final CacheManager _manager = CacheManager(
    Config(
      storeKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 60,
    ),
  );

  static final ReelVideoCache instance = ReelVideoCache();

  final ReelVideoDownloader _downloader;
  final ReelVideoCacheProbe _probe;

  /// Downloads currently in flight, keyed by url, so concurrent callers for
  /// the same reel join one request instead of racing. Without this a fast
  /// swiper at depth 3 issues overlapping downloads for the same files.
  final Map<String, Future<File?>> _inFlight = {};

  static Future<File?> _defaultProbe(String url) async {
    final info = await _manager.getFileFromCache(url);
    return info?.file;
  }

  static Future<File?> _defaultDownloader(String url) =>
      _manager.getSingleFile(url);

  /// The cached file for [url], or null. Never downloads.
  Future<File?> cachedFileFor(String url) async {
    if (url.isEmpty) return null;
    try {
      return await _probe(url);
    } catch (e) {
      debugPrint('ReelVideoCache: probe failed for $url: $e');
      return null;
    }
  }

  /// Downloads [url] if needed and returns the local file, or null on failure.
  Future<File?> prefetch(String url) {
    if (url.isEmpty) return Future.value(null);

    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _download(url);
    _inFlight[url] = future;
    return future;
  }

  Future<File?> _download(String url) async {
    try {
      return await _downloader(url);
    } catch (e) {
      debugPrint('ReelVideoCache: download failed for $url: $e');
      return null;
    } finally {
      // Cleared even on failure so a later attempt can retry rather than
      // finding a permanently-failed future cached here.
      _inFlight.remove(url);
    }
  }

  /// Fire-and-forget download, for a reel that is already streaming so the
  /// next view of it is local.
  void warm(String url) {
    prefetch(url);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/moments/reel_video_cache_test.dart`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/reel_video_cache.dart \
        bananatalk_app/test/moments/reel_video_cache_test.dart
git commit -m "feat(reels): dedicated on-disk video cache with in-flight de-duplication"
```

---

### Task 3: Cache-aware controller pool

**Files:**
- Modify: `lib/pages/moments/reels/reel_controller_pool.dart:26-83`
- Modify: `lib/pages/moments/reels/reels_feed_screen.dart` (`_syncControllers`, around lines 95-125)

**Interfaces:**
- Consumes: `ReelVideoCache.instance`, `cachedFileFor`, `prefetch`, `warm` (Task 2); `reelPrefetchDepth`, `kReelMaxPrefetchDepth` (Task 1).
- Produces: `ReelControllerPool({ReelVideoCache? cache})`; new method `Future<void> prefetchAhead(List<String> urls)` on the pool that only warms the cache and creates no controllers.

There is no unit-test harness for `VideoPlayerController` in this repo, so this task is verified by `flutter analyze` plus manual simulator steps.

- [ ] **Step 1: Make the pool cache-aware**

In `reel_controller_pool.dart`, add the import and constructor:

```dart
import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';
```

```dart
class ReelControllerPool {
  ReelControllerPool({ReelVideoCache? cache})
      : _cache = cache ?? ReelVideoCache.instance;

  final ReelVideoCache _cache;
```

Replace the controller construction inside `activate` (currently
`controller = VideoPlayerController.networkUrl(Uri.parse(url));`) with:

```dart
    var controller = _controllers[index];
    if (controller == null) {
      // Play from disk when we already have the bytes: instant start, no
      // network. On a miss stream as before AND warm the cache, so the next
      // view of this reel is local. Cache failure is always soft.
      final cached = await _cache.cachedFileFor(url);
      if (cached == null) {
        _cache.warm(url);
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        controller = VideoPlayerController.file(cached);
      }
      _controllers[index] = controller;
```

Apply the same cached-file preference in `preload`, replacing
`final controller = VideoPlayerController.networkUrl(Uri.parse(url));` with:

```dart
    final cached = await _cache.cachedFileFor(url);
    final controller = cached == null
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.file(cached);
```

- [ ] **Step 2: Add byte-only prefetching to the pool**

Append this method to `ReelControllerPool`, above `pauseAll`:

```dart
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
```

- [ ] **Step 3: Drive depth from connectivity in the feed**

In `reels_feed_screen.dart`, add imports:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_prefetch_policy.dart';
```

Add state fields beside `_muted`:

```dart
  int _prefetchDepth = 1;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
```

In `initState`, after `_loadCurrentUserId();`:

```dart
    Connectivity().checkConnectivity().then((status) {
      if (mounted) setState(() => _prefetchDepth = reelPrefetchDepth(status));
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) setState(() => _prefetchDepth = reelPrefetchDepth(status));
    });
```

In `dispose`, before `_pool.disposeAll();`:

```dart
    _connectivitySub?.cancel();
```

- [ ] **Step 4: Prefetch upcoming reels without widening the controller window**

In `_syncControllers`, leave the existing `activate`, `preload(_currentIndex + 1, …)` and `releaseOutside(_currentIndex)` calls exactly as they are — the ±1 window is deliberate — and append before the closing brace:

```dart
    // Bytes only: reaches further ahead than the controller window, creating
    // no decoders. releaseOutside() below stays at ±1 for that reason.
    final upcoming = <String>[];
    for (var i = _currentIndex + 1;
        i <= _currentIndex + _prefetchDepth && i < reels.length;
        i++) {
      final url = reels[i].video?.url;
      if (url != null && url.isNotEmpty) upcoming.add(url);
    }
    _pool.prefetchAhead(upcoming);
```

- [ ] **Step 5: Verify statically**

Run: `flutter analyze lib/pages/moments/reels/`
Expected: no new issues. Two pre-existing `Share` deprecation infos in `reels_feed_screen.dart` are expected and unrelated.

- [ ] **Step 6: Verify manually in the simulator**

Run: `flutter run` (hot restart, not reload — the pool is long-lived)

Confirm all four:
1. Open a reel, swipe forward three times, swipe back — the return should start immediately with no spinner (it is now a local file).
2. Kill and relaunch the app, open the same reel — still instant, proving the cache survives a restart.
3. Enable airplane mode after watching a reel, reopen it — it still plays from cache.
4. With a fresh cache and airplane mode on, open a reel — it shows the thumbnail and spinner and does **not** crash. Cache failure must be soft.

- [ ] **Step 7: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/reel_controller_pool.dart \
        bananatalk_app/lib/pages/moments/reels/reels_feed_screen.dart
git commit -m "perf(reels): play cached files and prefetch bytes by connection type

Byte prefetching and controller creation are separate concerns: prefetch
reaches up to 3 ahead on wifi while the live controller window stays at
±1, so peak decoders is unchanged at 3."
```

---

### Task 4: Viewport arithmetic for grid autoplay

**Files:**
- Create: `lib/pages/moments/reels/reel_grid_autoplay.dart`
- Test: `test/moments/reel_grid_autoplay_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `List<int> reelTilesToPlay({required double scrollOffset, required double viewportHeight, required double tileHeight, required int crossAxisCount, required int itemCount, int maxPlaying = 3})` — indices to play, nearest viewport centre first, at most `maxPlaying`. Also `const int kReelGridMaxPlaying = 3;`.

- [ ] **Step 1: Write the failing test**

```dart
// test/moments/reel_grid_autoplay_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_grid_autoplay.dart';

void main() {
  // A 3-column grid of 200px-tall tiles in an 800px viewport: four rows fit.
  List<int> play({
    required double offset,
    int itemCount = 30,
    int maxPlaying = 3,
  }) =>
      reelTilesToPlay(
        scrollOffset: offset,
        viewportHeight: 800,
        tileHeight: 200,
        crossAxisCount: 3,
        itemCount: itemCount,
        maxPlaying: maxPlaying,
      );

  group('reelTilesToPlay', () {
    test('never returns more than the cap', () {
      expect(play(offset: 0), hasLength(kReelGridMaxPlaying));
    });

    test('honours a lower explicit cap', () {
      expect(play(offset: 0, maxPlaying: 1), hasLength(1));
    });

    test('at the top, plays tiles from the vertically centred rows', () {
      // Viewport covers rows 0-3; its centre is at 400px, inside row 1.
      final indices = play(offset: 0);
      expect(indices.every((i) => i >= 0 && i < 12), isTrue);
      expect(indices.first, inInclusiveRange(3, 5),
          reason: 'the first pick should sit in the centre row, row 1');
    });

    test('after scrolling, the picks follow the viewport', () {
      final indices = play(offset: 2000); // rows 10-13 visible
      expect(indices.every((i) => i >= 27), isTrue);
    });

    test('clamps to itemCount near the end of the list', () {
      final indices = play(offset: 2000, itemCount: 30);
      expect(indices.every((i) => i < 30), isTrue);
    });

    test('an empty list plays nothing', () {
      expect(play(offset: 0, itemCount: 0), isEmpty);
    });

    test('fewer items than the cap plays only what exists', () {
      expect(play(offset: 0, itemCount: 2), hasLength(2));
    });

    test('returns no duplicate indices', () {
      final indices = play(offset: 350);
      expect(indices.toSet(), hasLength(indices.length));
    });

    test('degenerate geometry plays nothing rather than dividing by zero', () {
      expect(
        reelTilesToPlay(
          scrollOffset: 0,
          viewportHeight: 0,
          tileHeight: 0,
          crossAxisCount: 0,
          itemCount: 10,
        ),
        isEmpty,
      );
    });

    test('a negative scroll offset (overscroll bounce) is safe', () {
      final indices = play(offset: -120);
      expect(indices.every((i) => i >= 0 && i < 30), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/moments/reel_grid_autoplay_test.dart`
Expected: FAIL — `Error: Method not found: 'reelTilesToPlay'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/moments/reels/reel_grid_autoplay.dart
import 'dart:math' as math;

/// Most grid tiles allowed to play at once.
///
/// The full-screen viewer caps live controllers at 3 to avoid exhausting
/// native decoders; the grid honours the same ceiling.
const int kReelGridMaxPlaying = 3;

/// Which grid tiles should be playing, nearest the viewport centre first.
///
/// Pure arithmetic rather than a visibility-detector package: the grid already
/// knows its scroll offset, tile extent, column count and viewport height, so
/// the answer is derivable — and unit-testable — without a new dependency.
List<int> reelTilesToPlay({
  required double scrollOffset,
  required double viewportHeight,
  required double tileHeight,
  required int crossAxisCount,
  required int itemCount,
  int maxPlaying = kReelGridMaxPlaying,
}) {
  if (itemCount <= 0 ||
      crossAxisCount <= 0 ||
      tileHeight <= 0 ||
      viewportHeight <= 0 ||
      maxPlaying <= 0) {
    return const [];
  }

  final offset = math.max(0.0, scrollOffset);
  final rowCount = (itemCount / crossAxisCount).ceil();

  final firstVisibleRow =
      (offset / tileHeight).floor().clamp(0, math.max(0, rowCount - 1));
  final lastVisibleRow = ((offset + viewportHeight) / tileHeight)
      .ceil()
      .clamp(0, rowCount);

  // Rows ordered by how close their centre is to the viewport centre, so the
  // tiles that draw the eye are the ones that move.
  final viewportCentre = offset + viewportHeight / 2;
  final rows = <int>[
    for (var r = firstVisibleRow; r < lastVisibleRow; r++) r,
  ]..sort((a, b) {
      final da = ((a + 0.5) * tileHeight - viewportCentre).abs();
      final db = ((b + 0.5) * tileHeight - viewportCentre).abs();
      return da.compareTo(db);
    });

  final picks = <int>[];
  for (final row in rows) {
    for (var column = 0; column < crossAxisCount; column++) {
      final index = row * crossAxisCount + column;
      if (index >= itemCount) break;
      picks.add(index);
      if (picks.length == maxPlaying) return picks;
    }
  }
  return picks;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/moments/reel_grid_autoplay_test.dart`
Expected: PASS, 10 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/reel_grid_autoplay.dart \
        bananatalk_app/test/moments/reel_grid_autoplay_test.dart
git commit -m "feat(reels): pure viewport arithmetic for which grid tiles play"
```

---

### Task 5: Grid tile widget

**Files:**
- Create: `lib/pages/moments/reels/widgets/reel_grid_tile.dart`

**Interfaces:**
- Consumes: `ReelVideoCache.instance.cachedFileFor` (Task 2); `Moments` from `lib/providers/provider_models/moments_model.dart`; `CachedImageWidget` from `lib/widgets/cached_image_widget.dart`.
- Produces: `ReelGridTile({required Key key, required Moments reel, required bool shouldPlay, required bool mayDownload, required VoidCallback onTap})`.

Verified by `flutter analyze` plus manual steps; there is no widget-test harness for platform video here.

- [ ] **Step 1: Create the tile**

```dart
// lib/pages/moments/reels/widgets/reel_grid_tile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// One tile in the reels grid: a thumbnail that comes alive when it is one of
/// the few tiles chosen to play.
///
/// [shouldPlay] is decided by the parent from `reelTilesToPlay`, so the tile
/// itself owns no policy — it only owns its controller's lifecycle.
///
/// [mayDownload] carries the metered-connection rule: on cellular a tile
/// animates only if the bytes are already cached, so browsing the grid cannot
/// quietly spend a data allowance.
class ReelGridTile extends StatefulWidget {
  const ReelGridTile({
    required Key key,
    required this.reel,
    required this.shouldPlay,
    required this.mayDownload,
    required this.onTap,
  }) : super(key: key);

  final Moments reel;
  final bool shouldPlay;
  final bool mayDownload;
  final VoidCallback onTap;

  @override
  State<ReelGridTile> createState() => _ReelGridTileState();
}

class _ReelGridTileState extends State<ReelGridTile> {
  VideoPlayerController? _controller;
  bool _starting = false;

  @override
  void didUpdateWidget(ReelGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPlay && !oldWidget.shouldPlay) {
      _start();
    } else if (!widget.shouldPlay && oldWidget.shouldPlay) {
      _stop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.shouldPlay) _start();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    final url = widget.reel.video?.url ?? '';
    if (url.isEmpty || _starting || _controller != null) return;
    _starting = true;

    File? file = await ReelVideoCache.instance.cachedFileFor(url);
    if (file == null && widget.mayDownload) {
      file = await ReelVideoCache.instance.prefetch(url);
    }
    // On a metered connection with nothing cached we simply stay a thumbnail.
    if (file == null || !mounted || !widget.shouldPlay) {
      _starting = false;
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted || !widget.shouldPlay) {
        await controller.dispose();
        _starting = false;
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // grid previews are always silent
      await controller.play();
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    } finally {
      _starting = false;
    }
  }

  void _stop() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.pause().whenComplete(controller.dispose);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = widget.reel.video?.thumbnail ?? '';
    final controller = _controller;
    final playing = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail.isNotEmpty)
            CachedImageWidget(imageUrl: thumbnail, fit: BoxFit.cover)
          else
            Container(color: context.containerColor),
          if (playing)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          if (!playing)
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify statically**

Run: `flutter analyze lib/pages/moments/reels/widgets/reel_grid_tile.dart`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/widgets/reel_grid_tile.dart
git commit -m "feat(reels): grid tile that plays muted video when selected"
```

---

### Task 6: Wire autoplay into the grid

**Files:**
- Modify: `lib/pages/moments/reels/reels_grid_screen.dart:34-68` (state, scroll listener) and `:125-154` (`GridView.builder`)

**Interfaces:**
- Consumes: `reelTilesToPlay`, `kReelGridMaxPlaying` (Task 4); `ReelGridTile` (Task 5); `reelPrefetchDepth` (Task 1).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add autoplay state and settle detection**

Add imports to `reels_grid_screen.dart`:

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_grid_autoplay.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_prefetch_policy.dart';
import 'package:bananatalk_app/pages/moments/reels/widgets/reel_grid_tile.dart';
```

Add to `_ReelsGridScreenState`:

```dart
  static const double _tileHeight = 180; // 9:16 at a third of a phone width
  List<int> _playing = const [];
  bool _unmetered = false;
  Timer? _settleTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
```

In `initState`, after the existing listener registration:

```dart
    Connectivity().checkConnectivity().then((status) {
      if (mounted) {
        setState(() => _unmetered = reelPrefetchDepth(status) > 1);
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) setState(() => _unmetered = reelPrefetchDepth(status) > 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePlaying());
```

In `dispose`, before `_scrollController.dispose();`:

```dart
    _settleTimer?.cancel();
    _connectivitySub?.cancel();
```

- [ ] **Step 2: Gate playback on the scroll settling**

Extend the existing `_onScroll` (keep its `loadMore` trigger untouched):

```dart
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(reelsFeedProvider.notifier).loadMore();
    }

    // Nothing plays mid-scroll: flinging through the grid would otherwise
    // spawn and tear down controllers for every row it passed.
    if (_playing.isNotEmpty) {
      setState(() => _playing = const []);
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      // isScrollingNotifier is the authority on "settled" — it stays true
      // through the ballistic phase, which a bare debounce would miss.
      if (_scrollController.hasClients &&
          _scrollController.position.isScrollingNotifier.value) {
        return;
      }
      _recomputePlaying();
    });
  }

  void _recomputePlaying() {
    if (!mounted || !_scrollController.hasClients) return;
    final reels = ref.read(reelsFeedProvider).reels;
    final next = reelTilesToPlay(
      scrollOffset: _scrollController.position.pixels,
      viewportHeight: _scrollController.position.viewportDimension,
      tileHeight: _tileHeight,
      crossAxisCount: 3,
      itemCount: reels.length,
      maxPlaying: kReelGridMaxPlaying,
    );
    setState(() => _playing = next);
  }
```

- [ ] **Step 3: Release controllers when the viewer is pushed**

Replace `_openReel` so the grid stops playing while the full-screen viewer owns the decoders — otherwise the grid's 3 controllers stay alive behind the route alongside the viewer's 3:

```dart
  void _openReel(int index) {
    setState(() => _playing = const []);
    Navigator.of(context)
        .push(AppPageRoute(builder: (_) => ReelsFeedScreen(initialIndex: index)))
        .then((_) {
      if (mounted) _recomputePlaying();
    });
  }
```

- [ ] **Step 4: Render keyed tiles**

In `_buildBody`, replace the `_ReelTile(...)` return with:

```dart
        final reel = state.reels[index];
        return ReelGridTile(
          // Keyed by reel id, never index: GridView.builder recycles
          // children, and an index key would let a recycled tile inherit the
          // previous cell's controller and play the wrong video.
          key: ValueKey('reel-tile-${reel.id}'),
          reel: reel,
          shouldPlay: _playing.contains(index),
          mayDownload: _unmetered,
          onTap: () => _openReel(index),
        );
```

Delete the now-unused `_ReelTile` class (`reels_grid_screen.dart:237-288`). Keep `_LanguageChip` only if still referenced; if not, delete it too and let `flutter analyze` confirm.

- [ ] **Step 5: Verify statically**

Run: `flutter analyze lib/pages/moments/reels/`
Expected: no new issues, and no "unused element" warnings for anything you deleted.

- [ ] **Step 6: Verify manually in the simulator**

Run: `flutter run`, hot restart, open Moments → Reels.

Confirm all five:
1. When the grid is at rest, up to three tiles near the middle are playing — never more.
2. Fling the grid hard: everything freezes to thumbnails mid-scroll and only resumes once it stops.
3. Scroll fast then stop repeatedly — no tile ever shows a video that belongs to a different tile (the recycling bug the id key prevents).
4. Tap into a reel, then come back — the grid resumes playing, and audio never doubles.
5. Switch the simulator to a cellular-only condition with a cleared cache: tiles stay as static thumbnails rather than downloading.

- [ ] **Step 7: Commit**

```bash
git add bananatalk_app/lib/pages/moments/reels/reels_grid_screen.dart
git commit -m "feat(reels): bounded, settle-gated autoplay in the reels grid

At most three tiles play, nearest the viewport centre, and only once
scrolling settles. Tiles are keyed by reel id so recycling can't hand a
tile another tile's controller, and the grid releases its controllers
while the full-screen viewer is open."
```

---

### Task 7: Instagram-style compact counts

**Files:**
- Create: `lib/utils/compact_count.dart`
- Create: `test/utils/compact_count_test.dart`

**Interfaces:**
- Consumes: nothing. Pure Dart, no imports beyond `dart:core`.
- Produces: `String formatCompactCount(int count)`.

**Why:** count display is currently hand-rolled in **nine places** — five
private `_formatCount` methods (`city_tab.dart:1016`, `genders_tab.dart:670`,
`topics_tab.dart:458`, and two in `save_moment_button.dart` at `:160` and
`:317`) plus four inline ternaries (`moment_card.dart:800`,
`moment_card.dart:966`, `single_moment.dart:877`,
`profile/moments/moment_card.dart:635`) — and they disagree.

Six of the nine have no millions branch at all, so 1,000,000 renders as
**"1000.0k"**. Of the three that do handle millions, `topics_tab.dart:460` and
both `save_moment_button.dart` methods use uppercase `K`/`M` while every other
site uses lowercase `k`. And all nine render exactly 1000 as `1.0k`.

This task creates the one true formatter; replacing the call sites is Task 8.

**Do not touch distance formatting.** `nearby_tab.dart:866`,
`location_service.dart:114` and `compact_user_tile.dart:343` also call
`toStringAsFixed(1)` but render kilometres (`"1.4km"`), not counts. They are
out of scope and must be left exactly as they are.

- [ ] **Step 1: Write the failing tests**

```dart
// test/utils/compact_count_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/compact_count.dart';

void main() {
  group('formatCompactCount', () {
    test('renders counts below a thousand exactly', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(7), '7');
      expect(formatCompactCount(999), '999');
    });

    test('drops the dead decimal at exact thresholds', () {
      // The bug this replaces rendered these as "1.0k" and "1.0M".
      expect(formatCompactCount(1000), '1k');
      expect(formatCompactCount(1000000), '1m');
    });

    test('keeps one decimal below ten of a unit', () {
      expect(formatCompactCount(1100), '1.1k');
      expect(formatCompactCount(9900), '9.9k');
      expect(formatCompactCount(1500000), '1.5m');
    });

    test('drops the decimal at ten of a unit and above', () {
      expect(formatCompactCount(10000), '10k');
      expect(formatCompactCount(12300), '12.3k');
      expect(formatCompactCount(123400), '123k');
      expect(formatCompactCount(999000), '999k');
    });

    test('truncates rather than rounding up across a threshold', () {
      // 999,999 must not render as "1000k"; it truncates to 999.9k.
      expect(formatCompactCount(999999), '999.9k');
      // 1,099 truncates to 1k, never rounds to 1.1k.
      expect(formatCompactCount(1099), '1k');
    });

    test('handles millions the same way it handles thousands', () {
      expect(formatCompactCount(10000000), '10m');
      expect(formatCompactCount(1234000000), '1234m');
    });

    test('never emits a negative or a minus sign', () {
      // Counts are cardinalities; a negative is a server bug, not a display
      // case. Clamp rather than render "-5".
      expect(formatCompactCount(-1), '0');
      expect(formatCompactCount(-1000000), '0');
    });
  });
}
```

Run: `flutter test test/utils/compact_count_test.dart`
Expected: fails to compile — `compact_count.dart` does not exist yet.

- [ ] **Step 2: Implement**

```dart
// lib/utils/compact_count.dart

/// Renders a cardinal count the way Instagram does: `999`, `1k`, `1.1k`,
/// `12.3k`, `999k`, `1m`.
///
/// Two rules make it look right rather than merely short:
///
///  * **No dead decimal.** Exactly 1000 is `1k`, not `1.0k`. This is the
///    single most visible flaw in the seven hand-rolled formatters this
///    replaces.
///  * **Truncate, never round up.** 999,999 renders `999.9k`; rounding would
///    produce the self-contradictory `1000k`. Truncation also means a
///    displayed count never overstates the real one.
///
/// One decimal appears only below ten of a unit, where it carries real
/// information (`1.1k` vs `1k`). At ten and above the decimal is noise, so
/// `12300` is `12.3k` but `123400` is `123k`.
String formatCompactCount(int count) {
  // A count is a cardinality. A negative one means the server sent something
  // impossible, and "-5 likes" is a worse answer than "0".
  if (count <= 0) return '0';
  if (count < 1000) return '$count';
  if (count < 1000000) return '${_unit(count, 1000)}k';
  return '${_unit(count, 1000000)}m';
}

/// Formats [count] in units of [divisor], keeping one truncated decimal only
/// while the whole part is a single digit.
String _unit(int count, int divisor) {
  final whole = count ~/ divisor;
  if (whole >= 10) return '$whole';

  // Truncate the tenth rather than rounding, so the result never crosses back
  // over the threshold it was just reduced below.
  final tenths = (count % divisor) * 10 ~/ divisor;
  return tenths == 0 ? '$whole' : '$whole.$tenths';
}
```

Run: `flutter test test/utils/compact_count_test.dart`
Expected: all tests pass.

- [ ] **Step 3: Verify statically**

Run: `flutter analyze lib/utils/compact_count.dart test/utils/compact_count_test.dart`
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add bananatalk_app/lib/utils/compact_count.dart bananatalk_app/test/utils/compact_count_test.dart
git commit -m "feat(ui): one Instagram-style compact count formatter

Seven hand-rolled _formatCount implementations disagreed with each other,
and six of them had no millions branch — so a million likes rendered as
'1000.0k'. This is the single formatter they will all be replaced by.

Truncates rather than rounding so 999,999 cannot render as '1000k', and
drops the dead decimal so 1000 is '1k' rather than '1.0k'."
```

---

### Task 8: Replace every hand-rolled count formatter

**Files (all Modify):**
- `lib/pages/moments/card/moment_card.dart` (two sites: `:799`, `:965`)
- `lib/pages/moments/single/single_moment.dart` (`:876`)
- `lib/pages/profile/moments/moment_card.dart` (`:634`)
- `lib/pages/community/tabs/city_tab.dart` (`_formatCount` at `:1016`, call at `:990`)
- `lib/pages/community/tabs/genders_tab.dart` (`_formatCount` at `:670`, calls at `:449`, `:517`)
- `lib/pages/community/tabs/topics_tab.dart` (`_formatCount` at `:458`, call at `:438`)
- `lib/widgets/save_moment_button.dart` (two `_formatCount` at `:160`, `:317`; calls at `:147`, `:305`)

**Interfaces:**
- Consumes: `formatCompactCount` from `lib/utils/compact_count.dart` (Task 7).
- Produces: nothing new. This task only deletes duplication.

This is deliberately mechanical: import the shared formatter, replace the
inline ternary or the private method's body's call sites with
`formatCompactCount(...)`, then **delete** the now-unused private
`_formatCount` methods. Do not leave a private wrapper that just forwards.

Note the two casing families — `k`/`M` in some files, `K`/`M` in others. They
all become lowercase `k`/`m`, which is the deliberate, stated choice from
Task 7; a reviewer seeing casing change in `topics_tab.dart` and
`save_moment_button.dart` is seeing the intended unification, not a
regression.

- [ ] **Step 1: Replace the call sites and delete the duplicates**

Work file by file. For the four inline-ternary sites, the shape is:

```dart
// before
count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count'
// after
formatCompactCount(count)
```

For the private-method sites, replace the call with `formatCompactCount(...)`
and delete the method declaration.

- [ ] **Step 2: Prove no formatter survives**

Run: `grep -rnE '_formatCount|\((count|likeCount) / 1000' lib --include='*.dart'`
Expected: no output. Any hit is a count site this task missed.

This pattern is deliberately narrower than "anything ending in k". A looser
grep on `toStringAsFixed(1)}` also matches the three **distance** formatters
named in Task 7, which are correct as they stand — do not "fix" them to make
a grep quiet.

- [ ] **Step 3: Verify statically and run the suite**

Run: `flutter analyze lib/` then `flutter test`
Expected: no new analyzer issues; the suite passes. Deleting a private method
that is still referenced fails analysis, which is the check that Step 1 was
complete.

- [ ] **Step 4: Commit**

```bash
git add -u bananatalk_app/lib
git commit -m "refactor(ui): route every count display through formatCompactCount

Deletes seven duplicated _formatCount implementations. Six of them had no
millions branch, so large counts rendered as '1000.0k'; two used uppercase
K/M while the rest used lowercase. All counts now format identically."
```

---

## Out of Scope for This Plan

These are specified in `2026-08-23-reels-performance-and-sharing-design.md` but deliberately deferred to a second plan, because both require a `Moment`/`Message` schema addition and a production backend deploy:

- **View counts** — `viewCount` on `Moment`, `POST /moments/:id/view`, the client throttle and the compacted count on tiles.
- **Share into chat** — `'moment_share'` on the `messageType` enum, the `momentReference` subdocument, reusing `ForwardMessageDialog`, and the share bubble.

Nothing in this plan is blocked by them, and nothing here needs a deploy.

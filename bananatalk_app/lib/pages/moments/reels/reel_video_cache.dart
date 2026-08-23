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

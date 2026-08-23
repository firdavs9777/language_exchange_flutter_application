import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Video container extensions we trust AVFoundation and ExoPlayer to open.
const Set<String> _knownVideoExtensions = {'.mp4', '.mov', '.m4v', '.webm'};

/// The file extension a cached reel video should be saved under, derived from
/// the URL path rather than the HTTP `Content-Type`.
///
/// This exists because of a bug found on a real device, not on principle.
/// `cdn.banatalk.com` serves reel videos as `content-type:
/// application/octet-stream`, and `flutter_cache_manager` maps that to a
/// `.bin` extension (`mime_converter.dart:19`). iOS `AVURLAsset` infers a
/// file's container format from its EXTENSION, never by sniffing bytes — so a
/// byte-perfect MP4 saved as `.bin` is refused outright with
/// `OSStatus -12847, "This media format is not supported"`. Every cached reel
/// failed to open and silently fell back to streaming, so the cache cost a
/// download and bought nothing.
///
/// Falls back to `.mp4` rather than to nothing: an unhelpful-but-plausible
/// container hint still opens, whereas `.bin` provably does not.
String reelVideoFileExtension(String url) {
  // Strip query and fragment first — signed CDN urls carry both, and a
  // `?token=` suffix would otherwise swallow the real extension.
  var path = url.split('#').first.split('?').first;

  final lastSlash = path.lastIndexOf('/');
  if (lastSlash != -1) path = path.substring(lastSlash + 1);

  final dot = path.lastIndexOf('.');
  if (dot == -1) return '.mp4';

  final extension = path.substring(dot).toLowerCase();
  return _knownVideoExtensions.contains(extension) ? extension : '.mp4';
}

/// Wraps [HttpFileService] so downloaded reels land on disk under a real video
/// extension. Only [FileServiceResponse.fileExtension] is overridden; every
/// other response property delegates untouched.
class ReelVideoFileService extends FileService {
  ReelVideoFileService({FileService? inner})
      : _inner = inner ?? HttpFileService();

  final FileService _inner;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final response = await _inner.get(url, headers: headers);
    return _UrlExtensionResponse(response, reelVideoFileExtension(url));
  }
}

class _UrlExtensionResponse implements FileServiceResponse {
  _UrlExtensionResponse(this._inner, this.fileExtension);

  final FileServiceResponse _inner;

  @override
  final String fileExtension;

  @override
  Stream<List<int>> get content => _inner.content;
  @override
  int? get contentLength => _inner.contentLength;
  @override
  String? get eTag => _inner.eTag;
  @override
  int get statusCode => _inner.statusCode;
  @override
  DateTime get validTill => _inner.validTill;
}

/// Downloads [url] and returns the local file, or null on failure.
typedef ReelVideoDownloader = Future<File?> Function(String url);

/// Returns the already-cached local file for [url], or null on a miss.
typedef ReelVideoCacheProbe = Future<File?> Function(String url);

/// Removes [url] from the cache so the next probe misses.
typedef ReelVideoEvictor = Future<void> Function(String url);

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
    ReelVideoEvictor? evictor,
  })  : _downloader = downloader ?? _defaultDownloader,
        _probe = probe ?? _defaultProbe,
        _evictor = evictor ?? _defaultEvictor;

  static const String storeKey = 'bananatalkReelVideoCache';

  static final CacheManager _manager = CacheManager(
    Config(
      storeKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 60,
      // Names files from the URL path instead of the Content-Type, so videos
      // are not saved as `.bin`. See [reelVideoFileExtension].
      fileService: ReelVideoFileService(),
    ),
  );

  static final ReelVideoCache instance = ReelVideoCache();

  final ReelVideoDownloader _downloader;
  final ReelVideoCacheProbe _probe;
  final ReelVideoEvictor _evictor;

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

  static Future<void> _defaultEvictor(String url) => _manager.removeFile(url);

  /// Drops [url] from the cache.
  ///
  /// Called when a cached file turns out to be unplayable. Without this a bad
  /// entry stays "valid" for the whole 7-day stale period, so every playback
  /// attempt pays a failed decoder init and then streams anyway — which is
  /// exactly how the `.bin` bug above kept reproducing after it was cached.
  /// Best-effort: failures are swallowed, since this is only cleanup.
  Future<void> evict(String url) async {
    if (url.isEmpty) return;
    try {
      await _evictor(url);
    } catch (e) {
      debugPrint('ReelVideoCache: evict failed for \$url: \$e');
    }
  }

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

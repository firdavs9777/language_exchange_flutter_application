import 'dart:async';
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

/// Regression tests for the iOS `-12847` failure found on device.
///
/// The CDN serves reel videos as `content-type: application/octet-stream`
/// (verified with curl against cdn.banatalk.com). flutter_cache_manager maps
/// that content type to a `.bin` extension (`mime_converter.dart:19`), and iOS
/// `AVURLAsset` infers a file's container format from its EXTENSION, not its
/// bytes — so a perfectly valid MP4 saved as `.bin` is rejected with
/// `OSStatus -12847, "This media format is not supported"`.
///
/// The cached files really were valid: `file` reported "ISO Media, MP4 v2" and
/// their sizes matched the CDN's content-length exactly.

  group('reelVideoFileExtension', () {
    test('takes the extension from the URL path, not the content type', () {
      expect(reelVideoFileExtension('https://cdn.x.com/a/b/clip.mov'), '.mov');
      expect(reelVideoFileExtension('https://cdn.x.com/a/b/clip.mp4'), '.mp4');
      expect(reelVideoFileExtension('https://cdn.x.com/a/b/clip.m4v'), '.m4v');
    });

    test('ignores query strings and fragments', () {
      // Signed CDN urls carry query parameters; the extension must survive.
      expect(
        reelVideoFileExtension('https://cdn.x.com/clip.mp4?token=abc&e=123'),
        '.mp4',
      );
      expect(reelVideoFileExtension('https://cdn.x.com/clip.mov#t=2'), '.mov');
    });

    test('is case insensitive', () {
      expect(reelVideoFileExtension('https://cdn.x.com/CLIP.MP4'), '.mp4');
      expect(reelVideoFileExtension('https://cdn.x.com/CLIP.MoV'), '.mov');
    });

    test('falls back to .mp4 when the URL carries no video extension', () {
      // Better a plausible container hint than the ".bin" that provably makes
      // AVFoundation refuse the file outright.
      expect(reelVideoFileExtension('https://cdn.x.com/clip'), '.mp4');
      expect(reelVideoFileExtension('https://cdn.x.com/clip.bin'), '.mp4');
      expect(reelVideoFileExtension('https://cdn.x.com/clip.txt'), '.mp4');
      expect(reelVideoFileExtension(''), '.mp4');
    });

    test('is not fooled by a dot in a path segment', () {
      expect(
        reelVideoFileExtension('https://cdn.x.com/v1.2/reels/clip.mp4'),
        '.mp4',
      );
      // A dot in a directory but none in the filename must not leak ".2/reels".
      expect(reelVideoFileExtension('https://cdn.x.com/v1.2/reels/clip'), '.mp4');
    });

    test('never returns .bin, whatever the input', () {
      for (final url in [
        'https://cdn.x.com/a.bin',
        'https://cdn.x.com/a.BIN',
        'https://cdn.x.com/bin',
        'bin',
      ]) {
        expect(reelVideoFileExtension(url), isNot('.bin'), reason: url);
      }
    });
  });

  group('ReelVideoCache.evict', () {
    test('removes the entry so the next probe misses', () async {
      final evicted = <String>[];
      final cache = ReelVideoCache(
        probe: (url) async => evicted.contains(url) ? null : File('/tmp/x.mp4'),
        downloader: (url) async => File('/tmp/x.mp4'),
        evictor: (url) async => evicted.add(url),
      );

      expect(await cache.cachedFileFor('u'), isNotNull);
      await cache.evict('u');
      expect(evicted, ['u']);
      expect(await cache.cachedFileFor('u'), isNull,
          reason: 'an unplayable cached file must not be served again');
    });

    test('swallows evictor failures', () async {
      final cache = ReelVideoCache(
        probe: (url) async => null,
        downloader: (url) async => null,
        evictor: (url) async => throw Exception('disk gone'),
      );
      // Eviction is best-effort cleanup; it must never surface to the caller.
      await expectLater(cache.evict('u'), completes);
    });
  });
}

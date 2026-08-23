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
}

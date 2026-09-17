import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_failure_diagnostics.dart';

/// The pool logged only the PlatformException, which for AVFoundation is a
/// bare OSStatus: -12746 says a decoder refused the file and nothing about the
/// file. Diagnosing it from outside meant guessing — simulator limits, codec,
/// bitrate, moov position — all plausible, all wrong.
void main() {
  group('the verdict on Content-Type', () {
    test('octet-stream is named as the cause', () {
      // AVPlayer picks its decoder from this header; "arbitrary binary" makes
      // it refuse a perfectly good H.264 file.
      final out = ReelFailureDiagnostics.describe(
        url: 'https://cdn/x.mov',
        usingCache: false,
        status: 206,
        contentType: 'application/octet-stream',
      );
      expect(out, contains('-12746'));
      expect(out, contains('not a type it will play'));
    });

    test('a playable type points the reader elsewhere', () {
      for (final type in ['video/mp4', 'video/quicktime']) {
        final out = ReelFailureDiagnostics.describe(
          url: 'https://cdn/x.mp4',
          usingCache: false,
          contentType: type,
        );
        expect(out, contains('look elsewhere'), reason: type);
      }
    });

    test('charset parameters and casing do not confuse the verdict', () {
      final out = ReelFailureDiagnostics.describe(
        url: 'https://cdn/x.mp4',
        usingCache: false,
        contentType: 'Video/MP4; charset=binary',
      );
      expect(out, contains('look elsewhere'));
    });
  });

  group('cached file facts', () {
    test('a .bin cached file is flagged', () {
      // A previous bug stored cached reels as .bin and iOS refused them.
      final out = ReelFailureDiagnostics.describe(
        url: 'https://cdn/x.mov',
        usingCache: true,
        cachedPath: '/tmp/cache/abc.bin',
        cachedBytes: 1234,
      );
      expect(out, contains('no usable video extension'));
    });

    test('a proper extension is not flagged', () {
      final out = ReelFailureDiagnostics.describe(
        url: 'https://cdn/x.mov',
        usingCache: true,
        cachedPath: '/tmp/cache/abc.mov',
        cachedBytes: 1234,
      );
      expect(out, isNot(contains('no usable video extension')));
    });

    test('a cache hit whose file is gone is visible', () {
      final out = ReelFailureDiagnostics.describe(
        url: 'https://cdn/x.mov',
        usingCache: true,
        cachedPath: '/tmp/cache/abc.mov',
        cachedBytes: -1,
      );
      expect(out, contains('-1'));
    });
  });

  test('the url and source are always reported', () {
    final out = ReelFailureDiagnostics.describe(
      url: 'https://cdn/reel.mov',
      usingCache: true,
    );
    expect(out, contains('https://cdn/reel.mov'));
    expect(out, contains('cached file'));
  });

  test('missing facts are omitted rather than printed as null', () {
    final out = ReelFailureDiagnostics.describe(
      url: 'https://cdn/x.mov',
      usingCache: false,
    );
    expect(out, isNot(contains('null')));
  });
}

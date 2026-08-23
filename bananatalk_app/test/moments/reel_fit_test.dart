import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_fit.dart';

/// A reel should fill the screen — letterboxing portrait video makes the
/// viewer feel cheap. But blindly cropping to fill would slice a landscape
/// clip down to a narrow strip, so the decision is "cover unless cropping
/// would throw away most of the frame".
void main() {
  // 9:19.5, a modern phone.
  const phone = 9 / 19.5;

  group('reelVideoFit', () {
    test('9:16 portrait video fills the screen', () {
      expect(
        reelVideoFit(videoAspect: 9 / 16, screenAspect: phone),
        BoxFit.cover,
      );
    });

    test('3:4 portrait video still fills the screen', () {
      expect(
        reelVideoFit(videoAspect: 3 / 4, screenAspect: phone),
        BoxFit.cover,
      );
    });

    test('a video matching the screen exactly fills it', () {
      expect(
        reelVideoFit(videoAspect: phone, screenAspect: phone),
        BoxFit.cover,
      );
    });

    test('16:9 landscape video is letterboxed rather than gutted', () {
      expect(
        reelVideoFit(videoAspect: 16 / 9, screenAspect: phone),
        BoxFit.contain,
      );
    });

    test('4:3 landscape video is letterboxed', () {
      expect(
        reelVideoFit(videoAspect: 4 / 3, screenAspect: phone),
        BoxFit.contain,
      );
    });

    test('an absurdly tall video is letterboxed rather than cropped', () {
      expect(
        reelVideoFit(videoAspect: 9 / 60, screenAspect: phone),
        BoxFit.contain,
      );
    });

    test('the visible-fraction threshold is the boundary', () {
      // Exactly half the frame visible -> still fills.
      expect(
        reelVideoFit(
          videoAspect: phone * 2,
          screenAspect: phone,
          minVisibleFraction: 0.5,
        ),
        BoxFit.cover,
      );
      // Just under half -> letterbox.
      expect(
        reelVideoFit(
          videoAspect: phone * 2.05,
          screenAspect: phone,
          minVisibleFraction: 0.5,
        ),
        BoxFit.contain,
      );
    });

    test('degenerate aspect ratios fall back to contain, never crash', () {
      for (final bad in <double>[0, -1, double.nan, double.infinity]) {
        expect(
          reelVideoFit(videoAspect: bad, screenAspect: phone),
          BoxFit.contain,
          reason: 'videoAspect $bad should be safe',
        );
        expect(
          reelVideoFit(videoAspect: 9 / 16, screenAspect: bad),
          BoxFit.contain,
          reason: 'screenAspect $bad should be safe',
        );
      }
    });
  });
}

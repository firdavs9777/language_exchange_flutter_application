import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/home/splash_timing.dart';

/// The splash awaited a flat 2 seconds AFTER notification set-up, auth restore
/// and a version check — two seconds added to whatever those already cost,
/// every launch, worst on the cold first one this was reported for.
void main() {
  group('remainingSplash', () {
    test('slow start-up waits no longer at all', () {
      // The case that made first launch painful: the real work already took
      // longer than the branding needs.
      expect(
        remainingSplash(const Duration(seconds: 3)),
        Duration.zero,
      );
    });

    test('fast start-up still shows the branding', () {
      // Without a floor the logo would flash and vanish.
      expect(
        remainingSplash(const Duration(milliseconds: 200)),
        const Duration(milliseconds: 1200),
      );
    });

    test('exactly at the floor waits zero, not a negative', () {
      expect(remainingSplash(kMinimumSplash), Duration.zero);
    });

    test('never returns a negative duration', () {
      for (final e in [
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 30),
      ]) {
        expect(remainingSplash(e).isNegative, isFalse, reason: '$e');
      }
    });

    test('the floor is the entrance animation length, not an arbitrary wait', () {
      // Matched to the animation so a splash is never cut off mid-fade.
      expect(kMinimumSplash, const Duration(milliseconds: 1400));
    });
  });
}

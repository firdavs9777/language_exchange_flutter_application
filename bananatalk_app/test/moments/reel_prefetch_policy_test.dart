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

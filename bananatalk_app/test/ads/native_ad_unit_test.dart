import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/ad_service.dart';

/// Regression tests for the endless
/// `NativeAd failed to load: Ad unit doesn't match format` seen on device.
///
/// `_nativeAdUnitId` was a copy-paste of `_bannerAdUnitId` — byte-identical on
/// both platforms — so every `NativeAd` request asked AdMob to serve a NATIVE ad
/// from a BANNER ad unit. AdMob's rejection was correct: no native unit exists.
///
/// Three native slots on the Learning screen meant three wasted round trips and
/// three fallbacks on every visit.
void main() {
  group('nativeAdUnitIsDistinct', () {
    test('false when the native id is just the banner id', () {
      expect(
        nativeAdUnitIsDistinct(
          bannerAdUnitId: 'ca-app-pub-1/2',
          nativeAdUnitId: 'ca-app-pub-1/2',
        ),
        isFalse,
      );
    });

    test('true once a genuinely separate native unit is configured', () {
      expect(
        nativeAdUnitIsDistinct(
          bannerAdUnitId: 'ca-app-pub-1/2',
          nativeAdUnitId: 'ca-app-pub-1/9999',
        ),
        isTrue,
      );
    });

    test('treats blank ids as not configured', () {
      expect(
        nativeAdUnitIsDistinct(bannerAdUnitId: 'ca-app-pub-1/2', nativeAdUnitId: ''),
        isFalse,
      );
      expect(nativeAdUnitIsDistinct(bannerAdUnitId: '', nativeAdUnitId: ''), isFalse);
    });

    test('ignores surrounding whitespace when comparing', () {
      // A stray space is a typo, not a distinct ad unit.
      expect(
        nativeAdUnitIsDistinct(
          bannerAdUnitId: 'ca-app-pub-1/2',
          nativeAdUnitId: ' ca-app-pub-1/2 ',
        ),
        isFalse,
      );
    });
  });
}

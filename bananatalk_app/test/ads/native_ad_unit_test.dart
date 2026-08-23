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

/// Audit finding #1: VIP users could be shown interstitials.
///
/// `AdService._isAdFree` was only ever assigned inside `adServiceProvider`'s
/// body, so it ran only when something read that provider — which happened in
/// two places, while SIX call sites used the `AdService()` singleton directly
/// (moment_card, essay_editor, section_practice, story_setup, lesson_builder,
/// limit_exceeded_dialog). `_isAdFree` defaults to false and ads initialise in
/// main() before the user loads, so a VIP opening a moment got a full-screen
/// interstitial — the exact thing they paid to remove.
///
/// The fix makes "we do not know yet" distinct from "ads are allowed", so the
/// unsafe default becomes no-ads rather than ads-to-paying-customers.
  group('shouldShowFullScreenAd', () {
    test('refuses while the ad-free state is still unknown', () {
      // The old default was isAdFree=false, i.e. "show ads", before the user
      // had even loaded. Unknown must never mean allowed.
      expect(
        shouldShowFullScreenAd(adFreeKnown: false, isAdFree: false),
        isFalse,
      );
      expect(
        shouldShowFullScreenAd(adFreeKnown: false, isAdFree: true),
        isFalse,
      );
    });

    test('refuses for an ad-free (VIP) user', () {
      expect(shouldShowFullScreenAd(adFreeKnown: true, isAdFree: true), isFalse);
    });

    test('allows only a known, non-ad-free user', () {
      expect(shouldShowFullScreenAd(adFreeKnown: true, isAdFree: false), isTrue);
    });
  });
}

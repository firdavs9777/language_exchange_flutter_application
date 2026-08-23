import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Whether a full-screen ad (interstitial / rewarded) may be shown.
///
/// Deliberately refuses while [adFreeKnown] is false. `AdService._isAdFree`
/// used to default to `false` — meaning "show ads" — and was only assigned
/// inside `adServiceProvider`'s body, so it ran only when something read that
/// provider. Six call sites use the `AdService()` singleton directly, and ads
/// initialise in `main()` before the user has loaded, so a VIP could be shown
/// an interstitial: exactly what they paid to remove.
///
/// Treating "unknown" as "not allowed" makes the failure mode a missed
/// impression rather than an ad served to a paying customer.
bool shouldShowFullScreenAd({
  required bool adFreeKnown,
  required bool isAdFree,
}) =>
    adFreeKnown && !isAdFree;

/// Whether a genuinely separate NATIVE ad unit has been configured.
///
/// Returns false when [nativeAdUnitId] is blank or merely repeats
/// [bannerAdUnitId]. In that state AdMob rejects every `NativeAd` request with
/// "Ad unit doesn't match format" — correctly, because a banner ad unit cannot
/// serve a native ad. Requesting anyway costs a round trip per slot and then
/// falls back to a banner regardless, which on the Learning screen meant three
/// wasted requests on every visit.
///
/// Compared trimmed, because a stray space is a typo rather than a new ad unit.
bool nativeAdUnitIsDistinct({
  required String bannerAdUnitId,
  required String nativeAdUnitId,
}) {
  final native = nativeAdUnitId.trim();
  if (native.isEmpty) return false;
  return native != bannerAdUnitId.trim();
}

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  bool _isAdFree = false;

  /// False until [setAdFree] has been called at least once, i.e. until VIP
  /// status is actually known. Until then no full-screen ad may show.
  bool _adFreeKnown = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Google's official sample ad units, used in debug builds only.
  //
  // Debug runs previously hit the PRODUCTION units. Google classifies
  // impressions and clicks generated during development as invalid traffic,
  // which is a documented cause of AdMob account suspension — so every hot
  // restart on a simulator was an account risk, not just noise.
  static const _testBanner = {
    true: 'ca-app-pub-3940256099942544/6300978111',
    false: 'ca-app-pub-3940256099942544/2934735716',
  };
  static const _testInterstitial = {
    true: 'ca-app-pub-3940256099942544/1033173712',
    false: 'ca-app-pub-3940256099942544/4411468910',
  };
  static const _testRewarded = {
    true: 'ca-app-pub-3940256099942544/5224354917',
    false: 'ca-app-pub-3940256099942544/1712485313',
  };
  static const _testNative = {
    true: 'ca-app-pub-3940256099942544/2247696110',
    false: 'ca-app-pub-3940256099942544/3986624511',
  };

  bool get _android => Platform.isAndroid;

  // Production ad unit IDs
  String get _bannerAdUnitId => kDebugMode
      ? _testBanner[_android]!
      : (_android
          ? 'ca-app-pub-5669092242437690/6629245267'
          : 'ca-app-pub-5669092242437690/7326563500');

  String get _interstitialAdUnitId => kDebugMode
      ? _testInterstitial[_android]!
      : (_android
          ? 'ca-app-pub-5669092242437690/4724450892'
          : 'ca-app-pub-5669092242437690/4700400166');

  String get _rewardedAdUnitId => kDebugMode
      ? _testRewarded[_android]!
      : (_android
          ? 'ca-app-pub-5669092242437690/9785205886'
          : 'ca-app-pub-5669092242437690/3424497428');

  // NOTE: in release this is still a copy of the banner unit, because no native
  // ad unit exists in AdMob yet — `hasNativeAdUnit` detects that and skips the
  // request. In debug the distinct test unit means native ads really render, so
  // the native path stays exercisable.
  String get _nativeAdUnitId => kDebugMode
      ? _testNative[_android]!
      : (_android
          ? 'ca-app-pub-5669092242437690/6629245267'
          : 'ca-app-pub-5669092242437690/7326563500');

  String get bannerAdUnitId => _bannerAdUnitId;
  String get nativeAdUnitId => _nativeAdUnitId;

  /// False while `_nativeAdUnitId` is still a copy of `_bannerAdUnitId`, i.e.
  /// while no native ad unit exists in AdMob. Callers should render a banner
  /// directly rather than requesting a native ad that cannot be served.
  ///
  /// This flips to true on its own the moment real native unit ids are pasted
  /// into `_nativeAdUnitId` — no other code needs changing.
  bool get hasNativeAdUnit => nativeAdUnitIsDistinct(
        bannerAdUnitId: _bannerAdUnitId,
        nativeAdUnitId: _nativeAdUnitId,
      );

  bool get isAdFree => _isAdFree;
  bool get isInitialized => _initialized;

  /// Whether a full-screen ad may be shown right now. False while VIP status
  /// is still unknown, so a paying user is never shown one by default.
  bool get canShowFullScreenAd =>
      shouldShowFullScreenAd(adFreeKnown: _adFreeKnown, isAdFree: _isAdFree);

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdService: Google Mobile Ads SDK initialized');
      if (!_isAdFree) {
        loadInterstitial();
        loadRewarded();
      }
    } catch (e) {
      debugPrint('AdService: Failed to initialize - $e');
    }
  }

  void setAdFree(bool adFree) {
    _adFreeKnown = true;
    _isAdFree = adFree;
    if (adFree) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _rewardedAd?.dispose();
      _rewardedAd = null;
    } else if (_initialized) {
      loadInterstitial();
      loadRewarded();
    }
  }

  void loadInterstitial() {
    if (_isAdFree || !_initialized) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Interstitial failed to load - ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (!canShowFullScreenAd || _interstitialAd == null) return;
    await _interstitialAd!.show();
  }

  DateTime? _lastInterstitialAt;
  int _interstitialTriggerCount = 0;

  /// Shows an interstitial only on every [everyN]-th call AND when at least
  /// [minGap] has elapsed since the last one. Keeps full-screen ads from
  /// spamming users on repeated actions (moment opens, session completions)
  /// and stays within AdMob's frequency guidance. Returns true if shown.
  Future<bool> maybeShowInterstitial({
    int everyN = 3,
    Duration minGap = const Duration(minutes: 2),
  }) async {
    if (!canShowFullScreenAd || _interstitialAd == null) return false;

    _interstitialTriggerCount++;
    if (everyN > 1 && _interstitialTriggerCount % everyN != 0) return false;

    final now = DateTime.now();
    if (_lastInterstitialAt != null &&
        now.difference(_lastInterstitialAt!) < minGap) {
      return false;
    }

    _lastInterstitialAt = now;
    await showInterstitial();
    return true;
  }

  void loadRewarded() {
    if (_isAdFree || !_initialized) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Rewarded ad failed to load - ${error.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isRewardedAdReady => !_isAdFree && _rewardedAd != null;

  Future<void> showRewarded({required void Function() onRewarded}) async {
    // Rewarded ads are user-initiated, but still gated: an ad-free user should
    // not be handed an ad-shaped path to a reward.
    if (!canShowFullScreenAd || _rewardedAd == null) return;
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );
  }
}

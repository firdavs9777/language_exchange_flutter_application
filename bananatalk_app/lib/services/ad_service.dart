import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  bool _isAdFree = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Production ad unit IDs
  String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-5669092242437690/6629245267'
      : 'ca-app-pub-5669092242437690/7326563500';

  String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-5669092242437690/4724450892'
      : 'ca-app-pub-5669092242437690/4700400166';

  String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-5669092242437690/9785205886'
      : 'ca-app-pub-5669092242437690/3424497428';

  String get _nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-5669092242437690/6629245267'
      : 'ca-app-pub-5669092242437690/7326563500';

  String get bannerAdUnitId => _bannerAdUnitId;
  String get nativeAdUnitId => _nativeAdUnitId;

  bool get isAdFree => _isAdFree;
  bool get isInitialized => _initialized;

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
    if (_isAdFree || _interstitialAd == null) return;
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
    if (_isAdFree || _interstitialAd == null) return false;

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
    if (_isAdFree || _rewardedAd == null) return;
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );
  }
}

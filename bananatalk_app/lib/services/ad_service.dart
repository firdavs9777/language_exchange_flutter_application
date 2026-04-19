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
      ? 'ca-app-pub-1050509512947605/6444757529'
      : 'ca-app-pub-1050509512947605/8220873620';

  String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-1050509512947605/8739748370'
      : 'ca-app-pub-1050509512947605/9558006020';

  String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-1050509512947605/4940104168'
      : 'ca-app-pub-1050509512947605/1637561082';

  String get _nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-1050509512947605/4455296114'
      : 'ca-app-pub-1050509512947605/1655465274';

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

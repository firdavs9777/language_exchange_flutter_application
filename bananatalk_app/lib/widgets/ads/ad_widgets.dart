import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Adaptive banner ad widget — collapses to SizedBox.shrink() for VIP users
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    final showAds = ref.read(showAdsProvider);
    if (!showAds || _bannerAd != null) return;

    final adService = AdService();
    if (!adService.isInitialized) return;

    final adSize = AdSize.getInlineAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
      60,
    );

    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 60);
    }

    return Container(
      width: double.infinity,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Compact banner ad (32px) for tight spaces like chat list header
class SmallBannerAdWidget extends ConsumerStatefulWidget {
  const SmallBannerAdWidget({super.key});

  @override
  ConsumerState<SmallBannerAdWidget> createState() => _SmallBannerAdWidgetState();
}

class _SmallBannerAdWidgetState extends ConsumerState<SmallBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    final showAds = ref.read(showAdsProvider);
    if (!showAds || _bannerAd != null) return;

    final adService = AdService();
    if (!adService.isInitialized) return;

    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdUnitId,
      size: AdSize.banner, // 320x50 standard banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Native ad widget styled to blend with content cards — collapses for VIP
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adService = AdService();
    if (!adService.isInitialized || adService.isAdFree) return;

    _nativeAd = NativeAd(
      adUnitId: adService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: ${error.message}');
          ad.dispose();
          _nativeAd = null;
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 16,
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Ad" label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Ad',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isLoaded && _nativeAd != null)
            SizedBox(
              height: 300,
              child: AdWidget(ad: _nativeAd!),
            )
          else
            Shimmer.fromColors(
              baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: context.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 300,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// Button to watch a rewarded ad for a temporary bonus
class RewardedAdButton extends ConsumerWidget {
  final VoidCallback onRewarded;
  final String label;

  const RewardedAdButton({
    super.key,
    required this.onRewarded,
    this.label = 'Watch Ad for Bonus',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    final adService = ref.watch(adServiceProvider);
    final isReady = adService.isRewardedAdReady;

    return OutlinedButton.icon(
      onPressed: isReady
          ? () => adService.showRewarded(onRewarded: onRewarded)
          : null,
      icon: const Icon(Icons.play_circle_outline, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF667EEA),
        side: BorderSide(
          color: isReady
              ? const Color(0xFF667EEA)
              : Colors.grey.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

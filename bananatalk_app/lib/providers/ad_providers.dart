import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// Whether ads should be shown (false for VIP users with adFree)
final showAdsProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return false; // Don't show ads until user loads
  final isVip = user.isVip;
  return !isVip;
});

/// Singleton AdService provider that reactively updates adFree flag
final adServiceProvider = Provider<AdService>((ref) {
  final showAds = ref.watch(showAdsProvider);
  final adService = AdService();
  adService.setAdFree(!showAds);
  return adService;
});

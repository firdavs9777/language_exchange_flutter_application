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

/// The user's `privacySettings.personalizedAds`; null until the user loads.
/// No stored settings means the backend default (true).
final personalizedAdsProvider = Provider<bool?>((ref) {
  final user = ref.watch(userProvider).valueOrNull;
  if (user == null) return null;
  return user.privacySettings?.personalizedAds ?? true;
});

/// Singleton AdService provider that reactively updates adFree flag
final adServiceProvider = Provider<AdService>((ref) {
  final showAds = ref.watch(showAdsProvider);
  final adService = AdService();
  adService.setPersonalizedAds(ref.watch(personalizedAdsProvider));
  adService.setAdFree(!showAds);
  return adService;
});

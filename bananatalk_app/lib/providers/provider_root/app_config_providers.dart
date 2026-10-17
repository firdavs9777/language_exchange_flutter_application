import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/services/app_config_service.dart';

final appConfigServiceProvider = Provider<AppConfigService>(
  (ref) => AppConfigService(),
);

/// Holds a config fetched by [refreshAppConfig] until [appConfigProvider]
/// rebuilds with it, and when the last fetch ran.
class AppConfigRefreshState {
  AppConfig? prefetched;
  DateTime? lastFetch;
}

final appConfigRefreshStateProvider =
    Provider<AppConfigRefreshState>((ref) => AppConfigRefreshState());

/// Fetches /api/app-config on first watch. Returns null on network failure.
/// [refreshAppConfig] re-reads it when the app returns to the foreground.
final appConfigProvider = FutureProvider<AppConfig?>((ref) async {
  final refresh = ref.read(appConfigRefreshStateProvider);
  final prefetched = refresh.prefetched;
  refresh.prefetched = null;
  refresh.lastFetch ??= DateTime.now();
  final config = prefetched ?? await ref.read(appConfigServiceProvider).fetch();
  // Interstitial session cap for the legacy every-N ad sites.
  AdService.rewardedLimitsFlag = config?.rewardedLimitsEnabled ?? false;
  return config;
});

/// How long after a fetch a resume does not fetch again.
const Duration appConfigRefreshInterval = Duration(minutes: 2);

/// Re-reads app-config (called on resume), so a switch flipped server-side
/// (e.g. BOOSTS_ENABLED) shows without a full restart. The fetch happens
/// first and [appConfigProvider] is only rebuilt with a successful answer:
/// a failed fetch keeps the config already loaded instead of turning
/// features off. Returns whether the config was replaced.
Future<bool> refreshAppConfig(
  ProviderContainer container, {
  DateTime? now,
}) async {
  final state = container.read(appConfigRefreshStateProvider);
  final at = now ?? DateTime.now();
  final last = state.lastFetch;
  if (last != null && at.difference(last) < appConfigRefreshInterval) {
    return false;
  }
  state.lastFetch = at;
  final config = await container.read(appConfigServiceProvider).fetch();
  if (config == null) return false;
  state.prefetched = config;
  container.invalidate(appConfigProvider);
  await container.read(appConfigProvider.future);
  return true;
}

/// Cached running app version (e.g. "1.3.8") loaded once via package_info_plus.
final runningAppVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Post-registration read of `matchesLayoutEnabled` within one [budget]
/// (the 3s the register screen has always allowed). If the config read is in
/// (or lands in) an error state, [invalidate] it once and retry with whatever
/// budget is left. Any timeout or second failure -> false, i.e. today's
/// `/home` landing.
Future<bool> resolveMatchesLayoutForNewUser({
  required bool Function() hasError,
  required void Function() invalidate,
  required Future<AppConfig?> Function() read,
  Duration budget = const Duration(seconds: 3),
}) async {
  final elapsed = Stopwatch()..start();
  var retried = false;
  if (hasError()) {
    invalidate();
    retried = true;
  }
  while (true) {
    final remaining = budget - elapsed.elapsed;
    if (remaining <= Duration.zero) return false;
    try {
      final config = await read().timeout(remaining);
      return config?.matchesLayoutEnabled ?? false;
    } on TimeoutException {
      return false;
    } catch (_) {
      if (retried) return false;
      retried = true;
      invalidate();
    }
  }
}

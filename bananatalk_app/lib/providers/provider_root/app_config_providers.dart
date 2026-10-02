import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/services/app_config_service.dart';

final appConfigServiceProvider = Provider<AppConfigService>(
  (ref) => AppConfigService(),
);

/// Fetches /api/app-config once on first watch. Returns null on network failure.
final appConfigProvider = FutureProvider<AppConfig?>((ref) async {
  final config = await ref.read(appConfigServiceProvider).fetch();
  // Interstitial session cap for the legacy every-N ad sites.
  AdService.rewardedLimitsFlag = config?.rewardedLimitsEnabled ?? false;
  return config;
});

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

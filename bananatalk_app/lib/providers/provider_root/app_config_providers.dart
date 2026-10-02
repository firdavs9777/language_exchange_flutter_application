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

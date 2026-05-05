import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:bananatalk_app/widgets/update_dialog.dart';

/// Decides whether and how to prompt the user to update.
///
/// - If runningVersion < minVersion → blocking force dialog (always shown)
/// - Else if runningVersion < latestVersion or forceUpdate flag is set →
///   soft prompt, capped to once per [_softPromptCooldown]
/// - Else → no dialog
class VersionCheckCoordinator {
  static const _lastSoftPromptKey = 'app_update_last_soft_prompt_ms';
  static const Duration _softPromptCooldown = Duration(hours: 24);

  final AppConfigService _service;

  VersionCheckCoordinator({AppConfigService? service})
    : _service = service ?? AppConfigService();

  Future<void> check(BuildContext context) async {
    final config = await _service.fetch();
    if (config == null) return;
    if (!context.mounted) return;

    final running = (await PackageInfo.fromPlatform()).version;
    final cmpMin = compareSemver(running, config.minVersion);
    final cmpLatest = compareSemver(running, config.latestVersion);

    final mustForce = cmpMin < 0 || config.forceUpdate;
    final shouldSoftPrompt = !mustForce && cmpLatest < 0;

    if (mustForce) {
      if (!context.mounted) return;
      await showUpdateDialog(
        context: context,
        force: true,
        iosUrl: config.iosUrl,
        androidUrl: config.androidUrl,
        releaseNotes: config.releaseNotes,
      );
      return;
    }

    if (shouldSoftPrompt) {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_lastSoftPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastShown < _softPromptCooldown.inMilliseconds) return;

      if (!context.mounted) return;
      await showUpdateDialog(
        context: context,
        force: false,
        iosUrl: config.iosUrl,
        androidUrl: config.androidUrl,
        releaseNotes: config.releaseNotes,
      );
      await prefs.setInt(_lastSoftPromptKey, now);
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/widgets/update_dialog.dart';

/// Decides whether to prompt for an update (runs in splash).
///
/// - running < minVersion or forceUpdate → blocking dialog (always shown)
/// - running < latestVersion → soft prompt, once per [_softPromptCooldown],
///   and only if the launch's [PopupBudget] is unspent
///
/// The announcement moved to `LaunchModalCoordinator` (spec §4.1); this
/// reports whether it showed, so the coordinator stops.
class VersionCheckCoordinator {
  static const _lastSoftPromptKey = 'app_update_last_soft_prompt_ms';
  static const Duration _softPromptCooldown = Duration(hours: 24);

  /// Whether a [check] in this process put an update dialog on screen.
  static bool lastCheckShowedUpdate = false;

  final AppConfigService _service;

  VersionCheckCoordinator({AppConfigService? service})
      : _service = service ?? AppConfigService();

  /// Splash entry point. Never throws: a check that fails counts as "no
  /// update dialog" and the launch carries on.
  static Future<bool> checkSafely(
    BuildContext context, {
    VersionCheckCoordinator? coordinator,
  }) async {
    try {
      return await (coordinator ?? VersionCheckCoordinator()).check(context);
    } catch (e) {
      debugPrint('VersionCheckCoordinator: check failed: $e');
      return false;
    }
  }

  /// True when an update dialog was put on screen (it is then this launch's
  /// pop-up). A force update always shows and blocks everything after it.
  Future<bool> check(BuildContext context) async {
    lastCheckShowedUpdate = false;
    final config = await _service.fetch();
    if (config == null) return false;
    if (!context.mounted) return false;

    final running = (await PackageInfo.fromPlatform()).version;
    final mustForce =
        compareSemver(running, config.minVersion) < 0 || config.forceUpdate;
    final shouldSoftPrompt =
        !mustForce && compareSemver(running, config.latestVersion) < 0;

    if (mustForce) {
      if (!context.mounted) return false;
      PopupBudget.tryConsume(); // spends it; shown regardless
      lastCheckShowedUpdate = true;
      await showUpdateDialog(
        context: context,
        force: true,
        iosUrl: config.iosUrl,
        androidUrl: config.androidUrl,
        releaseNotes: config.releaseNotes,
      );
      return true;
    }

    if (shouldSoftPrompt) {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_lastSoftPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastShown >= _softPromptCooldown.inMilliseconds) {
        if (!context.mounted) return false;
        if (!PopupBudget.tryConsume()) return false;
        lastCheckShowedUpdate = true;
        await showUpdateDialog(
          context: context,
          force: false,
          iosUrl: config.iosUrl,
          androidUrl: config.androidUrl,
          releaseNotes: config.releaseNotes,
        );
        await prefs.setInt(_lastSoftPromptKey, now);
        return true;
      }
    }
    return false;
  }
}

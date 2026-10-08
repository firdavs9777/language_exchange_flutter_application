import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Android 14+ revokes USE_FULL_SCREEN_INTENT by default for most apps, so
/// incoming calls on a locked phone show as a small notification. Ask once,
/// with an explainer, after the user's first incoming call has ended (never
/// on top of a ringing screen).
class FullScreenIntentPrompt {
  const FullScreenIntentPrompt._();

  static const String prefsKey = 'call_fsi_prompted';

  static bool shouldAsk({required bool isAndroid, required bool canUse, required bool alreadyAsked}) =>
      isAndroid && !canUse && !alreadyAsked;

  static Future<bool> alreadyAsked() async =>
      (await SharedPreferences.getInstance()).getBool(prefsKey) ?? false;

  static Future<void> markAsked() async =>
      (await SharedPreferences.getInstance()).setBool(prefsKey, true);

  static Future<void> maybeAsk(BuildContext context) async {
    if (!Platform.isAndroid) return;
    bool canUse = true;
    try {
      canUse = (await FlutterCallkitIncoming.canUseFullScreenIntent()) == true;
    } catch (e) {
      debugPrint('📞 canUseFullScreenIntent failed: $e');
    }
    if (!shouldAsk(isAndroid: true, canUse: canUse, alreadyAsked: await alreadyAsked())) return;
    await markAsked();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.callFullScreenIntentTitle),
        content: Text(l10n.callFullScreenIntentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.openSettings)),
        ],
      ),
    );
    if (allow != true) return;
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      debugPrint('📞 requestFullIntentPermission failed: $e');
    }
  }
}

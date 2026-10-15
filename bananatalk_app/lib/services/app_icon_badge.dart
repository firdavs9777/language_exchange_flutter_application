import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The number on the iOS app icon, set through a small channel in
/// AppDelegate.swift (no badge plugin in pubspec).
///
/// The server sets `aps.badge` to the unread-message count on every chat
/// push; callers pass that same count so the icon does not jump between
/// two meanings. Android has no portable icon badge: launchers derive their
/// dot from the notifications in the shade, so this is a no-op there.
class AppIconBadge {
  static const MethodChannel channel = MethodChannel('bananatalk/app_badge');

  static Future<void> set(int count, {bool? isIOS}) async {
    final ios = isIOS ?? (!kIsWeb && Platform.isIOS);
    if (!ios) return;
    try {
      await channel.invokeMethod<void>(
          'setBadge', {'count': count < 0 ? 0 : count});
    } catch (_) {
      // Best-effort: a stale badge must never break the caller.
    }
  }
}

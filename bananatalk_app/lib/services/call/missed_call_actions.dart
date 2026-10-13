import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/language_service.dart';

/// Missed-call push actions (calls Phase 2, C4 backend contract): builds that
/// declare `missed_call_actions` get iOS category [kMissedCallCategory] and,
/// on Android, a data-only push the app draws itself with the two buttons.

const String kMissedCallCategory = 'MISSED_CALL';
const String kMissedCallBack = 'call_back';
const String kMissedCallMessage = 'message';

/// Same channel every other banner uses (created at start-up; `show` creates
/// it too when the app has not run since install).
const String _channelId = 'high_importance_channel';
const String _channelName = 'High Importance Notifications';

List<String> missedCallActions(Map<String, dynamic> data) {
  final raw = data['actions'];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is! String || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
  } catch (_) {}
  return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

/// Where a missed-call action goes. Call back carries `?call=` so the chat
/// screen starts the call once it has the user (works from a killed app).
String? missedCallActionRoute(Map<String, dynamic> data, String? actionId) {
  if (data['type']?.toString() != 'missed_call') return null;
  final callerId = data['callerId']?.toString() ?? '';
  if (callerId.isEmpty) return null;
  if (actionId == kMissedCallBack) {
    final type = data['callType']?.toString() == 'video' ? 'video' : 'audio';
    return '/chat/$callerId?call=$type';
  }
  if (actionId == kMissedCallMessage) return '/chat/$callerId';
  return null;
}

/// One key per missed call, whichever way its tap arrives. Without a call id
/// the caller alone is not a call: two missed calls from the same person
/// must not collapse, so the push's own time is added when it has one.
/// [expires] is true when only the caller is left: that key is remembered for
/// a short window (the same tap's other delivery paths), not for the process.
({String key, bool expires}) _tapKey(Map<String, dynamic> data) {
  for (final k in const ['callId', 'callUuid']) {
    final v = data[k]?.toString() ?? '';
    if (v.isNotEmpty) return (key: '$k:$v', expires: false);
  }
  final caller = data['callerId']?.toString() ?? '';
  for (final k in const ['sentAt', 'timestamp', 'sentTime', 'messageId']) {
    final v = data[k]?.toString() ?? '';
    if (v.isNotEmpty) return (key: 'callerId:$caller@$v', expires: false);
  }
  return (key: 'callerId:$caller', expires: true);
}

class _Tap {
  const _Tap(this.key, this.callerId, this.route, {required this.isAction});
  final String key;
  final String callerId;
  final String route;
  final bool isAction;
}

/// Routes missed-call notification taps exactly once, and never over the
/// splash.
///
/// One tap can reach the app up to three ways: the local-notification
/// response (Android action / launch details), FCM `getInitialMessage` and
/// `onMessageOpenedApp`, and on iOS the native AppDelegate channel. All of
/// them go through [submit]; a call already seen is dropped (an action that
/// arrives while a plain tap for the same call is still waiting replaces it).
///
/// Until [settle] (the router has left `/splash`) a tap is held, so a cold
/// start never races the splash's own `go('/home')`. When it is let through:
/// signed out → nothing (the app just opens); blocked caller → nothing.
class MissedCallTapGate {
  MissedCallTapGate({
    required this.navigate,
    required this.isSignedIn,
    required this.isBlocked,
    this.blockLookupTimeout = const Duration(seconds: 5),
    this.callerOnlyWindow = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final void Function(String route) navigate;
  final bool Function() isSignedIn;
  final Future<bool> Function(String userId) isBlocked;
  final Duration blockLookupTimeout;

  /// How long a tap with no call id and no push time (key = caller only)
  /// counts as a repeat: long enough for its other delivery paths, short
  /// enough that the caller's next missed call is routed.
  final Duration callerOnlyWindow;
  final DateTime Function() _now;

  static const int _remembered = 50;

  bool _settled = false;
  _Tap? _pending;

  /// Seen keys; the value is when a caller-only key stops counting (null:
  /// remembered while it is among the last [_remembered]).
  final LinkedHashMap<String, DateTime?> _seen = LinkedHashMap<String, DateTime?>();

  bool get isSettled => _settled;

  /// True when [data] is a missed-call tap this gate took (routed, held or
  /// dropped as a repeat); false leaves it to the caller's own routing.
  bool submit(Map<String, dynamic> data, String? actionId) {
    if (data['type']?.toString() != 'missed_call') return false;
    final callerId = data['callerId']?.toString() ?? '';
    if (callerId.isEmpty) return false;

    final actionRoute = missedCallActionRoute(data, actionId);
    final id = _tapKey(data);
    final tap = _Tap(
      id.key,
      callerId,
      actionRoute ?? '/chat/$callerId',
      isAction: actionRoute != null,
    );

    final now = _now();
    final until = _seen[tap.key];
    if (_seen.containsKey(tap.key) && until != null && !until.isAfter(now)) {
      _seen.remove(tap.key); // a caller-only key past its window: a new call
    }
    if (_seen.containsKey(tap.key)) {
      final waiting = _pending;
      if (tap.isAction && waiting != null && waiting.key == tap.key && !waiting.isAction) {
        _pending = tap;
      }
      return true;
    }
    _seen[tap.key] = id.expires ? now.add(callerOnlyWindow) : null;
    if (_seen.length > _remembered) _seen.remove(_seen.keys.first);

    if (!_settled) {
      final waiting = _pending;
      if (waiting == null || tap.isAction || !waiting.isAction) _pending = tap;
      return true;
    }
    unawaited(_dispatch(tap));
    return true;
  }

  /// The app is past the splash: let a held tap through. Idempotent.
  void settle() {
    if (_settled) return;
    _settled = true;
    final held = _pending;
    _pending = null;
    if (held != null) unawaited(_dispatch(held));
  }

  Future<void> _dispatch(_Tap tap) async {
    try {
      if (!isSignedIn()) return;
      var blocked = false;
      try {
        blocked = await isBlocked(tap.callerId).timeout(blockLookupTimeout);
      } catch (_) {
        // Unknown: the server refuses a call between blocked users anyway.
      }
      if (blocked) return;
      navigate(tap.route);
    } catch (e) {
      debugPrint('[missed-call] tap routing failed: $e');
    }
  }
}

/// Notification strings for code that runs without a widget tree (the
/// background isolate, start-up category registration): the app language
/// the user chose, else the device's, else English.
Future<AppLocalizations> notificationL10n() async {
  try {
    final locale = LanguageService.getLocale(await LanguageService.getAppLanguage());
    if (AppLocalizations.delegate.isSupported(locale)) {
      return lookupAppLocalizations(locale);
    }
  } catch (_) {}
  return lookupAppLocalizations(const Locale('en'));
}

/// Title and body for the drawn notification: the server's localized text,
/// else [fallbackTitle] and the caller's name.
({String title, String body}) missedCallNotificationContent(
  Map<String, dynamic> data, {
  required String fallbackTitle,
}) {
  final title = data['title']?.toString() ?? '';
  final body = data['body']?.toString() ?? '';
  return (
    title: title.isNotEmpty ? title : fallbackTitle,
    body: body.isNotEmpty ? body : (data['callerName']?.toString() ?? ''),
  );
}

/// Stable 31-bit id per call (FNV-1a), the same in every isolate, so a repeat
/// of the same push replaces the notification instead of stacking. With no
/// call id at all, caller + time: two such missed calls never replace each
/// other.
int missedCallNotificationId(
  Map<String, dynamic> data, {
  DateTime Function() now = DateTime.now,
}) {
  String? present(String key) {
    final v = data[key]?.toString() ?? '';
    return v.isEmpty ? null : v;
  }

  final source = present('callId') ??
      present('callUuid') ??
      '${data['callerId'] ?? ''}@${now().microsecondsSinceEpoch}';
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode('missed_call:$source')) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Android data-only missed call: draw it with Call back / Message.
///
/// Fail-safe by design. The push carries no notification of its own, so if
/// this throws the missed call is silently lost: any failure (strings,
/// avatar, the action notification itself) falls back to a plain notification
/// with the same tap payload. Never throws.
Future<void> showMissedCallNotification(
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic> data, {
  bool initialize = false,
  @visibleForTesting bool? isAndroid,
}) async {
  if (!(isAndroid ?? Platform.isAndroid)) return;
  if (initialize) {
    try {
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
        ),
      );
    } catch (e) {
      debugPrint('[missed-call] notification init failed: $e');
    }
  }

  AppLocalizations? l10n;
  try {
    l10n = await notificationL10n();
  } catch (_) {}
  final content = missedCallNotificationContent(
    data,
    fallbackTitle: l10n?.callMissed ?? 'Missed Call',
  );
  final id = missedCallNotificationId(data);
  String payload;
  try {
    payload = jsonEncode(data);
  } catch (_) {
    payload = jsonEncode({
      'type': 'missed_call',
      for (final k in const ['callId', 'callUuid', 'callerId', 'callType'])
        if (data[k] != null) k: data[k].toString(),
    });
  }

  try {
    final labels = l10n!;
    final icon = await _downloadAvatar(data['imageUrl']?.toString());
    await plugin.show(
      id,
      content.title,
      content.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.missedCall,
          largeIcon: icon != null ? FilePathAndroidBitmap(icon) : null,
          actions: [
            AndroidNotificationAction(
              kMissedCallBack,
              labels.callBackAction,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              kMissedCallMessage,
              labels.callMessageAction,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: payload,
    );
  } catch (e) {
    debugPrint('[missed-call] action notification failed, showing plain: $e');
    try {
      await plugin.show(
        id,
        content.title,
        content.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[missed-call] plain notification failed: $e');
    }
  }
}

/// The caller's avatar as a local file for the large icon, or null. Bounded,
/// so a slow image never costs the notification itself.
Future<String?> _downloadAvatar(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/missed_call_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// iOS remote-notification action taps are caught natively (AppDelegate) and
/// handed over on this channel; a cold start asks for the pending one.
/// `takePending` → `{action, callId, callerId, callType}` or null; native →
/// Dart `action` with the same map.
const MethodChannel missedCallActionsChannel = MethodChannel('bananatalk/missed_call_actions');

/// The router payload for a natively caught action.
Map<String, dynamic> nativeMissedCallTapData(Map<dynamic, dynamic> m) => {
      'type': 'missed_call',
      'callId': m['callId']?.toString() ?? '',
      'callerId': m['callerId']?.toString() ?? '',
      'callType': m['callType']?.toString() ?? 'audio',
      '_actionId': m['action']?.toString(),
    };

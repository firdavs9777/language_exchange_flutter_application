import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';

import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Wraps flutter_callkit_incoming to show native incoming call UI on both
/// iOS (CallKit) and Android (full-screen activity). This replaces the
/// custom full-screen intent notification on Android and adds proper iOS
/// background call support.
class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  /// Returns true if CallKit should be used on this device.
  /// CallKit is disabled on iOS in China per MIIT regulations.
  /// On Android, flutter_callkit_incoming uses a full-screen activity (not CallKit),
  /// so it's always allowed.
  static bool get isCallKitAllowed {
    if (!Platform.isIOS) return true;
    // Check device region/locale for China
    final locale = Platform.localeName; // e.g. "zh_CN", "en_CN", "zh-Hans_CN"
    if (locale.endsWith('_CN')) return false;
    // Also check via PlatformDispatcher for cases where localeName format differs
    try {
      final uiLocale = ui.PlatformDispatcher.instance.locale;
      if (uiLocale.countryCode == 'CN') return false;
    } catch (_) {}
    return true;
  }

  /// Callbacks for call actions from the native UI. The optional [extra]
  /// payload on `onAccepted` carries pre-minted LiveKit fields that arrive
  /// alongside the CallKit prompt (set in [showIncomingCall] for the
  /// foreground path, and via PushKit's payload for killed-state). The
  /// caller uses it to hydrate `CallManager.currentCall` when accept fires
  /// before the FCM/socket path has run.
  /// Every callback receives the CallKit UUID (uppercase on iOS), never the
  /// server id — that is `extra['callId']`.
  Function(String callKitId, Map<String, dynamic>? extra)? onAccepted;
  Function(String callKitId, Map<String, dynamic>? extra)? onDeclined;
  Function(String callKitId, Map<String, dynamic>? extra)? onEnded;
  Function(String callKitId, Map<String, dynamic>? extra)? onTimedOut;

  bool _listenersRegistered = false;

  /// Current active callkit UUID (used for ending/updating the call)
  String? _activeCallUuid;

  /// Most-recent VoIP push token Apple handed us via PKPushRegistry. Cached
  /// so we can re-upload after login or backend errors without waiting for
  /// the next system-issued rotation.
  String? _voipToken;
  String? get voipToken => _voipToken;

  final NotificationApiClient _api = NotificationApiClient();

  /// Initialize listeners for CallKit events.
  /// Call this once at app startup.
  void initialize() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    // If the previous run cached a VoIP token while no user was logged in,
    // try uploading it now — the user may have signed in since then. This
    // matters because Apple only re-fires `didUpdate` on token rotation
    // (rare), so the token we have may be the only one we'll see for a
    // while.
    if (Platform.isIOS) {
      unawaited(reuploadVoipTokenIfAvailable());
    }

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      debugPrint('📱 CallKit event: ${event.event} body=${event.body}');

      switch (event.event) {
        case Event.actionCallAccept:
          final id = _extractId(event.body);
          if (id != null) onAccepted?.call(id, _extraOf(event.body));
          break;
        case Event.actionCallDecline:
          final id = _extractId(event.body);
          if (id != null) onDeclined?.call(id, _extraOf(event.body));
          break;
        case Event.actionCallEnded:
          final id = _extractId(event.body);
          if (id != null) onEnded?.call(id, _extraOf(event.body));
          _activeCallUuid = null;
          break;
        case Event.actionCallTimeout:
          // The native ring timed out: dismiss locally. The server's 45 s
          // timer owns the outcome, so this is never a decline.
          final id = _extractId(event.body);
          if (id != null) onTimedOut?.call(id, _extraOf(event.body));
          _activeCallUuid = null;
          break;
        case Event.actionDidUpdateDevicePushTokenVoip:
          // iOS only — PKPushRegistry handed us a new VoIP token. Cache
          // and upload it; backend uses it to send VoIP pushes when calls
          // are initiated, bypassing the silent-FCM-push throttling that
          // makes killed-state calls unreliable on iOS.
          final token = _extractVoipToken(event.body);
          if (token != null) {
            _voipToken = token.isEmpty ? null : token;
            debugPrint('📞 VoIP token from PushKit: '
                '${token.isEmpty ? "(empty/invalidated)" : token}');
            unawaited(_uploadVoipToken(token));
          }
          break;
        default:
          break;
      }
    });
  }

  String? _extractVoipToken(Map<String, dynamic>? body) {
    return body?['deviceTokenVoIP']?.toString() ??
        body?['deviceToken']?.toString() ??
        body?['token']?.toString();
  }

  /// Persist the VoIP token locally + push to backend so subsequent
  /// incoming-call sends target this device. No-op if the user isn't
  /// logged in yet — the token will be re-uploaded on next login via
  /// [reuploadVoipTokenIfAvailable].
  Future<void> _uploadVoipToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        // Defer — the token stays cached in _voipToken; we re-upload
        // when the next login flow calls reuploadVoipTokenIfAvailable.
        await prefs.setString('pending_voip_token', token);
        return;
      }
      // The real device id (same one the FCM token uses): call_cancelled
      // skips the device that accepted/declined by this id.
      final deviceId = await NotificationService().getDeviceId();
      await _api.registerVoipToken(token, deviceId);
      await prefs.remove('pending_voip_token');
    } catch (e) {
      debugPrint('📞 VoIP token upload failed: $e');
    }
  }

  /// Called from the login flow once a user id is known — re-uploads any
  /// VoIP token that arrived before the user was logged in.
  Future<void> reuploadVoipTokenIfAvailable() async {
    if (!Platform.isIOS) return;
    final cached = _voipToken;
    if (cached == null || cached.isEmpty) {
      // Maybe a token came in pre-login and we only stashed it in prefs.
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('pending_voip_token');
      if (pending == null || pending.isEmpty) return;
      await _uploadVoipToken(pending);
      return;
    }
    await _uploadVoipToken(cached);
  }

  /// The CallKit UUID only — never `extra['callId']` (the server id).
  String? _extractId(Map<String, dynamic>? body) {
    final id = body?['id']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  Map<String, dynamic>? _extraOf(Map<String, dynamic>? body) {
    final extra = body?['extra'];
    return extra is Map ? Map<String, dynamic>.from(extra) : null;
  }

  /// The native incoming-call params. Pure, so the id/extra contract with
  /// AppDelegate.swift and CallManager is unit-tested.
  static CallKitParams buildIncomingParams({
    required String callId,
    String? callUuid,
    required String callerName,
    String? callerAvatar,
    String? callerId,
    bool isVideo = false,
    String? livekitUrl,
    String? roomName,
  }) {
    // CallKit ids MUST be UUIDs (the plugin force-unwraps UUID(uuidString:)
    // on iOS); the 24-hex Mongo id crashed backgrounded iPhones.
    final uuid = CallKitIds.uuidFor(callId: callId, callUuid: callUuid);
    final extra = <String, dynamic>{
      'callId': callId,
      'callUuid': uuid,
      'callType': isVideo ? 'video' : 'audio',
      'callerName': callerName,
      if (callerAvatar != null) 'callerAvatar': callerAvatar,
      if (callerId != null) 'callerId': callerId,
      if (livekitUrl != null) 'livekitUrl': livekitUrl,
      if (roomName != null) 'roomName': roomName,
    };
    return CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Bananatalk',
      avatar: callerAvatar,
      handle: callerName,
      type: isVideo ? 1 : 0, // 0 = audio, 1 = video
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
      ),
      duration: 50000, // Outlasts the server's 45 s ring; the server ends the call
      extra: extra,
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1a1a2e',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: null, // Uses default iOS ringtone
      ),
    );
  }

  /// Show the native incoming call screen. Returns the CallKit id (the
  /// callUuid), needed to end it later. The LiveKit token is NOT carried:
  /// it comes from POST /calls/:id/accept.
  Future<String> showIncomingCall({
    required String callId,
    String? callUuid,
    required String callerName,
    String? callerAvatar,
    String? callerId,
    bool isVideo = false,
    String? livekitUrl,
    String? roomName,
  }) async {
    final params = buildIncomingParams(
      callId: callId,
      callUuid: callUuid,
      callerName: callerName,
      callerAvatar: callerAvatar,
      callerId: callerId,
      isVideo: isVideo,
      livekitUrl: livekitUrl,
      roomName: roomName,
    );
    final uuid = params.id!;
    _activeCallUuid = uuid;

    if (!isCallKitAllowed) {
      debugPrint('📱 CallKit disabled (China/iOS) — skipping native call UI');
      return uuid;
    }

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('📱 CallKit incoming call shown: $uuid ($callerName)');
    return uuid;
  }

  /// Calls the native UI currently shows (iOS reports ids uppercase).
  Future<List<CallKitEntry>> activeCallEntries() async {
    final raw = await FlutterCallkitIncoming.activeCalls();
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(CallKitEntry.fromPlugin).toList();
  }

  /// Show an outgoing call screen (for the caller side).
  Future<void> showOutgoingCall({
    required String callId,
    required String calleeName,
    String? calleeAvatar,
    bool isVideo = false,
  }) async {
    final uuid = callId.isNotEmpty ? callId : const Uuid().v4();
    _activeCallUuid = uuid;

    final params = CallKitParams(
      id: uuid,
      nameCaller: calleeName,
      appName: 'Bananatalk',
      avatar: calleeAvatar,
      handle: calleeName,
      type: isVideo ? 1 : 0,
      extra: {'callId': callId},
    );

    if (!isCallKitAllowed) {
      debugPrint('📱 CallKit disabled (China/iOS) — skipping outgoing call UI');
      return;
    }

    await FlutterCallkitIncoming.startCall(params);
  }

  /// End the current call in the native UI.
  Future<void> endCall([String? callId]) async {
    final uuid = callId ?? _activeCallUuid;
    if (uuid != null && isCallKitAllowed) {
      await FlutterCallkitIncoming.endCall(uuid);
      debugPrint('📱 CallKit call ended: $uuid');
    }
    _activeCallUuid = null;
  }

  /// End all active calls (cleanup).
  Future<void> endAllCalls() async {
    if (isCallKitAllowed) {
      await FlutterCallkitIncoming.endAllCalls();
    }
    _activeCallUuid = null;
  }

  /// Check if there are any active calls shown by CallKit.
  Future<List<dynamic>> getActiveCalls() async {
    return await FlutterCallkitIncoming.activeCalls();
  }

  String? get activeCallUuid => _activeCallUuid;
}

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';

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

  /// Callbacks for call actions from the native UI
  Function(String callId)? onAccepted;
  Function(String callId)? onDeclined;
  Function(String callId)? onEnded;

  bool _listenersRegistered = false;

  /// Current active callkit UUID (used for ending/updating the call)
  String? _activeCallUuid;

  /// Initialize listeners for CallKit events.
  /// Call this once at app startup.
  void initialize() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      debugPrint('📱 CallKit event: ${event.event} body=${event.body}');

      switch (event.event) {
        case Event.actionCallAccept:
          final id = _extractId(event.body);
          if (id != null) onAccepted?.call(id);
          break;
        case Event.actionCallDecline:
          final id = _extractId(event.body);
          if (id != null) onDeclined?.call(id);
          break;
        case Event.actionCallEnded:
          final id = _extractId(event.body);
          if (id != null) onEnded?.call(id);
          _activeCallUuid = null;
          break;
        case Event.actionCallTimeout:
          final id = _extractId(event.body);
          if (id != null) onDeclined?.call(id);
          _activeCallUuid = null;
          break;
        default:
          break;
      }
    });
  }

  String? _extractId(Map<String, dynamic>? body) {
    return body?['id']?.toString() ?? body?['extra']?['callId']?.toString();
  }

  /// Show the native incoming call screen.
  /// Returns the UUID used for this call (needed to end it later).
  Future<String> showIncomingCall({
    required String callId,
    required String callerName,
    String? callerAvatar,
    bool isVideo = false,
  }) async {
    // Use callId as the UUID so we can reference it later
    final uuid = callId.isNotEmpty ? callId : const Uuid().v4();
    _activeCallUuid = uuid;

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'BananaTalk',
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
      duration: 45000, // Ring for 45 seconds then timeout
      extra: {'callId': callId},
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

    if (!isCallKitAllowed) {
      debugPrint('📱 CallKit disabled (China/iOS) — skipping native call UI');
      return uuid;
    }

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('📱 CallKit incoming call shown: $uuid ($callerName)');
    return uuid;
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
      appName: 'BananaTalk',
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

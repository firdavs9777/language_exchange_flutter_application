import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Everything a call needs from the device, behind one seam so
/// CallManager can be tested without plugins.
abstract class CallPlatform {
  Future<void> showIncomingCallUi(CallModel call);
  Future<void> endCallUi(CallModel call);
  Future<List<CallKitEntry>> activeCallUis();
  Future<void> startRingtone();
  Future<void> startRingback();
  Future<void> stopTones();
  Future<void> playConnectSound();
  Future<void> playEndSound();
  Future<void> cancelIncomingNotification();
  Future<String> deviceId();
  Future<bool> ensurePermissions({required bool video});
  Future<String> permissionError({required bool video, required bool accepting});
}

class DeviceCallPlatform implements CallPlatform {
  AudioPlayer? _tone;
  AudioPlayer? _sound;

  Future<void> _loop(String asset) async {
    try {
      await _tone?.dispose();
      final player = AudioPlayer();
      _tone = player;
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.one);
      await player.play();
    } catch (e) {
      debugPrint('🔔 tone $asset failed: $e');
    }
  }

  Future<void> _once(String asset) async {
    try {
      await _sound?.dispose();
      final player = AudioPlayer();
      _sound = player;
      await player.setAsset(asset);
      await player.play();
    } catch (e) {
      debugPrint('🔔 sound $asset failed: $e');
    }
  }

  @override
  Future<void> startRingtone() => _loop('assets/sounds/ringtone.m4a');

  @override
  Future<void> startRingback() => _loop('assets/sounds/ringback.m4a');

  @override
  Future<void> stopTones() async {
    final player = _tone;
    _tone = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (e) {
      debugPrint('🔔 stop tones failed: $e');
    }
  }

  @override
  Future<void> playConnectSound() => _once('assets/sounds/call_connect.m4a');

  @override
  Future<void> playEndSound() => _once('assets/sounds/call_end.m4a');

  @override
  Future<void> showIncomingCallUi(CallModel call) async {
    await CallKitService().showIncomingCall(
      callId: call.callId,
      callUuid: call.callUuid,
      callerName: call.userName,
      callerAvatar: call.userProfilePicture,
      callerId: call.userId,
      isVideo: call.callType == CallType.video,
      livekitUrl: call.livekitUrl,
      roomName: call.roomName,
    );
  }

  @override
  Future<void> endCallUi(CallModel call) =>
      CallKitService().endCall(CallKitIds.uuidFor(callId: call.callId, callUuid: call.callUuid));

  @override
  Future<List<CallKitEntry>> activeCallUis() => CallKitService().activeCallEntries();

  @override
  Future<void> cancelIncomingNotification() => NotificationService().cancelCallNotification();

  @override
  Future<String> deviceId() => NotificationService().getDeviceId();

  @override
  Future<bool> ensurePermissions({required bool video}) async {
    final mic = await Permission.microphone.status;
    final cam = video ? await Permission.camera.status : PermissionStatus.granted;
    if (mic.isGranted && cam.isGranted) return true;
    if (mic.isPermanentlyDenied || (video && cam.isPermanentlyDenied)) return false;
    final statuses = await [Permission.microphone, if (video) Permission.camera].request();
    return statuses.values.every((s) => s.isGranted);
  }

  @override
  Future<String> permissionError({required bool video, required bool accepting}) async {
    final mic = await Permission.microphone.status;
    final cam = video ? await Permission.camera.status : PermissionStatus.granted;
    final verb = accepting ? 'answer' : 'make';
    final scope = video ? 'video calls' : 'calls';
    if (video) {
      if (mic.isPermanentlyDenied && cam.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone and camera access in Settings to $verb $scope.';
      }
      if (mic.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone access in Settings to $verb calls.';
      }
      if (cam.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable camera access in Settings to $verb video calls.';
      }
      if (!mic.isGranted) return 'DENIED:Microphone permission is required to $verb calls.';
      return 'DENIED:Camera permission is required to $verb video calls.';
    }
    if (mic.isPermanentlyDenied) {
      return 'PERMANENTLY_DENIED:Please enable microphone access in Settings to $verb calls.';
    }
    return 'DENIED:Microphone permission is required to $verb calls.';
  }
}

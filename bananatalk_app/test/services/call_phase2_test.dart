import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  Future<CallHarness> connectedVoice() async {
    final h = CallHarness();
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    return h;
  }

  test('rejectCall(message:) forwards the message', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.rejectCall(message: 'Later');
    expect(h.api.calls, contains('decline:call-1'));
    expect(h.api.declineMessages['call-1'], 'Later');
  });

  test('a decline whose message the server refuses (400) is sent again without it', () async {
    final h = CallHarness();
    await h.ringIncoming();
    h.api.declineResponder = (message) => message == null
        ? const CallApiResult(ok: true, statusCode: 200)
        : const CallApiResult(ok: false, statusCode: 400);
    await h.manager.rejectCall(message: 'too long for the server');
    await pumpEventQueue();
    expect(h.api.declineLog, [
      (callId: 'call-1', message: 'too long for the server'),
      (callId: 'call-1', message: null),
    ]);
  });

  test('a decline refused for another reason (409) is not retried', () async {
    final h = CallHarness();
    await h.ringIncoming();
    h.api.declineResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    await h.manager.rejectCall(message: 'Later');
    await pumpEventQueue();
    expect(h.api.declineLog.length, 1);
  });

  test('a decline without a message is never retried', () async {
    final h = CallHarness();
    await h.ringIncoming();
    h.api.declineResult = const CallApiResult(ok: false, statusCode: 400);
    await h.manager.rejectCall();
    await pumpEventQueue();
    expect(h.api.declineLog.length, 1);
  });

  test('409 CALLEE_UNAVAILABLE → InitiateStatus.calleeUnavailable, no call left', () async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_UNAVAILABLE');
    expect((await h.startOutgoing()).status, InitiateStatus.calleeUnavailable);
    expect(h.manager.currentCall, isNull);
  });

  test('call:state active+video on a connected call changes the type only', () async {
    final h = await connectedVoice();
    final types = <CallType>[];
    h.manager.onCallTypeChanged = types.add;
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.manager.currentCall!.status, CallStatus.connected);
    expect(types, [CallType.video]);
    expect(h.finishes, isEmpty);
  });

  test('a late call:state active+video never revives an ended or unknown call', () async {
    final h = await connectedVoice();
    final types = <CallType>[];
    h.manager.onCallTypeChanged = types.add;
    await h.state('ended');
    expect(h.manager.currentCall, isNull);
    final opens = h.opened.length;
    await h.manager.handleSocketEvent(
        'call:state', {'callId': 'call-1', 'callUuid': kCallUuid, 'status': 'active', 'type': 'video'});
    await h.manager.handleSocketEvent('call:state', {'callId': 'other', 'status': 'active', 'type': 'video'});
    expect(h.manager.currentCall, isNull);
    expect(types, isEmpty);
    expect(h.opened.length, opens);
    expect(h.finishes, hasLength(1));
  });

  test('upgradeToVideo: camera on, POST /upgrade, type video; refused without permission', () async {
    final h = await connectedVoice();
    expect(await h.manager.upgradeToVideo(), isTrue);
    expect(h.liveKit.cameraCalls, [true]);
    expect(h.api.calls, contains('upgrade:call-1'));
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.manager.isVideoEnabled, isTrue);

    final h2 = await connectedVoice();
    h2.platform.permissionsGranted = false;
    expect(await h2.manager.upgradeToVideo(), isFalse);
    expect(h2.liveKit.cameraCalls, isEmpty);
  });

  test('upgradeToVideo returns false on a non-200 and rolls the camera back', () async {
    final h = await connectedVoice();
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    final types = <CallType>[];
    h.manager.onCallTypeChanged = types.add;
    expect(await h.manager.upgradeToVideo(), isFalse);
    expect(types, [CallType.video, CallType.audio]);
    expect(h.manager.currentCall!.callType, CallType.audio);
    expect(h.manager.isVideoEnabled, isFalse);
    expect(h.liveKit.cameraCalls, [true, false]);
  });

  test('upgradeToVideo is false with no call or while ringing', () async {
    final h = CallHarness();
    expect(await h.manager.upgradeToVideo(), isFalse);
    await h.ringIncoming();
    expect(await h.manager.upgradeToVideo(), isFalse);
  });

  test('upgradeToVideo is false while the call is still connecting', () async {
    final h = CallHarness();
    await h.startOutgoing();
    await h.state('active');
    expect(h.manager.currentCall!.status, CallStatus.connecting);
    expect(await h.manager.upgradeToVideo(), isFalse);
    expect(h.liveKit.cameraCalls, isEmpty);
    expect(h.api.calls.where((c) => c.startsWith('upgrade')), isEmpty);
  });

  test('a second upgradeToVideo while one is in flight does nothing', () async {
    final h = await connectedVoice();
    final first = h.manager.upgradeToVideo();
    final second = await h.manager.upgradeToVideo();
    expect(second, isFalse);
    expect(await first, isTrue);
    expect(h.liveKit.cameraCalls, [true]);
    expect(h.api.calls.where((c) => c.startsWith('upgrade')), hasLength(1));
  });

  test('a local upgrade routes audio to the speaker; a refusal restores the earpiece', () async {
    final h = await connectedVoice();
    expect(h.manager.isSpeakerOn, isFalse);
    expect(await h.manager.upgradeToVideo(), isTrue);
    expect(h.manager.isSpeakerOn, isTrue);
    expect(h.liveKit.speakerCalls, [true]);

    final h2 = await connectedVoice();
    h2.api.upgradeResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    expect(await h2.manager.upgradeToVideo(), isFalse);
    expect(h2.liveKit.speakerCalls, [true, false]);
    expect(h2.manager.isSpeakerOn, isFalse);
  });

  test('a rollback restores a speaker the user had already turned on', () async {
    final h = await connectedVoice();
    await h.manager.setSpeakerOn(true);
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 403);
    expect(await h.manager.upgradeToVideo(), isFalse);
    expect(h.manager.isSpeakerOn, isTrue);
  });

  test('a peer upgrade leaves the audio route alone but keeps the screen on', () async {
    final h = await connectedVoice();
    h.platform.log.clear();
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    expect(h.manager.isSpeakerOn, isFalse, reason: 'the phone may be at the ear; the camera is still off');
    expect(h.liveKit.speakerCalls, isEmpty);
    expect(h.manager.isVideoEnabled, isFalse, reason: 'the local camera stays off');
    expect(h.platform.log, containsAll(['wakelock:on', 'service:start:video']));
  });

  test('peer upgrade in the background: the video call service starts on resume', () async {
    final h = await connectedVoice();
    h.appResumed = false;
    h.platform.log.clear();
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    expect(h.platform.log, isNot(contains('service:start:video')));
    h.appResumed = true;
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.platform.log, contains('service:start:video'));
  });

  test('after a peer upgrade, turning the camera on moves audio to the speaker once', () async {
    final h = await connectedVoice();
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    expect(await h.manager.enableCamera(), isTrue);
    expect(h.manager.isSpeakerOn, isTrue);
    expect(h.liveKit.speakerCalls, [true]);
    h.manager.setVideoEnabled(false);
    await h.manager.setSpeakerOn(false); // user picks the earpiece
    expect(await h.manager.enableCamera(), isTrue);
    expect(h.liveKit.speakerCalls, [true, false], reason: 'a later camera-on keeps the user route');
  });

  test('enableCamera on a call started as video does not touch the route', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.liveKit.onPeerConnected!();
    h.manager.setVideoEnabled(false);
    expect(await h.manager.enableCamera(), isTrue);
    expect(h.liveKit.speakerCalls, isEmpty);
  });

  test('a timed-out upgrade the server applied stays video', () async {
    final h = await connectedVoice();
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 0);
    h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'active', 'type': 'video'});
    expect(await h.manager.upgradeToVideo(), isTrue);
    expect(h.api.calls, contains('get:call-1'));
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.liveKit.cameraCalls, [true]);
  });

  test('a timed-out upgrade the server did not apply rolls back', () async {
    final h = await connectedVoice();
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 503);
    h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'active', 'type': 'audio'});
    expect(await h.manager.upgradeToVideo(), isFalse);
    expect(h.manager.currentCall!.callType, CallType.audio);
    expect(h.liveKit.cameraCalls, [true, false]);
  });

  test('an unknown upgrade outcome (re-check fails too) keeps the optimistic video state', () async {
    final h = await connectedVoice();
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 0);
    h.api.getResult = const CallApiResult(ok: false, statusCode: 0);
    expect(await h.manager.upgradeToVideo(), isTrue);
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.manager.isVideoEnabled, isTrue);
  });
}

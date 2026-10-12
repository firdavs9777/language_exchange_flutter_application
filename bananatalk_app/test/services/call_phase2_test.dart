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
    expect(await h.manager.upgradeToVideo(), isFalse);
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
}

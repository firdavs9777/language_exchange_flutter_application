import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_push_handler.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

Map<String, dynamic> _pushData({String type = 'incoming_call', String callId = 'call-1'}) => {
      'type': type,
      'callId': callId,
      'callUuid': kCallUuid,
      'callerId': 'u-caller',
      'callerName': 'Ada',
      'callType': 'audio',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foreground incoming_call push is handled (not dropped) and deduped with the socket', () async {
    final h = CallHarness();
    expect(await handleCallPush(_pushData(), manager: h.manager), isTrue);
    await h.manager.handleSocketEvent('call:incoming', CallHarness.incomingPayload());
    expect(h.opened, ['incoming:call-1']);
    expect(await handleCallPush({'type': 'chat_message'}, manager: h.manager), isFalse);
  });

  test('call_cancelled for the ringing call ends it and its CallKit UI', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await handleCallPush(_pushData(type: 'call_cancelled'), manager: h.manager);
    expect(h.finishes.single.reason, CallExitReason.remoteState);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
  });

  test('call_cancelled that overtook the invite: CallKit ended, the late invite ignored', () async {
    final h = CallHarness();
    await handleCallPush(_pushData(type: 'call_cancelled', callId: 'call-9'), manager: h.manager);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
    await handleCallPush(_pushData(callId: 'call-9'), manager: h.manager);
    expect(h.manager.currentCall, isNull);
    expect(h.opened, isEmpty);
  });

  test('call_cancelled does not end a call this device is already answering', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.acceptCall();
    await handleCallPush(_pushData(type: 'call_cancelled'), manager: h.manager);
    expect(h.finishes, isEmpty);
    expect(h.manager.currentCall!.status, CallStatus.connecting);
  });

  test('tapping an old incoming-call notification opens the chat when the call is over', () async {
    final h = CallHarness();
    h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'missed'});
    expect(await h.manager.resolveIncomingTap(_pushData()), IncomingTapAction.openChat);
    expect(h.manager.currentCall, isNull);
    expect(h.opened, isEmpty);
  });

  test('tapping a still-ringing notification shows the incoming screen', () async {
    final h = CallHarness();
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(await h.manager.resolveIncomingTap(_pushData()), IncomingTapAction.showCall);
    expect(h.opened, ['incoming:call-1']);
  });

  test('resume: a call ringing for me on the server shows the incoming UI', () async {
    final h = CallHarness();
    h.api.currentResult = const CallApiResult(ok: true, statusCode: 200, data: {
      'call': {
        'id': 'call-1', 'callUuid': kCallUuid, 'type': 'video', 'status': 'ringing', 'direction': 'in',
        'otherParty': {'id': 'u-caller', 'name': 'Ada', 'avatar': null}, 'roomName': 'call:call-1',
      },
    });
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.opened, ['incoming:call-1']);
  });

  test('resume: nothing live on the server ends a stale local ring', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.recoverCallState();
    expect(h.finishes.single.reason, CallExitReason.remoteState);
  });

  test('cold start / resume: an active call is rejoined with the fresh token', () async {
    final h = CallHarness();
    h.api.currentResult = const CallApiResult(ok: true, statusCode: 200, data: {
      'call': {
        'id': 'call-1', 'callUuid': kCallUuid, 'type': 'audio', 'status': 'active', 'direction': 'out',
        'otherParty': {'id': 'u2', 'name': 'Bo', 'avatar': null}, 'roomName': 'call:call-1',
      },
      'token': 'tok-rejoin', 'url': 'wss://lk.test',
    });
    await h.manager.recoverCallState();
    expect(h.liveKit.connects, 1);
    expect(h.opened, ['active:call-1']);
    expect(h.manager.currentCall!.direction, CallDirection.outgoing);
  });

  test('call_cancelled while this device is accepting does not end the call', () async {
    final h = CallHarness();
    await h.ringIncoming();
    h.platform.permissionsGranted = true;
    final accepting = h.manager.acceptCall(); // accept request in flight
    await handleCallPush(_pushData(type: 'call_cancelled'), manager: h.manager);
    await accepting;
    expect(h.finishes, isEmpty);
  });

  test('a tapped notification without caller details is filled from GET /calls/:id', () async {
    final h = CallHarness();
    h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {
      'status': 'ringing',
      'type': 'video',
      'callUuid': kCallUuid,
      'initiator': 'u-caller',
      'participants': [
        {'_id': 'u-caller', 'name': 'Ada', 'images': ['https://img/ada.jpg']},
        {'_id': 'u-me', 'name': 'Me', 'images': []},
      ],
    });
    final action = await h.manager.resolveIncomingTap({'type': 'incoming_call', 'callId': 'call-1'});
    expect(action, IncomingTapAction.showCall);
    final call = h.manager.currentCall!;
    expect(call.userName, 'Ada');
    expect(call.userId, 'u-caller');
    expect(call.userProfilePicture, 'https://img/ada.jpg');
    expect(call.callType, CallType.video);
    expect(call.callUuid, kCallUuid);
  });
}

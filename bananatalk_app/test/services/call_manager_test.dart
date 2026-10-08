import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a call:state for another callId is ignored', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.state('ended', callId: 'another-call', outcome: 'completed');
    expect(h.manager.currentCall?.callId, 'call-1');
    expect(h.finishes, isEmpty);
  });

  test('outgoing: accepted then ended via call:state → one clean finish', () async {
    final h = CallHarness();
    final r = await h.startOutgoing();
    expect(r.status, InitiateStatus.started);
    expect(h.manager.currentCall!.callUuid, kCallUuid);
    expect(h.platform.log, contains('ringback'));
    await h.state('active');
    expect(h.manager.currentCall!.status, CallStatus.connecting);
    final media = h.liveKit;
    await h.state('ended', outcome: 'completed', duration: 42);
    expect(h.finishes.single.reason, CallExitReason.remoteState);
    expect(h.finishes.single.call.duration, 42);
    expect(h.manager.currentCall, isNull);
    expect(media.disconnects, 1);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
    expect(h.closes, 1);
  });

  group('every exit path runs _finish exactly once, even when another exit follows', () {
    // (run, closes expected right after the exit + a late call:state).
    // The caller's "No answer" / "Declined" banner holds the screen for
    // 1.5 s, so those two close nothing yet; the trailing End then closes.
    final scenarios = <String, (Future<void> Function(CallHarness h), int)>{
      'local hang-up': ((h) async {
        await h.startOutgoing();
        await h.manager.endCall();
      }, 1),
      'decline': ((h) async {
        await h.ringIncoming();
        await h.manager.rejectCall();
      }, 1),
      'remote no answer': ((h) async {
        await h.startOutgoing();
        await h.state('missed', outcome: 'no_answer');
      }, 0),
      'remote declined': ((h) async {
        await h.startOutgoing();
        await h.state('rejected', outcome: 'declined');
      }, 0),
      'room deleted': ((h) async {
        await h.startOutgoing();
        h.liveKit.onLocalDisconnected!(lk.DisconnectReason.roomDeleted);
        await pumpEventQueue();
      }, 1),
      'LiveKit connect failure': ((h) async {
        h.nextConnectError = StateError('no network');
        await h.startOutgoing();
      }, 1),
      '409 on accept': ((h) async {
        h.api.acceptResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
        await h.ringIncoming();
        await h.manager.acceptCall();
      }, 1),
    };
    scenarios.forEach((name, scenario) {
      final (run, closesAfterExit) = scenario;
      test(name, () async {
        final h = CallHarness();
        await run(h);
        await h.state('ended', outcome: 'completed');
        await pumpEventQueue();
        expect(h.finishes, hasLength(1));
        expect(h.manager.currentCall, isNull);
        expect(h.closes, closesAfterExit,
            reason: 'the late call:state must not close (or finish) again');
        await h.manager.endCall();
        await pumpEventQueue();
        expect(h.finishes, hasLength(1));
        expect(h.closes, closesAfterExit + 1, reason: 'End always closes the call screens');
        // Teardown ran once for the call: CallKit UI by callUuid, tones, media.
        expect(h.platform.log.where((l) => l == 'endUi:$kCallUuid'), hasLength(1));
        expect(h.platform.log.where((l) => l.startsWith('endUi:')), hasLength(1));
        expect(h.platform.log, contains('stopTones'));
        expect(h.liveKits.fold<int>(0, (n, m) => n + m.disconnects), 1);
      });
    });
  });

  test('End with no current call still closes the call screens', () async {
    final h = CallHarness();
    await h.manager.endCall();
    expect(h.closes, 1);
    expect(h.finishes, isEmpty);
  });

  test('409 CALL_STATE on accept dismisses silently and reports the device id', () async {
    final h = CallHarness();
    final errors = <String>[];
    h.manager.onCallError = errors.add;
    h.api.acceptResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    await h.ringIncoming();
    await h.manager.acceptCall();
    expect(h.finishes.single.reason, CallExitReason.acceptConflict);
    expect(errors, isEmpty);
    expect(h.api.deviceIds['accept'], 'device-1');
  });

  test('answered on another device: this device stops ringing', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.state('active');
    expect(h.finishes.single.reason, CallExitReason.answeredElsewhere);
  });

  test('the caller sees the outcome for 1.5 s before the screen closes', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('missed', outcome: 'no_answer');
      async.flushMicrotasks();
      expect(h.finishes.single.outcome, CallOutcome.noAnswer);
      expect(h.closes, 0);
      async.elapse(const Duration(milliseconds: 1499));
      expect(h.closes, 0);
      async.elapse(const Duration(milliseconds: 2));
      expect(h.closes, 1);
    });
  });

  test('the 5-minute free cap is gone: the client never ends a connected call', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('active');
      async.flushMicrotasks();
      h.liveKit.onPeerConnected!();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 6));
      expect(h.finishes, isEmpty);
      expect(h.api.calls.where((c) => c.startsWith('end:')), isEmpty);
    });
  });

  test('ring safety net: no call:state for 50 s → GET /calls/:id decides', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'missed', 'outcome': 'no_answer'});
      h.startOutgoing();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 49));
      expect(h.finishes, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(h.api.calls, contains('get:call-1'));
      expect(h.finishes.single.outcome, CallOutcome.noAnswer);
    });
  });

  test('socket + push for the same call → one incoming screen, one ringtone', () async {
    final h = CallHarness();
    await h.manager.handleIncoming(CallHarness.incomingPayload(), source: IncomingSource.socket);
    await h.manager.handleIncoming({
      'type': 'incoming_call', 'callId': 'call-1', 'callUuid': kCallUuid, 'callerName': 'Ada', 'callType': 'audio',
    }, source: IncomingSource.push);
    expect(h.opened, ['incoming:call-1']);
    expect(h.platform.log.where((l) => l == 'ringtone'), hasLength(1));
  });

  test('CALLEE_BUSY: calleeBusy result, no call, LiveKit untouched', () async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_BUSY');
    final r = await h.startOutgoing();
    expect(r.status, InitiateStatus.calleeBusy);
    expect(h.manager.currentCall, isNull);
    expect(h.liveKits, hasLength(1), reason: 'only the idle instance from construction');
  });

  test('hanging up while /initiate is in flight cancels the call the server created', () async {
    final h = CallHarness();
    h.api.initiateGate = Completer<void>();
    final pending = h.startOutgoing();
    await pumpEventQueue();
    expect(h.api.calls, ['initiate:u-callee:audio']);
    await h.manager.endCall();
    h.api.initiateGate!.complete();
    final r = await pending;
    expect(r.status, InitiateStatus.failed);
    expect(h.api.calls, contains('end:call-1'));
  });

  test('the banner close is taken over by End: no second close later', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('missed', outcome: 'no_answer');
      async.flushMicrotasks();
      h.manager.endCall();
      async.flushMicrotasks();
      expect(h.closes, 1);
      async.elapse(const Duration(seconds: 2));
      expect(h.closes, 1);
    });
  });

  group('CallKit callbacks carry the CallKit UUID (R14)', () {
    test('cold start: accept with a v5-fallback uuid uses extra.callId on the server', () async {
      final h = CallHarness();
      final callKitId = CallKitIds.uuidFor(callId: 'call-1').toUpperCase();
      await h.manager.handleCallKitAccept(callKitId, {
        'callId': 'call-1',
        'callerName': 'Ada',
        'callType': 'audio',
      });
      expect(h.api.calls, ['accept:call-1']);
      expect(h.api.calls.where((c) => c.contains(callKitId)), isEmpty);
      expect(h.manager.currentCall?.callId, 'call-1');
      expect(h.opened, ['active:call-1']);
    });

    test('cold start without extra.callId does nothing', () async {
      final h = CallHarness();
      await h.manager.handleCallKitAccept(kCallUuid, const {});
      await h.manager.handleCallKitAccept(kCallUuid, null);
      expect(h.api.calls, isEmpty);
      expect(h.manager.currentCall, isNull);
    });

    test('an uppercase CallKit id matches the ringing call (Review Focus 1)', () async {
      final h = CallHarness();
      await h.ringIncoming();
      await h.manager.handleCallKitAccept(kCallUuid.toUpperCase(), null);
      expect(h.api.calls, ['accept:call-1']);
      expect(h.opened, contains('active:call-1'));
    });

    test('decline by uppercase CallKit id declines the server call id', () async {
      final h = CallHarness();
      await h.ringIncoming();
      await h.manager.handleCallKitDecline(kCallUuid.toUpperCase(), null);
      expect(h.api.calls, ['decline:call-1']);
      expect(h.finishes.single.reason, CallExitReason.declined);
    });

    test('decline with no current call declines extra.callId, never the CallKit id', () async {
      final h = CallHarness();
      await h.manager.handleCallKitDecline(kCallUuid.toUpperCase(), {'callId': 'call-9'});
      await pumpEventQueue();
      expect(h.api.calls, ['decline:call-9']);
    });

    test('ended for a different CallKit call leaves the current call alone', () async {
      final h = CallHarness();
      await h.ringIncoming();
      await h.manager.handleCallKitEnded('00000000-0000-4000-8000-000000000000', null);
      expect(h.manager.currentCall?.callId, 'call-1');
      await h.manager.handleCallKitEnded(kCallUuid.toUpperCase(), null);
      expect(h.manager.currentCall, isNull);
      expect(h.api.calls, contains('end:call-1'));
    });
  });

  test('call:state matches the call id case-insensitively', () async {
    final h = CallHarness();
    await h.manager.handleIncoming(CallHarness.incomingPayload(callId: 'abcdef0123456789abcdef01'));
    await h.state('ended', callId: 'ABCDEF0123456789ABCDEF01', outcome: 'completed');
    expect(h.finishes, hasLength(1));
  });

  test('403 CONVERSATION_START_LIMIT on initiate: one error with the server message, no call', () async {
    final h = CallHarness();
    final errors = <String>[];
    h.manager.onCallError = errors.add;
    h.api.initiateResult = const CallApiResult(
      ok: false,
      statusCode: 403,
      errorCode: 'CONVERSATION_START_LIMIT',
      error: 'You have started the most conversations you can today.',
    );
    final r = await h.startOutgoing();
    expect(r.status, InitiateStatus.failed);
    expect(r.error, 'You have started the most conversations you can today.');
    expect(errors, ['You have started the most conversations you can today.']);
    expect(h.manager.currentCall, isNull);
    expect(h.liveKits, hasLength(1));
  });

  group('LiveKit connect fails after the call already finished', () {
    test('outgoing: no error, no extra /end, one finish, the banner still closes once', () {
      fakeAsync((async) {
        final h = CallHarness();
        final errors = <String>[];
        h.manager.onCallError = errors.add;
        final gate = Completer<void>();
        h.nextConnectGate = gate;
        h.nextConnectError = StateError('disconnected');
        InitiateResult? result;
        h.startOutgoing().then((r) => result = r);
        async.flushMicrotasks();
        h.state('missed', outcome: 'no_answer');
        async.flushMicrotasks();
        gate.complete();
        async.flushMicrotasks();
        expect(result?.status, InitiateStatus.failed);
        expect(errors, isEmpty);
        expect(h.finishes, hasLength(1));
        expect(h.finishes.single.outcome, CallOutcome.noAnswer);
        expect(h.api.calls.where((c) => c.startsWith('end:')), isEmpty);
        expect(h.closes, 0, reason: 'the outcome banner is still up');
        async.elapse(const Duration(seconds: 2));
        expect(h.closes, 1);
      });
    });

    test('accepting: no error, no extra /end, one finish', () async {
      final h = CallHarness();
      final errors = <String>[];
      h.manager.onCallError = errors.add;
      await h.ringIncoming();
      final gate = Completer<void>();
      h.nextConnectGate = gate;
      h.nextConnectError = StateError('disconnected');
      final accepting = h.manager.acceptCall();
      await pumpEventQueue();
      await h.state('ended', outcome: 'completed');
      gate.complete();
      await accepting;
      await pumpEventQueue();
      expect(errors, isEmpty);
      expect(h.finishes, hasLength(1));
      expect(h.closes, 1);
      expect(h.api.calls.where((c) => c.startsWith('end:')), isEmpty);
    });
  });

  test('accepted mid-connect: no ringback and no 50 s safety check', () {
    fakeAsync((async) {
      final h = CallHarness();
      final gate = Completer<void>();
      h.nextConnectGate = gate;
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('active');
      async.flushMicrotasks();
      gate.complete();
      async.flushMicrotasks();
      expect(h.platform.log, isNot(contains('ringback')));
      async.elapse(const Duration(seconds: 60));
      expect(h.api.calls.where((c) => c.startsWith('get:')), isEmpty);
      expect(h.manager.currentCall?.status, CallStatus.connecting);
    });
  });

  test('a native CallKit ring timeout dismisses locally and posts nothing', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.handleCallKitTimeout(kCallUuid.toUpperCase(), null);
    expect(h.finishes, hasLength(1));
    expect(h.manager.currentCall, isNull);
    expect(h.api.calls, isEmpty, reason: 'the server timer owns the outcome');
    expect(h.closes, 1);
  });

  test('a CallKit timeout for another call is ignored', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.handleCallKitTimeout('00000000-0000-4000-8000-000000000000', null);
    expect(h.manager.currentCall?.callId, 'call-1');
    expect(h.finishes, isEmpty);
  });
}

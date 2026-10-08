import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CallKit id is the lowercase callUuid; extra carries ids and caller, never a token', () {
    final p = CallKitService.buildIncomingParams(
      callId: 'call-1',
      callUuid: kCallUuid.toUpperCase(),
      callerName: 'Ada',
      callerAvatar: 'https://cdn.test/a.jpg',
      callerId: 'u-caller',
      isVideo: true,
      livekitUrl: 'wss://lk.test',
      roomName: 'call:call-1',
    );
    expect(p.id, kCallUuid);
    expect(p.type, 1);
    expect(p.duration, 50000);
    expect(p.extra, {
      'callId': 'call-1',
      'callUuid': kCallUuid,
      'callType': 'video',
      'callerName': 'Ada',
      'callerAvatar': 'https://cdn.test/a.jpg',
      'callerId': 'u-caller',
      'livekitUrl': 'wss://lk.test',
      'roomName': 'call:call-1',
    });
  });

  test('Review focus 1: cold start finds an accepted CallKit call reported in UPPERCASE and joins it', () async {
    final h = CallHarness();
    h.platform.activeEntries = [
      CallKitEntry(uuid: kCallUuid.toUpperCase(), accepted: true, extra: {
        'callId': 'call-1', 'callUuid': kCallUuid, 'callerId': 'u-caller', 'callerName': 'Ada', 'callType': 'audio',
      }),
    ];
    await h.manager.reconcileCallKitOnColdStart();
    expect(h.api.calls, ['accept:call-1']);
    expect(h.opened, ['active:call-1']);
  });

  test('cold start ignores CallKit calls that were not accepted', () async {
    final h = CallHarness();
    h.platform.activeEntries = const [CallKitEntry(uuid: kCallUuid, accepted: false, extra: {'callId': 'call-1'})];
    await h.manager.reconcileCallKitOnColdStart();
    expect(h.api.calls, isEmpty);
  });

  test('a CallKit accept with an uppercase id matches the ringing call', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.handleCallKitAccept(kCallUuid.toUpperCase(), null);
    expect(h.api.calls, ['accept:call-1']);
  });

  test('cold start skips a stale accepted entry that fails to accept and joins the real one', () async {
    final h = CallHarness();
    const staleUuid = '11111111-2222-4333-8444-555555555555';
    h.api.acceptResultFor['call-0'] =
        const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    h.platform.activeEntries = const [
      CallKitEntry(uuid: staleUuid, accepted: true, extra: {
        'callId': 'call-0', 'callUuid': staleUuid, 'callerId': 'u-old', 'callerName': 'Old', 'callType': 'audio',
      }),
      CallKitEntry(uuid: kCallUuid, accepted: true, extra: {
        'callId': 'call-1', 'callUuid': kCallUuid, 'callerId': 'u-caller', 'callerName': 'Ada', 'callType': 'audio',
      }),
    ];
    await h.manager.reconcileCallKitOnColdStart();
    expect(h.api.calls, ['accept:call-0', 'accept:call-1']);
    expect(h.opened, ['active:call-1']);
    expect(h.manager.currentCall!.callId, 'call-1');
    expect(h.manager.currentCall!.status, CallStatus.connecting);
  });

  group('one ring UI per call', () {
    test('the native ring UI already shows the call: no in-app screen, no Dart ringtone', () async {
      final h = CallHarness();
      h.platform.activeEntries = [
        CallKitEntry(uuid: kCallUuid.toUpperCase(), accepted: false, extra: const {'callId': 'call-1'}),
      ];
      await h.ringIncoming();
      expect(h.manager.currentCall!.status, CallStatus.ringing);
      expect(h.opened, isEmpty);
      expect(h.platform.log, isNot(contains('ringtone')));
      // A later tap / recovery for the same call does not add the in-app screen.
      await h.manager.resolveIncomingTap({'callId': 'call-1'});
      expect(h.opened, isEmpty);
    });

    test('the native ring UI appears after the in-app screen: the in-app ring closes', () async {
      final h = CallHarness();
      await h.ringIncoming();
      expect(h.opened, ['incoming:call-1']);
      final closesBefore = h.closes;
      h.platform.log.clear();
      await h.manager.handleCallKitIncomingShown(kCallUuid.toUpperCase(), const {'callId': 'call-1'});
      expect(h.closes, closesBefore + 1);
      expect(h.platform.log, contains('stopTones'));
      expect(h.manager.currentCall!.status, CallStatus.ringing);
      // Answered from the native UI from here on.
      await h.manager.handleCallKitAccept(kCallUuid.toUpperCase(), const {'callId': 'call-1'});
      expect(h.api.calls, ['accept:call-1']);
      expect(h.opened, ['incoming:call-1', 'active:call-1']);
    });

    test('in-app accept dismisses the native ring; its echoed decline / ended is ignored', () async {
      final h = CallHarness();
      await h.ringIncoming();
      // The native ring showed meanwhile (e.g. Android, backgrounded during the ring).
      h.platform.activeEntries = const [CallKitEntry(uuid: kCallUuid, accepted: false, extra: {'callId': 'call-1'})];
      h.platform.log.clear();
      await h.manager.acceptCall();
      await pumpEventQueue();
      expect(h.platform.log.where((l) => l == 'endUi:$kCallUuid'), hasLength(1));
      expect(h.manager.currentCall!.status, CallStatus.connecting);
      await h.manager.handleCallKitDecline(kCallUuid.toUpperCase(), const {'callId': 'call-1'});
      await h.manager.handleCallKitEnded(kCallUuid.toUpperCase(), const {'callId': 'call-1'});
      expect(h.finishes, isEmpty);
      expect(h.api.calls, ['accept:call-1']);
      expect(h.manager.currentCall!.status, CallStatus.connecting);
    });

    test('an echoed native decline while the in-app accept is in flight is ignored', () async {
      final h = CallHarness();
      await h.ringIncoming();
      h.api.acceptGate = Completer<void>();
      final accepting = h.manager.acceptCall();
      await pumpEventQueue();
      await h.manager.handleCallKitDecline(kCallUuid, const {'callId': 'call-1'});
      h.api.acceptGate!.complete();
      await accepting;
      expect(h.api.calls, ['accept:call-1']);
      expect(h.finishes, isEmpty);
      expect(h.manager.currentCall!.status, CallStatus.connecting);
    });

    test('a leftover native decline for a call accepted here never ends it (no finish, no POST)', () async {
      final h = CallHarness();
      await h.ringIncoming();
      await h.manager.handleCallKitAccept(kCallUuid, const {'callId': 'call-1'});
      expect(h.manager.currentCall!.status, CallStatus.connecting);
      await h.manager.handleCallKitDecline(kCallUuid, const {'callId': 'call-1'});
      expect(h.finishes, isEmpty);
      expect(h.api.calls, ['accept:call-1']);
    });

    test('hanging up from the native UI still ends a call answered there', () async {
      final h = CallHarness();
      await h.ringIncoming();
      await h.manager.handleCallKitAccept(kCallUuid, const {'callId': 'call-1'});
      await h.manager.handleCallKitEnded(kCallUuid, const {'callId': 'call-1'});
      expect(h.finishes.single.reason, CallExitReason.localHangUp);
      expect(h.api.calls, ['accept:call-1', 'end:call-1']);
    });
  });

  group('token registration declares call_cancel and the real device id', () {
    late String originalBaseUrl;
    setUp(() {
      originalBaseUrl = Endpoints.baseURL;
      Endpoints.baseURL = 'http://api.test/api/v1/';
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
    });
    tearDown(() => Endpoints.baseURL = originalBaseUrl);

    test('VoIP and FCM', () async {
      final bodies = <String, dynamic>{};
      await http.runWithClient(() async {
        final api = NotificationApiClient();
        await api.registerVoipToken('voip-tok', 'device-xyz');
        await api.registerToken('fcm-tok', 'android', 'device-xyz');
      }, () => MockClient((req) async {
        bodies[req.url.path.split('/').last] = jsonDecode(req.body);
        return http.Response(jsonEncode({'success': true}), 200);
      }));
      expect(bodies['register-voip-token'], {
        'voipToken': 'voip-tok', 'deviceId': 'device-xyz', 'capabilities': ['call_cancel'],
      });
      expect(bodies['register-token']['capabilities'], ['call_cancel']);
    });
  });
}

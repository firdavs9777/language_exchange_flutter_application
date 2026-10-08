import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
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

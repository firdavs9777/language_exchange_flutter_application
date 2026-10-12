import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String originalBaseUrl;

  setUp(() {
    originalBaseUrl = Endpoints.baseURL;
    Endpoints.baseURL = 'http://api.test/api/v1/';
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    ApiClient().clearTokenCache();
  });
  tearDown(() => Endpoints.baseURL = originalBaseUrl);

  test('accept: sends deviceId, maps 409 CALL_STATE to isCallStateConflict', () async {
    final seen = <http.Request>[];
    final result = await http.runWithClient(
      () => RestCallApi().accept('c1', deviceId: 'dev-1'),
      () => MockClient((req) async {
        seen.add(req);
        return http.Response(
          jsonEncode({'success': false, 'error': 'Call already active', 'code': 'CALL_STATE', 'status': 'active'}),
          409,
        );
      }),
    );
    expect(seen.single.url.toString(), 'http://api.test/api/v1/calls/c1/accept');
    expect(jsonDecode(seen.single.body), {'deviceId': 'dev-1'});
    expect(result.ok, isFalse);
    expect(result.isCallStateConflict, isTrue);
  });

  test('initiate: 409 CALLEE_BUSY and 200 data map', () async {
    final busy = await http.runWithClient(
      () => RestCallApi().initiate(receiverId: 'u2', type: CallType.video),
      () => MockClient((req) async => http.Response(
          jsonEncode({'success': false, 'error': 'busy', 'code': 'CALLEE_BUSY'}), 409)),
    );
    expect(busy.isCalleeBusy, isTrue);

    final ok = await http.runWithClient(
      () => RestCallApi().initiate(receiverId: 'u2', type: CallType.audio),
      () => MockClient((req) async {
        expect(jsonDecode(req.body), {'receiverId': 'u2', 'type': 'audio'});
        return http.Response(jsonEncode({
          'success': true,
          'data': {'call': {'_id': 'c9', 'callUuid': 'u-9'}, 'token': 't', 'url': 'wss://x', 'roomName': 'call:c9'},
        }), 200);
      }),
    );
    expect(ok.ok, isTrue);
    expect((ok.data['call'] as Map)['callUuid'], 'u-9');
  });

  test('initiate: 403 CONVERSATION_START_LIMIT keeps the server message and skips the global 403 toast', () async {
    const message =
        'You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want.';
    final toasts = <String>[];
    final client = ApiClient();
    final previous = client.onAuthorizationError;
    client.onAuthorizationError = toasts.add;
    addTearDown(() => client.onAuthorizationError = previous);

    final capped = await http.runWithClient(
      () => RestCallApi().initiate(receiverId: 'u2', type: CallType.audio),
      () => MockClient((req) async => http.Response(
          jsonEncode({'success': false, 'error': message, 'code': 'CONVERSATION_START_LIMIT'}), 403)),
    );
    expect(capped.ok, isFalse);
    expect(capped.statusCode, 403);
    expect(capped.errorCode, 'CONVERSATION_START_LIMIT');
    expect(capped.error, message);
    expect(toasts, isEmpty, reason: 'the call UI shows this message once itself');

    // Any other 403 still raises the global permission toast.
    await http.runWithClient(
      () => RestCallApi().accept('c1'),
      () => MockClient((req) async =>
          http.Response(jsonEncode({'success': false, 'error': 'Not a participant'}), 403)),
    );
    expect(toasts, hasLength(1));
  });

  test('Review focus 1: CallKit ids compare case-insensitively; uuidFor prefers callUuid', () {
    expect(CallKitIds.same('6F1C2B8E-3C1D-4A8E-9B7F-0A1B2C3D4E5F', '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f'), isTrue);
    expect(CallKitIds.same(null, 'x'), isFalse);
    expect(CallKitIds.same('', ''), isFalse);
    expect(CallKitIds.uuidFor(callId: 'abc', callUuid: 'AB-CD'), 'ab-cd');
    final derived = CallKitIds.uuidFor(callId: '0123456789abcdef01234567');
    expect(derived, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(CallKitIds.uuidFor(callId: '0123456789abcdef01234567'), derived, reason: 'deterministic');
  });

  test('CallKitEntry reads both plugin shapes (iOS "accepted", Android "isAccepted")', () {
    final ios = CallKitEntry.fromPlugin({'id': 'U-1', 'accepted': true, 'extra': {'callId': 'c1'}});
    expect(ios.accepted, isTrue);
    expect(ios.callId, 'c1');
    final android = CallKitEntry.fromPlugin({'id': 'u-2', 'isAccepted': false});
    expect(android.accepted, isFalse);
    expect(android.callId, isNull);
  });

  test('CallModel reads callUuid and the FCM callerAvatar alias', () {
    final m = CallModel.fromJson({
      'callId': 'c1', 'callUuid': 'u-1', 'callerId': 'u2', 'callerName': 'Ada',
      'callerAvatar': 'https://cdn.test/a.jpg', 'callType': 'video',
    }, CallDirection.incoming);
    expect(m.callUuid, 'u-1');
    expect(m.userProfilePicture, 'https://cdn.test/a.jpg');
    expect(m.copyWith(status: CallStatus.connecting).callUuid, 'u-1');
  });

  test('decline sends a trimmed message; upgrade posts; CALLEE_UNAVAILABLE is recognised', () async {
    final seen = <http.Request>[];
    Future<CallApiResult> send(Future<CallApiResult> Function() body, {int status = 200, Map<String, dynamic>? json}) =>
        http.runWithClient(body, () => MockClient((req) async {
              seen.add(req);
              return http.Response(jsonEncode(json ?? {'success': true, 'data': {}}), status);
            }));
    await send(() => RestCallApi().decline('c1', deviceId: 'd', message: '  Later  '));
    expect(jsonDecode(seen.last.body), {'deviceId': 'd', 'message': 'Later'});
    await send(() => RestCallApi().upgrade('c1'));
    expect(seen.last.url.toString(), 'http://api.test/api/v1/calls/c1/upgrade');
    final r = await send(() => RestCallApi().initiate(receiverId: 'u', type: CallType.audio),
        status: 409, json: {'success': false, 'error': "Bo isn't taking calls right now", 'code': 'CALLEE_UNAVAILABLE'});
    expect(r.isCalleeUnavailable, isTrue);
  });

  test('upgrade fixture: real backend shapes (200 idempotent, 409 CALL_STATE, 404, 403)', () async {
    Future<CallApiResult> upgrade(int status, Map<String, dynamic> json) => http.runWithClient(
        () => RestCallApi().upgrade('c1'), () => MockClient((req) async => http.Response(jsonEncode(json), status)));
    final ok = await upgrade(200, {
      'success': true,
      'data': {'call': {'_id': 'c1', 'type': 'video', 'status': 'active'}},
    });
    expect(ok.ok, isTrue);
    expect(ok.statusCode, 200);
    expect((ok.data['call'] as Map)['type'], 'video');
    final ended = await upgrade(409, {'success': false, 'error': 'Call already ended', 'code': 'CALL_STATE', 'status': 'ended'});
    expect(ended.ok, isFalse);
    expect(ended.isCallStateConflict, isTrue);
    expect((await upgrade(404, {'success': false, 'error': 'Call not found'})).ok, isFalse);
    expect((await upgrade(403, {'success': false, 'error': 'Not authorized to change this call'})).ok, isFalse);
  });
}

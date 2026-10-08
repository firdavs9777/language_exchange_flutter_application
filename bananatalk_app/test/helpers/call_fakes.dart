import 'dart:async';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_platform.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/call_livekit_manager.dart';
import 'package:bananatalk_app/services/call_manager.dart';

const kCallUuid = '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f';

class FakeCallApi implements CallApi {
  final List<String> calls = [];
  final Map<String, String?> deviceIds = {};
  Completer<void>? initiateGate;
  Completer<void>? currentGate;

  CallApiResult initiateResult = const CallApiResult(ok: true, statusCode: 200, data: {
    'call': {'_id': 'call-1', 'callUuid': kCallUuid, 'type': 'audio'},
    'token': 'tok-caller',
    'url': 'wss://lk.test',
    'roomName': 'call:call-1',
  });
  CallApiResult acceptResult = const CallApiResult(ok: true, statusCode: 200, data: {
    'token': 'tok-receiver',
    'url': 'wss://lk.test',
    'roomName': 'call:call-1',
  });
  CallApiResult declineResult = const CallApiResult(ok: true, statusCode: 200);
  CallApiResult endResult = const CallApiResult(ok: true, statusCode: 200);
  CallApiResult currentResult =
      const CallApiResult(ok: true, statusCode: 200, data: {'call': null});
  CallApiResult getResult =
      const CallApiResult(ok: true, statusCode: 200, data: {'status': 'ringing'});

  @override
  Future<CallApiResult> initiate({required String receiverId, required CallType type}) async {
    calls.add('initiate:$receiverId:${type.name}');
    if (initiateGate != null) await initiateGate!.future;
    return initiateResult;
  }

  @override
  Future<CallApiResult> accept(String callId, {String? deviceId}) async {
    calls.add('accept:$callId');
    deviceIds['accept'] = deviceId;
    return acceptResult;
  }

  @override
  Future<CallApiResult> decline(String callId, {String? deviceId}) async {
    calls.add('decline:$callId');
    deviceIds['decline'] = deviceId;
    return declineResult;
  }

  @override
  Future<CallApiResult> end(String callId) async {
    calls.add('end:$callId');
    return endResult;
  }

  @override
  Future<CallApiResult> current() async {
    calls.add('current');
    if (currentGate != null) await currentGate!.future;
    return currentResult;
  }

  @override
  Future<CallApiResult> get(String callId) async {
    calls.add('get:$callId');
    return getResult;
  }
}

class FakeCallPlatform implements CallPlatform {
  final List<String> log = [];
  List<CallKitEntry> activeEntries = const [];
  bool permissionsGranted = true;

  @override
  Future<void> showIncomingCallUi(CallModel call) async => log.add('showUi:${call.callId}');
  @override
  Future<void> endCallUi(CallModel call) async => log.add('endUi:${call.callUuid ?? call.callId}');
  @override
  Future<List<CallKitEntry>> activeCallUis() async => activeEntries;
  @override
  Future<void> startRingtone() async => log.add('ringtone');
  @override
  Future<void> startRingback() async => log.add('ringback');
  @override
  Future<void> stopTones() async => log.add('stopTones');
  @override
  Future<void> playConnectSound() async => log.add('connectSound');
  @override
  Future<void> playEndSound() async => log.add('endSound');
  @override
  Future<void> cancelIncomingNotification() async => log.add('cancelNotification');
  @override
  Future<String> deviceId() async => 'device-1';
  @override
  Future<bool> ensurePermissions({required bool video}) async => permissionsGranted;
  @override
  Future<String> permissionError({required bool video, required bool accepting}) async =>
      'DENIED:test';
}

class FakeLiveKit extends CallLiveKitManager {
  int connects = 0;
  int disconnects = 0;
  Object? connectError;
  Completer<void>? connectGate;
  final List<bool> cameraCalls = [];

  @override
  Future<void> connect({required String url, required String token, required CallType type}) async {
    connects++;
    if (connectGate != null) await connectGate!.future;
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> setCameraEnabled(bool enabled) async => cameraCalls.add(enabled);
}

/// A CallManager wired to fakes, recording everything it does.
class CallHarness {
  CallHarness({
    void Function()? closeCallScreens,
    void Function(CallModel call)? openIncoming,
    void Function(CallModel call)? openActive,
  }) {
    manager = CallManager.forTest(CallManagerDeps(
      api: api,
      platform: platform,
      liveKitFactory: () {
        final lk = FakeLiveKit()
          ..connectError = nextConnectError
          ..connectGate = nextConnectGate;
        nextConnectError = null;
        nextConnectGate = null;
        liveKits.add(lk);
        return lk;
      },
      closeCallScreens: () {
        closes++;
        closeCallScreens?.call();
      },
      openActiveCall: (c) {
        opened.add('active:${c.callId}');
        openActive?.call(c);
      },
      openIncomingCall: (c) {
        opened.add('incoming:${c.callId}');
        openIncoming?.call(c);
      },
    ));
    manager.onCallFinished = finishes.add;
  }

  final FakeCallApi api = FakeCallApi();
  final FakeCallPlatform platform = FakeCallPlatform();
  final List<FakeLiveKit> liveKits = [];
  final List<CallFinish> finishes = [];
  final List<String> opened = [];
  int closes = 0;
  Object? nextConnectError;
  Completer<void>? nextConnectGate;
  late final CallManager manager;

  FakeLiveKit get liveKit => liveKits.last;

  static Map<String, dynamic> incomingPayload({String callId = 'call-1', String callType = 'audio'}) => {
        'callId': callId,
        'callUuid': kCallUuid,
        'caller': {'_id': 'u-caller', 'name': 'Ada', 'profilePicture': null},
        'callType': callType,
        'roomName': 'call:$callId',
      };

  Future<InitiateResult> startOutgoing({CallType type = CallType.audio}) =>
      manager.initiateCall('u-callee', 'Bo', null, type);

  Future<void> ringIncoming({String callType = 'audio'}) =>
      manager.handleIncoming(incomingPayload(callType: callType));

  Future<void> state(String status, {String callId = 'call-1', String? outcome, int duration = 0}) =>
      manager.handleSocketEvent('call:state', {
        'callId': callId,
        'callUuid': kCallUuid,
        'status': status,
        'outcome': outcome,
        'duration': duration,
      });
}

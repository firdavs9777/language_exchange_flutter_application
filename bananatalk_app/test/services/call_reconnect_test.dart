import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

CallHarness _connected(FakeAsync async) {
  final h = CallHarness();
  h.startOutgoing();
  async.flushMicrotasks();
  h.state('active');
  async.flushMicrotasks();
  h.liveKit.onPeerConnected!();
  async.flushMicrotasks();
  return h;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('peer gone for 20 s → POST /end and one finish (connectionLost)', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onPeerDisconnected!();
      async.elapse(const Duration(seconds: 19));
      expect(h.finishes, isEmpty);
      expect(h.manager.connectionState, CallUiState.reconnecting);
      async.elapse(const Duration(seconds: 2));
      expect(h.finishes.single.reason, CallExitReason.connectionLost);
      expect(h.api.calls.where((c) => c == 'end:call-1'), hasLength(1));
    });
  });

  test('local network back within 20 s keeps the call', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onReconnecting!();
      async.elapse(const Duration(seconds: 10));
      h.liveKit.onReconnected!();
      async.elapse(const Duration(seconds: 30));
      expect(h.finishes, isEmpty);
      expect(h.manager.connectionState, CallUiState.connected);
    });
  });

  test('peer rejoins within 20 s keeps the call', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onPeerDisconnected!();
      async.elapse(const Duration(seconds: 15));
      h.liveKit.onPeerConnected!();
      async.elapse(const Duration(seconds: 30));
      expect(h.finishes, isEmpty);
    });
  });

  test('quality: the raw callback is chained, the mapped one still fires', () {
    fakeAsync((async) {
      final h = _connected(async);
      final raw = <lk.ConnectionQuality>[];
      final mapped = <CallQuality>[];
      h.manager.onRawQualityChanged = raw.add;
      h.manager.onCallQualityChanged = mapped.add;
      h.liveKit.onConnectionQualityChanged!(lk.ConnectionQuality.poor);
      expect(raw, [lk.ConnectionQuality.poor]);
      expect(mapped, [CallQuality.poor]);
      expect(h.manager.connectionState, CallUiState.poorConnection);
    });
  });

  test('expireIncoming skips an in-flight accept', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.ringIncoming();
      async.flushMicrotasks();
      h.api.acceptGate = Completer<void>();
      h.manager.acceptCall();
      async.flushMicrotasks();
      bool? expired;
      h.manager.expireIncoming('call-1').then((v) => expired = v);
      async.flushMicrotasks();
      expect(expired, isFalse);
      expect(h.finishes, isEmpty);
      expect(h.manager.currentCall, isNotNull);
    });
  });

  test('outgoing 50 s check re-arms once; still ringing at 65 s is no answer', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 51));
      expect(h.finishes, isEmpty); // GET says ringing: keep waiting
      async.elapse(const Duration(seconds: 15));
      expect(h.api.calls.where((c) => c == 'get:call-1'), hasLength(2));
      expect(h.finishes.single.reason, CallExitReason.remoteState);
      expect(h.finishes.single.outcome, CallOutcome.noAnswer);
    });
  });
}

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<Map<String, dynamic>>> sent;
  late bool on;
  late bool sendResult;
  late PaywallTracker t;

  setUp(() {
    sent = [];
    on = true;
    sendResult = true;
    t = PaywallTracker(
      send: (e) async {
        sent.add(e);
        return sendResult;
      },
      enabled: () => on,
    );
  });
  tearDown(() => t.dispose());

  const flow = PaywallFlow(placement: 'wave_cap', flowId: 'f1');

  test('nothing is queued or sent while the flag is off', () {
    fakeAsync((a) {
      on = false;
      t.log(flow, 'shown');
      a.elapse(const Duration(seconds: 30));
      t.flush();
      a.flushMicrotasks();
      expect(sent, isEmpty);
    });
  });

  test('events flush after 10 seconds in one batch', () {
    fakeAsync((a) {
      t.log(flow, 'shown');
      t.log(flow, 'cta_vip', detail: 'x' * 60);
      a.elapse(const Duration(seconds: 9));
      expect(sent, isEmpty);
      a.elapse(const Duration(seconds: 1));
      expect(sent.single.length, 2);
      expect(sent.single[1]['detail'].length, 40);
      expect(sent.single[0].keys,
          containsAll(['placement', 'action', 'flowId', 'clientAt']));
      expect(sent.single[0].containsKey('offerId'), isFalse);
      expect(sent.single[0].containsKey('detail'), isFalse);
    });
  });

  test('flow detail and offerId are carried; call detail wins', () {
    fakeAsync((a) {
      const f = PaywallFlow(
          placement: 'boost', flowId: 'f2', offerId: 'o1', detail: 'surf');
      t.log(f, 'shown');
      t.log(f, 'dismissed', detail: 'call');
      a.elapse(const Duration(seconds: 10));
      expect(sent.single[0]['detail'], 'surf');
      expect(sent.single[0]['offerId'], 'o1');
      expect(sent.single[1]['detail'], 'call');
      final at = sent.single[0]['clientAt'] as String;
      expect(DateTime.parse(at).isUtc, isTrue);
    });
  });

  test('the 20th event flushes at once', () {
    fakeAsync((a) {
      for (var i = 0; i < 19; i++) {
        t.log(flow, 'shown');
      }
      a.flushMicrotasks();
      expect(sent, isEmpty);
      t.log(flow, 'shown');
      a.flushMicrotasks();
      expect(sent.single.length, 20);
      a.elapse(const Duration(seconds: 30));
      expect(sent.length, 1);
    });
  });

  test('more than 50 queued events go out in chunks of at most 50', () {
    fakeAsync((a) {
      final big = PaywallTracker(
        send: (e) async {
          sent.add(e);
          return true;
        },
        enabled: () => true,
        maxQueue: 1000,
      );
      for (var i = 0; i < 120; i++) {
        big.log(flow, 'shown');
      }
      big.flush();
      a.flushMicrotasks();
      expect(sent.map((b) => b.length).toList(), [50, 50, 20]);
      big.dispose();
    });
  });

  test('a failed send drops the batch and the next event starts a fresh one',
      () {
    fakeAsync((a) {
      sendResult = false;
      t.log(flow, 'shown');
      a.elapse(const Duration(seconds: 10));
      expect(sent.length, 1);
      sendResult = true;
      t.log(flow, 'dismissed');
      a.elapse(const Duration(seconds: 10));
      expect(sent.length, 2);
      expect(sent[1].single['action'], 'dismissed');
    });
  });

  test('a throwing send drops the batch without throwing', () {
    fakeAsync((a) {
      final bad = PaywallTracker(
        send: (e) async => throw StateError('net'),
        enabled: () => true,
      );
      bad.log(flow, 'shown');
      a.elapse(const Duration(seconds: 10));
      a.flushMicrotasks();
      bad.dispose();
    });
  });

  test('turning the flag off drops what is queued', () {
    fakeAsync((a) {
      t.log(flow, 'shown');
      on = false;
      t.log(flow, 'shown');
      on = true;
      a.elapse(const Duration(seconds: 30));
      t.flush();
      a.flushMicrotasks();
      expect(sent, isEmpty);
    });
  });

  test('a flush after the flag turned off sends nothing (timer or pause)', () {
    fakeAsync((a) {
      t.log(flow, 'shown');
      on = false; // config refresh turned events off; nothing logged since
      a.elapse(const Duration(seconds: 30)); // the queued timer fires
      t.flush(); // the pause observer
      a.flushMicrotasks();
      expect(sent, isEmpty);
      on = true;
      t.flush();
      a.flushMicrotasks();
      expect(sent, isEmpty, reason: 'the old queue was dropped, not kept');
    });
  });

  test('dispose with queued events sends nothing and cancels the timer', () {
    fakeAsync((a) {
      t.log(flow, 'shown');
      expect(a.pendingTimers, isNotEmpty);
      t.dispose();
      expect(a.pendingTimers, isEmpty);
      t.flush();
      a.elapse(const Duration(seconds: 30));
      expect(sent, isEmpty);
    });
  });

  test('a multi-chunk flush stops after dispose', () {
    fakeAsync((a) {
      late PaywallTracker big;
      big = PaywallTracker(
        send: (e) async {
          sent.add(e);
          big.dispose(); // sign-out while the first chunk is in flight
          return true;
        },
        enabled: () => true,
        maxQueue: 1000,
      );
      for (var i = 0; i < 120; i++) {
        big.log(flow, 'shown');
      }
      big.flush();
      a.flushMicrotasks();
      expect(sent.map((b) => b.length).toList(), [50]);
    });
  });

  test('turning the flag on mid-session starts sending', () {
    fakeAsync((a) {
      on = false;
      t.log(flow, 'shown');
      on = true;
      t.log(flow, 'cta_vip');
      a.elapse(const Duration(seconds: 10));
      expect(sent.single.single['action'], 'cta_vip');
    });
  });

  test('a flow started twice has two different ids of 22 url-safe characters',
      () {
    final a = PaywallFlow.start('boost');
    final b = PaywallFlow.start('boost', detail: 'd', offerId: 'o');
    expect(a.flowId, isNot(b.flowId));
    for (final id in [a.flowId, b.flowId]) {
      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
    }
    expect(b.detail, 'd');
    expect(b.offerId, 'o');
  });

  group('paywallLog', () {
    late int built;
    late List<String> spied;

    ProviderContainer make({required bool flag, bool throwing = false}) {
      final c = ProviderContainer(
        overrides: [
          paywallEventsEnabledProvider.overrideWithValue(flag),
          paywallTrackerProvider.overrideWith((ref) {
            built++;
            if (throwing) throw StateError('tracker unavailable');
            return t;
          }),
        ],
      );
      paywallLogContainer = c;
      return c;
    }

    setUp(() {
      built = 0;
      spied = [];
      paywallLogSpy = (f, action, d) => spied.add(action);
    });
    tearDown(() {
      paywallLogSpy = null;
      paywallLogContainer = null;
    });

    test('flag off: the spy sees the call but no tracker is built', () {
      fakeAsync((a) {
        final c = make(flag: false);
        paywallLog(flow, 'shown');
        a.elapse(const Duration(seconds: 30));
        expect(spied, ['shown']);
        expect(built, 0);
        expect(c.exists(paywallTrackerProvider), isFalse);
        expect(sent, isEmpty);
        c.dispose();
      });
    });

    test('flag on: the event reaches the tracker', () {
      fakeAsync((a) {
        final c = make(flag: true);
        paywallLog(flow, 'shown');
        a.elapse(const Duration(seconds: 10));
        expect(built, 1);
        expect(sent.single.single['action'], 'shown');
        c.dispose();
      });
    });

    test('a throw inside (spy or tracker) is caught, never thrown', () {
      final c = make(flag: true, throwing: true);
      addTearDown(c.dispose);
      expect(() => paywallLog(flow, 'shown'), returnsNormally);
      expect(built, 1, reason: 'the tracker build threw inside paywallLog');

      paywallLogSpy = (f, action, d) => throw StateError('spy');
      expect(() => paywallLog(flow, 'shown'), returnsNormally);
    });
  });
}

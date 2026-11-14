import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('paywallLog never throws when the container is unavailable', () {
    // No binding-backed provider overrides here; the flag is off (no
    // app-config), so this must simply do nothing.
    expect(() => paywallLog(flow, 'shown'), returnsNormally);
  });
}

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/feed_open_tracker.dart';

void main() {
  test('opening the same post twice sends one item', () async {
    final sent = <List<Map<String, dynamic>>>[];
    final t = FeedOpenTracker(send: (b) async => sent.add(b));
    t.opened('a');
    t.opened('a');
    await t.flush();
    expect(sent, [
      [
        {'momentId': 'a', 'opened': true},
      ],
    ]);
  });

  test('an id already sent is not sent again later in the session', () async {
    final sent = <List<Map<String, dynamic>>>[];
    final t = FeedOpenTracker(send: (b) async => sent.add(b));
    t.opened('a');
    await t.flush();
    t.opened('a');
    await t.flush();
    expect(sent.length, 1);
  });

  test('ten distinct ids flush once with the exact item shape', () async {
    final sent = <List<Map<String, dynamic>>>[];
    final t = FeedOpenTracker(send: (b) async => sent.add(b));
    for (var i = 0; i < 10; i++) {
      t.opened('m$i');
    }
    await Future<void>.delayed(Duration.zero);
    expect(sent.length, 1);
    expect(sent.single, [
      for (var i = 0; i < 10; i++) {'momentId': 'm$i', 'opened': true},
    ]);
  });

  test('flush with nothing pending sends nothing', () async {
    final sent = <List<Map<String, dynamic>>>[];
    final t = FeedOpenTracker(send: (b) async => sent.add(b));
    await t.flush();
    expect(sent, isEmpty);
  });

  test('a throwing sender does not throw and the ids are not re-sent',
      () async {
    var calls = 0;
    final t = FeedOpenTracker(send: (_) async {
      calls++;
      throw Exception('offline');
    });
    t.opened('a');
    await t.flush();
    t.opened('a');
    await t.flush();
    expect(calls, 1);
  });

  test('flushes 5 s after the last opened', () {
    fakeAsync((async) {
      final sent = <List<Map<String, dynamic>>>[];
      final t = FeedOpenTracker(send: (b) async => sent.add(b));
      t.opened('a');
      async.elapse(const Duration(seconds: 4));
      t.opened('b'); // restarts the window
      async.elapse(const Duration(seconds: 4));
      expect(sent, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(sent.length, 1);
      expect(sent.single.length, 2);
      t.dispose();
    });
  });
}

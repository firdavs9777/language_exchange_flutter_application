import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/reel_view_tracker.dart';

void main() {
  late List<List<Map<String, dynamic>>> sent;
  late ReelViewTracker tracker;

  setUp(() {
    sent = [];
    tracker = ReelViewTracker(send: (batch) async => sent.add(batch));
  });

  void watch(String id, {required Duration watched, required Duration total}) {
    tracker.onReelStarted(id);
    tracker.onReelEnded(watched: watched, total: total);
  }

  test('a view under one second is dropped', () async {
    watch('r1',
        watched: const Duration(milliseconds: 400),
        total: const Duration(seconds: 30));
    await tracker.flush();
    expect(sent, isEmpty, reason: 'a scroll-past is not a view');
  });

  test('a view over one second is queued', () async {
    watch('r1',
        watched: const Duration(seconds: 3), total: const Duration(seconds: 30));
    await tracker.flush();
    expect(sent.single.single['momentId'], 'r1');
    expect(sent.single.single['watchedMs'], 3000);
    expect(sent.single.single['completed'], isFalse);
  });

  test('90% watched counts as completed', () async {
    watch('r1',
        watched: const Duration(seconds: 27), total: const Duration(seconds: 30));
    await tracker.flush();
    expect(sent.single.single['completed'], isTrue);
  });

  test('15 seconds completes a long reel without watching it all', () async {
    watch('r1',
        watched: const Duration(seconds: 16), total: const Duration(minutes: 2));
    await tracker.flush();
    expect(sent.single.single['completed'], isTrue);
  });

  test('a zero-duration reel is never called complete', () async {
    // Duration is unknown until the controller reports it; guessing "complete"
    // would invent completions for reels nobody finished.
    watch('r1', watched: const Duration(seconds: 5), total: Duration.zero);
    await tracker.flush();
    expect(sent.single.single['completed'], isFalse);
  });

  test('events batch rather than sending one request each', () async {
    for (var i = 0; i < 3; i++) {
      watch('r$i',
          watched: const Duration(seconds: 2), total: const Duration(seconds: 30));
    }
    await tracker.flush();
    expect(sent.length, 1, reason: 'one request, not three');
    expect(sent.single.length, 3);
  });

  test('the queue auto-flushes once it reaches the threshold', () async {
    final t = ReelViewTracker(send: (b) async => sent.add(b), flushEvery: 2);
    t.onReelStarted('a');
    t.onReelEnded(watched: const Duration(seconds: 2), total: const Duration(seconds: 30));
    t.onReelStarted('b');
    t.onReelEnded(watched: const Duration(seconds: 2), total: const Duration(seconds: 30));
    await Future<void>.delayed(Duration.zero);
    expect(sent.length, 1);
  });

  test('flushing an empty queue sends nothing', () async {
    await tracker.flush();
    expect(sent, isEmpty);
  });

  test('a failed send never throws into the UI', () async {
    final failing = ReelViewTracker(send: (_) async => throw Exception('offline'));
    failing.onReelStarted('r1');
    failing.onReelEnded(
        watched: const Duration(seconds: 3), total: const Duration(seconds: 30));
    await expectLater(failing.flush(), completes);
  });

  test('the queue is cleared after a successful flush', () async {
    watch('r1',
        watched: const Duration(seconds: 3), total: const Duration(seconds: 30));
    await tracker.flush();
    await tracker.flush();
    expect(sent.length, 1, reason: 'the second flush had nothing to send');
  });

  test('ending without a start records nothing', () async {
    tracker.onReelEnded(
        watched: const Duration(seconds: 5), total: const Duration(seconds: 30));
    await tracker.flush();
    expect(sent, isEmpty);
  });
}

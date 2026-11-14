import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<Map<String, dynamic>>> sent;
  late bool on;
  late bool sendResult;
  late StudyTracker t;

  setUp(() {
    sent = [];
    on = true;
    sendResult = true;
    t = StudyTracker(
      send: (e) async {
        sent.add(e);
        return sendResult;
      },
      enabled: () => on,
    );
  });
  tearDown(() => t.dispose());

  test('the flag parses from app-config and defaults to false', () {
    const base = {
      'minVersion': '0',
      'latestVersion': '0',
      'forceUpdate': false,
      'iosUrl': '',
      'androidUrl': '',
      'releaseNotes': '',
    };
    expect(AppConfig.fromJson({...base}).studyEventsEnabled, isFalse);
    expect(AppConfig.fromJson({...base, 'studyEventsEnabled': true}).studyEventsEnabled,
        isTrue);
  });

  test('nothing is queued or sent while the flag is off', () {
    fakeAsync((a) {
      on = false;
      t.log(StudyEvent.tabOpened);
      a.elapse(const Duration(seconds: 30));
      t.flush();
      a.flushMicrotasks();
      expect(sent, isEmpty);
    });
  });

  test('events flush after 10 seconds in one batch, with fields clipped', () {
    fakeAsync((a) {
      t.log(StudyEvent.stepFinished,
          language: 'ko', kind: 'grammar', score: 3, total: 5);
      t.log(StudyEvent.levelCheckFinished, detail: 'x' * 60, kind: 'k' * 40);
      a.elapse(const Duration(seconds: 9));
      expect(sent, isEmpty);
      a.elapse(const Duration(seconds: 1));
      expect(sent.single.length, 2);
      expect(sent.single[0]['name'], 'step_finished');
      expect(sent.single[0]['language'], 'ko');
      expect(sent.single[0]['score'], 3);
      expect(sent.single[0]['total'], 5);
      expect(sent.single[1]['detail'].length, 40);
      expect(sent.single[1]['kind'].length, 24);
      expect(sent.single[1].containsKey('score'), isFalse);
      final at = sent.single[0]['clientAt'] as String;
      expect(DateTime.parse(at).isUtc, isTrue);
    });
  });

  test('score and total are clamped and an out-of-range language is omitted', () {
    fakeAsync((a) {
      t.log(StudyEvent.stepFinished,
          language: 'x', score: -4, total: 5000);
      t.log(StudyEvent.stepFinished, language: 'abcdefghijk');
      a.elapse(const Duration(seconds: 10));
      expect(sent.single[0]['score'], 0);
      expect(sent.single[0]['total'], 1000);
      expect(sent.single[0].containsKey('language'), isFalse);
      expect(sent.single[1].containsKey('language'), isFalse);
    });
  });

  test('the 20th event flushes at once', () {
    fakeAsync((a) {
      for (var i = 0; i < 19; i++) {
        t.log(StudyEvent.tabOpened);
      }
      a.flushMicrotasks();
      expect(sent, isEmpty);
      t.log(StudyEvent.tabOpened);
      a.flushMicrotasks();
      expect(sent.single.length, 20);
      a.elapse(const Duration(seconds: 30));
      expect(sent.length, 1);
    });
  });

  test('more than 50 queued events go out in chunks of at most 50', () {
    fakeAsync((a) {
      final big = StudyTracker(
        send: (e) async {
          sent.add(e);
          return true;
        },
        enabled: () => true,
        maxQueue: 1000,
      );
      for (var i = 0; i < 120; i++) {
        big.log(StudyEvent.tabOpened);
      }
      big.flush();
      a.flushMicrotasks();
      expect(sent.map((b) => b.length).toList(), [50, 50, 20]);
      big.dispose();
    });
  });

  test('a failed send drops the batch and the next event starts a fresh one', () {
    fakeAsync((a) {
      sendResult = false;
      t.log(StudyEvent.tabOpened);
      a.elapse(const Duration(seconds: 10));
      expect(sent.length, 1);
      sendResult = true;
      t.log(StudyEvent.sessionStarted);
      a.elapse(const Duration(seconds: 10));
      expect(sent.length, 2);
      expect(sent[1].single['name'], 'session_started');
    });
  });

  test('a throwing send drops the batch without throwing', () {
    fakeAsync((a) {
      final bad = StudyTracker(
        send: (e) async => throw StateError('net'),
        enabled: () => true,
      );
      bad.log(StudyEvent.tabOpened);
      a.elapse(const Duration(seconds: 10));
      a.flushMicrotasks();
      bad.dispose();
    });
  });

  test('turning the flag off drops what is queued', () {
    fakeAsync((a) {
      t.log(StudyEvent.tabOpened);
      on = false;
      t.log(StudyEvent.tabOpened);
      on = true;
      a.elapse(const Duration(seconds: 30));
      t.flush();
      a.flushMicrotasks();
      expect(sent, isEmpty);
    });
  });

  test('a flush after the flag turned off sends nothing (timer or pause)', () {
    fakeAsync((a) {
      t.log(StudyEvent.tabOpened);
      on = false;
      a.elapse(const Duration(seconds: 30));
      t.flush();
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
      t.log(StudyEvent.tabOpened);
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
      late StudyTracker big;
      big = StudyTracker(
        send: (e) async {
          sent.add(e);
          big.dispose();
          return true;
        },
        enabled: () => true,
        maxQueue: 1000,
      );
      for (var i = 0; i < 120; i++) {
        big.log(StudyEvent.tabOpened);
      }
      big.flush();
      a.flushMicrotasks();
      expect(sent.map((b) => b.length).toList(), [50]);
    });
  });

  test('turning the flag on mid-session starts sending', () {
    fakeAsync((a) {
      on = false;
      t.log(StudyEvent.tabOpened);
      on = true;
      t.log(StudyEvent.sessionStarted);
      a.elapse(const Duration(seconds: 10));
      expect(sent.single.single['name'], 'session_started');
    });
  });

  group('studyLog', () {
    late int built;
    late List<String> spied;

    ProviderContainer make({required bool flag, bool throwing = false}) {
      final c = ProviderContainer(
        overrides: [
          studyEventsEnabledProvider.overrideWithValue(flag),
          studyTrackerProvider.overrideWith((ref) {
            built++;
            if (throwing) throw StateError('tracker unavailable');
            return t;
          }),
        ],
      );
      studyLogContainer = c;
      return c;
    }

    setUp(() {
      built = 0;
      spied = [];
      studyLogSpy = (name, fields) => spied.add(name);
    });
    tearDown(() {
      studyLogSpy = null;
      studyLogContainer = null;
    });

    test('flag off: the spy sees the call but no tracker is built', () {
      fakeAsync((a) {
        final c = make(flag: false);
        studyLog(StudyEvent.tabOpened);
        a.elapse(const Duration(seconds: 30));
        expect(spied, ['tab_opened']);
        expect(built, 0);
        expect(c.exists(studyTrackerProvider), isFalse);
        expect(sent, isEmpty);
        c.dispose();
      });
    });

    test('flag on: the event reaches the tracker', () {
      fakeAsync((a) {
        final c = make(flag: true);
        studyLog(StudyEvent.featureOpened, kind: 'tutor');
        a.elapse(const Duration(seconds: 10));
        expect(built, 1);
        expect(sent.single.single['name'], 'feature_opened');
        expect(sent.single.single['kind'], 'tutor');
        c.dispose();
      });
    });

    test('a throw inside (spy or tracker) is caught, never thrown', () {
      final c = make(flag: true, throwing: true);
      addTearDown(c.dispose);
      expect(() => studyLog(StudyEvent.tabOpened), returnsNormally);
      expect(built, 1, reason: 'the tracker build threw inside studyLog');

      studyLogSpy = (name, fields) => throw StateError('spy');
      expect(() => studyLog(StudyEvent.tabOpened), returnsNormally);
    });
  });
}

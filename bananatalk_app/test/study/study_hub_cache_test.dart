import 'dart:async';
import 'dart:convert';

import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/study/study_hub_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StudyHubSnapshot _snap({
  String dateKey = '2026-11-14',
  String packDateKey = '2026-11-14',
  DateTime? savedAt,
  int streak = 7,
  int done = 2,
  int total = 4,
}) => StudyHubSnapshot(
  dateKey: dateKey,
  packDateKey: packDateKey,
  language: 'Korean',
  level: 'B1',
  streak: streak,
  stationsDone: done,
  stationsTotal: total,
  savedAt: savedAt ?? DateTime(2026, 11, 14, 23, 50),
);

void main() {
  final t0 = DateTime(2026, 11, 14, 23, 50);

  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  test('write then read returns the snapshot for that user only', () async {
    final cache = StudyHubCache(now: () => t0);
    await cache.write('me', _snap());
    final read = await cache.read('me');
    expect(read, isNotNull);
    expect(read!.dateKey, '2026-11-14');
    expect(read.language, 'Korean');
    expect(read.level, 'B1');
    expect(read.streak, 7);
    expect(read.stationsDone, 2);
    expect(read.stationsTotal, 4);
    expect(read.packDateKey, '2026-11-14');
    expect(read.savedAt, DateTime(2026, 11, 14, 23, 50));
    expect(await cache.read('other'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('study_hub_v1_me'), isTrue);
  });

  test('a missing language and level survive the round trip as null', () async {
    final cache = StudyHubCache(now: () => t0);
    await cache.write(
      'me',
      StudyHubSnapshot(
        dateKey: '2026-11-14',
        packDateKey: '2026-11-14',
        streak: 0,
        stationsDone: 0,
        stationsTotal: 0,
        savedAt: t0,
      ),
    );
    final read = await cache.read('me');
    expect(read!.language, isNull);
    expect(read.level, isNull);
  });

  test('corrupt data and another user id read as null', () async {
    final cache = StudyHubCache(now: () => t0);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('study_hub_v1_me', '{not json');
    expect(await cache.read('me'), isNull);
    expect(
      prefs.containsKey('study_hub_v1_me'),
      isFalse,
      reason: 'an unusable entry is removed',
    );

    await prefs.setString(
      'study_hub_v1_me',
      jsonEncode({'v': 1, 'streak': 'x'}),
    );
    expect(await cache.read('me'), isNull);

    // Another user's entry sitting under this user's key.
    await cache.write('A', _snap());
    await prefs.setString('study_hub_v1_B', prefs.getString('study_hub_v1_A')!);
    expect(await cache.read('B'), isNull);
    expect(prefs.containsKey('study_hub_v1_B'), isFalse);

    expect(await cache.read(''), isNull);
  });

  test('a write that started before clearAll does not land after it', () async {
    final cache = StudyHubCache(now: () => t0);
    final pending = cache.write('me', _snap());
    await cache.clearAll();
    await pending;
    expect(await cache.read('me'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('study_hub_v1_me'), isFalse);

    // A write begun after the clear lands.
    await cache.write('me', _snap());
    expect(await cache.read('me'), isNotNull);
  });

  test('clearAll removes every user\'s snapshot and nothing else', () async {
    SharedPreferences.setMockInitialValues({
      'userId': 'me',
      'app_theme': 'dark',
    });
    final cache = StudyHubCache(now: () => t0);
    await cache.write('me', _snap());
    await cache.write('other', _snap());
    await cache.clearAll();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith('study_hub_v1_')),
      isEmpty,
    );
    expect(prefs.getString('app_theme'), 'dark');
  });

  test(
    'the sign-out prefs clean-up removes the snapshot (not device-level)',
    () async {
      final cache = StudyHubCache(now: () => t0);
      await cache.write('me', _snap());
      expect(isDeviceLevelPrefsKey('study_hub_v1_me'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      await clearUserScopedPrefs(prefs);
      expect(await cache.read('me'), isNull);
    },
  );

  test('todayKey is the device-local date as YYYY-MM-DD', () {
    expect(
      StudyHubCache(now: () => DateTime(2026, 1, 5, 0, 1)).todayKey(),
      '2026-01-05',
    );
    expect(
      StudyHubCache(now: () => DateTime(2026, 11, 14, 23, 59)).todayKey(),
      '2026-11-14',
    );
  });

  test('signedInUserId reads the userId pref', () async {
    expect(await StudyHubCache().signedInUserId(), 'me');
    SharedPreferences.setMockInitialValues({});
    expect(await StudyHubCache().signedInUserId(), isNull);
  });

  group('isFresh', () {
    final cache = StudyHubCache(now: () => t0);

    test('today save day, today pack and under 24 hours is fresh', () {
      expect(cache.isFresh(_snap()), isTrue);
    });

    test(
      "a pack from yesterday, a save day of yesterday or a day-old save is not",
      () {
        expect(cache.isFresh(_snap(packDateKey: '2026-11-13')), isFalse);
        expect(cache.isFresh(_snap(dateKey: '2026-11-13')), isFalse);
        expect(
          StudyHubCache(
            now: () => DateTime(2026, 11, 14, 23, 50),
          ).isFresh(_snap(savedAt: DateTime(2026, 11, 13, 23, 40))),
          isFalse,
        );
        expect(
          cache.isFresh(_snap(savedAt: t0.add(const Duration(minutes: 5)))),
          isFalse,
          reason: 'saved in the future (clock moved back)',
        );
      },
    );

    test('an entry without the pack date does not read', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'study_hub_v1_me',
        jsonEncode({
          'v': 1,
          'userId': 'me',
          'dateKey': '2026-11-14',
          'streak': 1,
          'stationsDone': 0,
          'stationsTotal': 1,
          'savedAt': t0.millisecondsSinceEpoch,
        }),
      );
      expect(await cache.read('me'), isNull);
    });
  });

  group('recordStationCompleted', () {
    test('started before clearAll, it writes nothing after it', () async {
      // The first prefs call is signedInUserId, the second is read's: hold
      // the second so clearAll (and a new entry) land inside the gap.
      final gate = Completer<void>();
      var calls = 0;
      final cache = StudyHubCache(
        now: () => t0,
        prefs: () async {
          if (++calls == 2) await gate.future;
          return SharedPreferences.getInstance();
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await cache.write('me', _snap(done: 1, total: 4));
      calls = 0;
      final pending = cache.recordStationCompleted(stationsRemaining: 2);
      await Future<void>.delayed(Duration.zero);
      await cache.clearAll();
      // An entry present again when the held read resumes.
      await prefs.setString(
        'study_hub_v1_me',
        jsonEncode({
          'v': 1,
          'userId': 'me',
          'dateKey': '2026-11-14',
          'packDateKey': '2026-11-14',
          'streak': 7,
          'stationsDone': 1,
          'stationsTotal': 4,
          'savedAt': t0.millisecondsSinceEpoch,
        }),
      );
      gate.complete();
      await pending;
      expect(
        (await cache.read('me'))!.stationsDone,
        1,
        reason: 'the stale completion must not land',
      );
    });

    test("moves today's done count to total minus what remains", () async {
      final cache = StudyHubCache(now: () => t0);
      await cache.write('me', _snap(done: 1, total: 4));
      await cache.recordStationCompleted(stationsRemaining: 2);
      final read = await cache.read('me');
      expect(read!.stationsDone, 2);
      expect(read.stationsTotal, 4);
      expect(read.streak, 7);
    });

    test(
      "leaves yesterday's snapshot, a missing one and signed-out alone",
      () async {
        final cache = StudyHubCache(now: () => t0);
        await cache.write(
          'me',
          _snap(dateKey: '2026-11-13', done: 1, total: 4),
        );
        await cache.recordStationCompleted(stationsRemaining: 0);
        expect((await cache.read('me'))!.stationsDone, 1);

        await cache.clearAll();
        await cache.recordStationCompleted(stationsRemaining: 0);
        expect(await cache.read('me'), isNull);

        SharedPreferences.setMockInitialValues({});
        await cache.recordStationCompleted(stationsRemaining: 0);
        expect(await cache.read('me'), isNull);
      },
    );
  });
}

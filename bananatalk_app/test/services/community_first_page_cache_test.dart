import 'dart:convert';

import 'package:bananatalk_app/services/community_first_page_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _row(String id) => {'_id': id, 'name': 'Person $id'};
Map<String, dynamic> _match(String id) => {
      'user': {'_id': id, 'name': 'Person $id'},
      'matchReasons': ['reciprocal_pair'],
    };

void main() {
  const p = CommunityFirstPageCache.partners;
  const d = CommunityFirstPageCache.daily;
  final t0 = DateTime(2026, 11, 14, 12);

  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  test('round-trip: rows and meta come back for the same user and slot',
      () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(
      userId: 'me',
      slot: p,
      rows: [_row('a'), _row('b')],
      meta: {'fingerprint': 'f1'},
    );
    final read = await cache.read(userId: 'me', slot: p);
    expect(read!.rows.map((r) => r['_id']), ['a', 'b']);
    expect(read.meta['fingerprint'], 'f1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('community_first_page_v1_me_partners'), isTrue);
  });

  test('the signed-in user is read from the userId pref', () async {
    expect(await CommunityFirstPageCache().signedInUserId(), 'me');
    SharedPreferences.setMockInitialValues({});
    expect(await CommunityFirstPageCache().signedInUserId(), isNull);
  });

  test('another user id, or the other slot, returns null', () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(userId: 'me', slot: p, rows: [_row('a')]);
    expect(await cache.read(userId: 'other', slot: p), isNull);
    expect(await cache.read(userId: 'me', slot: d), isNull);
    expect(await cache.read(userId: '', slot: p), isNull);
  });

  test("an entry under user B's key holding user A's data is ignored and removed",
      () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(userId: 'A', slot: p, rows: [_row('a')]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CommunityFirstPageCache.keyFor('B', p),
      prefs.getString(CommunityFirstPageCache.keyFor('A', p))!,
    );
    expect(await cache.read(userId: 'B', slot: p), isNull);
    expect(prefs.containsKey(CommunityFirstPageCache.keyFor('B', p)), isFalse);
  });

  test('the user never caches their own profile', () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(userId: 'me', slot: p, rows: [_row('me'), _row('a')]);
    await cache.write(userId: 'me', slot: d, rows: [_match('me'), _match('a')],
        meta: {'nextRefreshAt': t0.add(const Duration(hours: 1)).toIso8601String()});
    expect((await cache.read(userId: 'me', slot: p))!.rows.map((r) => r['_id']), ['a']);
    expect((await cache.read(userId: 'me', slot: d))!.rows, hasLength(1));
  });

  test('at most 20 rows are written', () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(
        userId: 'me', slot: p, rows: [for (var i = 0; i < 30; i++) _row('$i')]);
    expect((await cache.read(userId: 'me', slot: p))!.rows, hasLength(20));
  });

  test('a daily entry keeps a full VIP batch with extras (24 rows)', () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(
        userId: 'me',
        slot: d,
        rows: [for (var i = 0; i < 30; i++) _match('$i')],
        meta: {'nextRefreshAt': t0.add(const Duration(hours: 1)).toIso8601String()});
    expect((await cache.read(userId: 'me', slot: d))!.rows, hasLength(24));
  });

  test('an over-size write is dropped and removes the previous entry',
      () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(userId: 'me', slot: p, rows: [_row('a')]);
    await cache.write(userId: 'me', slot: p, rows: [
      for (var i = 0; i < 20; i++) {'_id': '$i', 'bio': 'x' * 20000},
    ]);
    expect(await cache.read(userId: 'me', slot: p), isNull);
  });

  test('over-size or over-long entries found on read are ignored and removed',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final key = CommunityFirstPageCache.keyFor('me', p);
    Map<String, dynamic> entry(List rows) => {
          'v': 1,
          'userId': 'me',
          'slot': p,
          'savedAt': t0.millisecondsSinceEpoch,
          'meta': {},
          'rows': rows,
        };
    await prefs.setString(key, jsonEncode(entry([for (var i = 0; i < 21; i++) _row('$i')])));
    final cache = CommunityFirstPageCache(now: () => t0);
    expect(await cache.read(userId: 'me', slot: p), isNull);
    expect(prefs.containsKey(key), isFalse);

    await prefs.setString(key, jsonEncode(entry([{'_id': 'a', 'bio': 'x' * 310000}])));
    expect(await cache.read(userId: 'me', slot: p), isNull);
    expect(prefs.containsKey(key), isFalse);
  });

  test('partners: older than 24 hours is ignored and removed', () async {
    await CommunityFirstPageCache(now: () => t0)
        .write(userId: 'me', slot: p, rows: [_row('a')]);
    final at = t0.add(const Duration(hours: 23, minutes: 59));
    expect(await CommunityFirstPageCache(now: () => at).read(userId: 'me', slot: p),
        isNotNull);
    final late = t0.add(const Duration(hours: 24, minutes: 1));
    expect(await CommunityFirstPageCache(now: () => late).read(userId: 'me', slot: p),
        isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(CommunityFirstPageCache.keyFor('me', p)), isFalse);
  });

  test('daily: valid until nextRefreshAt, ignored at or after it, or without it',
      () async {
    final next = t0.add(const Duration(hours: 3));
    await CommunityFirstPageCache(now: () => t0).write(
        userId: 'me', slot: d, rows: [_match('a')],
        meta: {'nextRefreshAt': next.toIso8601String()});
    final before = next.subtract(const Duration(minutes: 1));
    expect(await CommunityFirstPageCache(now: () => before).read(userId: 'me', slot: d),
        isNotNull);
    expect(await CommunityFirstPageCache(now: () => next).read(userId: 'me', slot: d),
        isNull);

    await CommunityFirstPageCache(now: () => t0)
        .write(userId: 'me', slot: d, rows: [_match('a')]);
    expect(await CommunityFirstPageCache(now: () => t0).read(userId: 'me', slot: d),
        isNull);
  });

  test('corrupt or old-format entries are ignored and removed, never thrown',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final key = CommunityFirstPageCache.keyFor('me', p);
    final cache = CommunityFirstPageCache(now: () => t0);
    for (final bad in [
      'not json{',
      '[1,2]',
      jsonEncode({'v': 0, 'userId': 'me', 'slot': p, 'savedAt': 1, 'meta': {}, 'rows': []}),
      jsonEncode({'v': 1, 'userId': 'me', 'slot': p, 'savedAt': 'x', 'meta': {}, 'rows': []}),
      jsonEncode({'v': 1, 'userId': 'me', 'slot': p, 'savedAt': t0.millisecondsSinceEpoch, 'meta': {}, 'rows': 'x'}),
    ]) {
      await prefs.setString(key, bad);
      expect(await cache.read(userId: 'me', slot: p), isNull, reason: bad);
      expect(prefs.containsKey(key), isFalse, reason: bad);
    }
  });

  test('removeUser drops that person from both slots and keeps the rest',
      () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    final next = t0.add(const Duration(hours: 3)).toIso8601String();
    await cache.write(userId: 'me', slot: p, rows: [_row('a'), _row('b')]);
    await cache.write(
        userId: 'me', slot: d, rows: [_match('a'), _match('c')],
        meta: {'nextRefreshAt': next});
    await cache.removeUser('me', 'a');
    expect((await cache.read(userId: 'me', slot: p))!.rows.map((r) => r['_id']), ['b']);
    final daily = await cache.read(userId: 'me', slot: d);
    expect(daily!.rows.map(CommunityFirstPageCache.rowUserId), ['c']);
    expect(daily.meta['nextRefreshAt'], next);
  });

  test('a write begun before a clearAll is dropped; one begun after is kept',
      () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    final before = cache.epoch;
    await cache.clearAll();
    await cache.write(userId: 'me', slot: p, rows: [_row('a')], epoch: before);
    expect(await cache.read(userId: 'me', slot: p), isNull);
    await cache.write(
        userId: 'me', slot: p, rows: [_row('a')], epoch: cache.epoch);
    expect(await cache.read(userId: 'me', slot: p), isNotNull);
  });

  test('clearAll removes every entry and nothing else', () async {
    final cache = CommunityFirstPageCache(now: () => t0);
    await cache.write(userId: 'me', slot: p, rows: [_row('a')]);
    await cache.write(userId: 'other', slot: p, rows: [_row('a')]);
    await cache.clearAll();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'userId'});
  });
}

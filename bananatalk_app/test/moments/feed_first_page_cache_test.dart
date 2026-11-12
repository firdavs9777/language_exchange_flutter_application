import 'dart:convert';

import 'package:bananatalk_app/services/feed_first_page_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> _items(int n) =>
    [for (var i = 0; i < n; i++) {'_id': 'm$i', 'description': 'post $i'}];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round trip', () async {
    final cache = FeedFirstPageCache();
    await cache.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(3));
    final read = await cache.read(feedMode: 'forYou', userId: 'u1');
    expect(read, _items(3));
  });

  test('feed modes are separate', () async {
    final cache = FeedFirstPageCache();
    await cache.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(3));
    expect(await cache.read(feedMode: 'following', userId: 'u1'), isNull);
  });

  test('another user reads nothing', () async {
    final cache = FeedFirstPageCache();
    await cache.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(2));
    expect(await cache.read(feedMode: 'forYou', userId: 'u2'), isNull);
  });

  test('another version reads nothing', () async {
    SharedPreferences.setMockInitialValues({
      'feed_first_page_v1_forYou': jsonEncode({
        'v': 0,
        'userId': 'u1',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': _items(2),
      }),
    });
    expect(
      await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'u1'),
      isNull,
    );
  });

  test('older than 7 days reads nothing', () async {
    final old = FeedFirstPageCache(
      now: () => DateTime.now().subtract(const Duration(days: 8)),
    );
    await old.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(2));
    expect(
      await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'u1'),
      isNull,
    );
  });

  test('garbage reads nothing', () async {
    SharedPreferences.setMockInitialValues(
        {'feed_first_page_v1_forYou': 'not json {'});
    expect(
      await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'u1'),
      isNull,
    );
  });

  test('13 items written, 12 read', () async {
    final cache = FeedFirstPageCache();
    await cache.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(13));
    expect(
      (await cache.read(feedMode: 'forYou', userId: 'u1'))!.length,
      12,
    );
  });

  test('JSON over 400 KB is not written', () async {
    final cache = FeedFirstPageCache();
    await cache.write(
      feedMode: 'forYou',
      userId: 'u1',
      rawMoments: [
        {'_id': 'big', 'description': 'x' * (401 * 1024)},
      ],
    );
    expect(await cache.read(feedMode: 'forYou', userId: 'u1'), isNull);
  });

  test('clearAll removes every feed mode', () async {
    final cache = FeedFirstPageCache();
    await cache.write(feedMode: 'forYou', userId: 'u1', rawMoments: _items(1));
    await cache.write(feedMode: 'following', userId: 'u1', rawMoments: _items(1));
    await cache.clearAll();
    expect(await cache.read(feedMode: 'forYou', userId: 'u1'), isNull);
    expect(await cache.read(feedMode: 'following', userId: 'u1'), isNull);
  });
}

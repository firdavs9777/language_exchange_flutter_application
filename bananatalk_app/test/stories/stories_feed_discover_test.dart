import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_widget.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_rail_order.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/pages/stories/story_precache.dart';
import 'package:bananatalk_app/services/stories_rail_cache.dart';

Map<String, dynamic> _story(String id, String userId, Duration fromNow) => {
      '_id': id,
      'user': {'_id': userId, 'name': 'U$userId'},
      'mediaType': 'image',
      'mediaUrl': 'https://x.test/$id.jpg',
      'privacy': 'public',
      'isActive': true,
      'isArchived': false,
      'expiresAt': DateTime.now().add(fromNow).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'views': <dynamic>[],
    };

Map<String, dynamic> _groupOf(String userId, List<Map<String, dynamic>> s) =>
    {
      'user': {'_id': userId, 'name': 'U$userId'},
      'stories': s,
      'hasUnviewed': s.length,
    };

Map<String, dynamic> _group(String userId) => {
      'user': {'_id': userId, 'name': 'U$userId'},
      'stories': [
        {
          '_id': 's-$userId',
          'user': {'_id': userId, 'name': 'U$userId'},
          'mediaType': 'image',
          'mediaUrl': 'https://x.test/$userId.jpg',
          'privacy': 'public',
          'isActive': true,
          'isArchived': false,
          'expiresAt':
              DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'views': <dynamic>[],
        },
      ],
      'hasUnviewed': 1,
    };

void main() {
  group('StoriesFeedResult.fromJson', () {
    test('a response without discover parses with an empty Discover list', () {
      final r = StoriesFeedResult.fromJson({
        'success': true,
        'data': [_group('f1')],
      }, 'me');
      expect(r.success, isTrue);
      expect(r.followed.length, 1);
      expect(r.discover, isEmpty);
    });

    test('discover: "x" parses to an empty list', () {
      final r = StoriesFeedResult.fromJson({
        'success': true,
        'data': [_group('f1')],
        'discover': 'x',
      }, 'me');
      expect(r.followed.length, 1);
      expect(r.discover, isEmpty);
    });

    test('a discover array parses with the same shape as data', () {
      final r = StoriesFeedResult.fromJson({
        'success': true,
        'data': [_group('f1')],
        'discover': [_group('d1'), 'junk', _group('d2')],
      }, 'me');
      expect(r.discover.map((g) => g.user.id), ['d1', 'd2']);
      expect(r.rawDiscover.length, 2);
      expect(r.rawData.length, 1);
    });
  });

  group('StoriesRailCache', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round trip', () async {
      final cache = StoriesRailCache();
      final f1 = _group('f1');
      await cache.write(userId: 'u1', rawData: [f1], rawDiscover: [_group('d1')]);
      final read = await cache.read(userId: 'u1');
      expect(read!.data, [f1]);
      expect(read.discover.length, 1);
    });

    test('another user reads nothing', () async {
      final cache = StoriesRailCache();
      await cache.write(userId: 'u1', rawData: [_group('f1')], rawDiscover: []);
      expect(await cache.read(userId: 'u2'), isNull);
      expect(await cache.read(userId: ''), isNull);
    });

    test('another version, garbage and age read nothing', () async {
      SharedPreferences.setMockInitialValues({
        'stories_rail_v1': jsonEncode({
          'v': 0,
          'userId': 'u1',
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'data': [],
          'discover': [],
        }),
      });
      expect(await StoriesRailCache().read(userId: 'u1'), isNull);
      SharedPreferences.setMockInitialValues({'stories_rail_v1': 'nope {'});
      expect(await StoriesRailCache().read(userId: 'u1'), isNull);
      SharedPreferences.setMockInitialValues({});
      await StoriesRailCache(
              now: () => DateTime.now().subtract(const Duration(days: 8)))
          .write(userId: 'u1', rawData: [_group('f1')], rawDiscover: []);
      expect(await StoriesRailCache().read(userId: 'u1'), isNull);
    });

    test('an empty result overwrites the cache', () async {
      final cache = StoriesRailCache();
      await cache.write(userId: 'u1', rawData: [_group('f1')], rawDiscover: []);
      await cache.write(userId: 'u1', rawData: [], rawDiscover: []);
      final read = await cache.read(userId: 'u1');
      expect(read, isNotNull);
      expect(read!.data, isEmpty);
    });

    test('over 400 KB is not written and drops the stale entry', () async {
      final cache = StoriesRailCache();
      await cache.write(userId: 'u1', rawData: [_group('f1')], rawDiscover: []);
      await cache.write(userId: 'u1', rawData: [
        {'user': {'_id': 'big'}, 'pad': 'x' * (401 * 1024)},
      ], rawDiscover: []);
      expect(await cache.read(userId: 'u1'), isNull);
    });

    test('clearAll removes it, and the key is user-scoped, not device-level',
        () async {
      final cache = StoriesRailCache();
      await cache.write(userId: 'u1', rawData: [_group('f1')], rawDiscover: []);
      expect(isDeviceLevelPrefsKey(StoriesRailCache.key), isFalse);
      await cache.clearAll();
      expect(await cache.read(userId: 'u1'), isNull);
    });
  });

  group('StoriesFeedWidget', () {
    Future<List<List<String>>> pump(
      WidgetTester tester, {
      required Future<StoriesFeedResult> Function() feed,
      required Future<Set<String>> Function() blocked,
      bool discoverEnabled = true,
      bool unmetered = true,
    }) async {
      final precached = <List<String>>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          blockedUserIdsProvider.overrideWith((ref) => blocked()),
          appConfigProvider.overrideWith((ref) async =>
              AppConfig.fromJson({'storyDiscoverEnabled': discoverEnabled})),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoriesFeedWidget(
              feedLoader: feed,
              myStoriesLoader: () async => StoriesResponse(success: true),
              precache: (context, urls) async => precached.add(urls),
              railPrecacheAllowed: () async => unmetered,
            ),
          ),
        ),
      ));
      return precached;
    }

    testWidgets('cached rings wait for the block list, then drop blocked users',
        (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      await StoriesRailCache().write(
        userId: 'me',
        rawData: [_group('ok'), _group('bad')],
        rawDiscover: [_group('d1')],
      );
      final blocked = Completer<Set<String>>();
      final feed = Completer<StoriesFeedResult>();
      await pump(tester,
          feed: () => feed.future, blocked: () => blocked.future);
      await tester.pump(const Duration(milliseconds: 50));
      // Cache read, block list still pending: no rings, still loading.
      expect(find.text('Ubad'), findsNothing);
      expect(find.text('Uok'), findsNothing);

      blocked.complete({'bad'});
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uok'), findsOneWidget);
      expect(find.text('Ubad'), findsNothing);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('an empty fresh answer replaces the rail and the cache',
        (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      await StoriesRailCache()
          .write(userId: 'me', rawData: [_group('ok')], rawDiscover: []);
      final feed = Completer<StoriesFeedResult>();
      await pump(tester,
          feed: () => feed.future, blocked: () async => <String>{});
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uok'), findsOneWidget);

      feed.complete(const StoriesFeedResult(success: true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uok'), findsNothing);
      final read = await StoriesRailCache().read(userId: 'me');
      expect(read, isNotNull);
      expect(read!.data, isEmpty);
    });

    testWidgets('cache painted, then the fetch fails: the rail stays',
        (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      await StoriesRailCache()
          .write(userId: 'me', rawData: [_group('ok')], rawDiscover: []);
      final feed = Completer<StoriesFeedResult>();
      await pump(tester,
          feed: () => feed.future, blocked: () async => <String>{});
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uok'), findsOneWidget);

      feed.complete(StoriesFeedResult.failure(error: 'offline'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uok'), findsOneWidget);
      expect(find.byKey(const Key('stories-error-retry')), findsNothing);
    });

    testWidgets('flag off: no Discover rings, no label; precache gets the first 3',
        (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      final result = StoriesFeedResult.fromJson({
        'success': true,
        'data': [_group('f1'), _group('f2'), _group('f3'), _group('f4')],
        'discover': [_group('d1')],
      }, 'me');
      final precached = await pump(tester,
          feed: () async => result,
          blocked: () async => <String>{},
          discoverEnabled: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ud1'), findsNothing);
      expect(find.text('Discover'), findsNothing);
      expect(precached.single, [
        'https://x.test/f1.jpg',
        'https://x.test/f2.jpg',
        'https://x.test/f3.jpg',
      ]);
    });
  
    testWidgets('cached rings whose stories all expired are not drawn',
        (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      await StoriesRailCache().write(
        userId: 'me',
        rawData: [
          _groupOf('gone', [_story('g1', 'gone', const Duration(hours: -2))]),
          _groupOf('mixed', [
            _story('m-old', 'mixed', const Duration(hours: -1)),
            _story('m-new', 'mixed', const Duration(hours: 3)),
          ]),
        ],
        rawDiscover: [
          _groupOf('dgone', [_story('d1', 'dgone', const Duration(hours: -1))]),
        ],
      );
      final feed = Completer<StoriesFeedResult>();
      final precached = await pump(tester,
          feed: () => feed.future, blocked: () async => <String>{});
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ugone'), findsNothing);
      expect(find.text('Udgone'), findsNothing);
      expect(find.text('Umixed'), findsOneWidget);
      // The kept ring holds only its live story.
      expect(precached.single, ['https://x.test/m-new.jpg']);
    });

    testWidgets('on mobile data the rail warms nothing', (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      final result = StoriesFeedResult.fromJson({
        'success': true,
        'data': [_group('f1'), _group('f2')],
      }, 'me');
      final precached = await pump(tester,
          feed: () async => result,
          blocked: () async => <String>{},
          unmetered: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Uf1'), findsOneWidget);
      expect(precached, isEmpty);
    });
  });

  group('dropExpiredStoryGroups', () {
    test('drops expired stories and groups left with none', () {
      final groups = [
        UserStories.fromJson(
            _groupOf('a', [_story('a1', 'a', const Duration(hours: -1))]),
            'me'),
        UserStories.fromJson(
            _groupOf('b', [
              _story('b1', 'b', const Duration(hours: -1)),
              _story('b2', 'b', const Duration(hours: 1)),
            ]),
            'me'),
      ];
      final kept = dropExpiredStoryGroups(groups);
      expect(kept.map((g) => g.user.id), ['b']);
      expect(kept.single.stories.map((s) => s.id), ['b2']);
      expect(kept.single.latestStory?.id, 'b2');
      expect(kept.single.unviewedCount, 1);
    });
  });

  group('precacheStoryImages', () {
    testWidgets('warms the disk cache for each URL and decodes nothing',
        (tester) async {
      final warmed = <String>[];
      late BuildContext ctx;
      await tester.pumpWidget(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }));
      final before = PaintingBinding.instance.imageCache.currentSize;
      await tester.runAsync(() => precacheStoryImages(
            ctx,
            ['https://x.test/a.jpg', 'https://x.test/b.jpg'],
            warm: (url) async {
              warmed.add(url);
              if (url.endsWith('a.jpg')) throw Exception('404');
            },
          ));
      expect(warmed, ['https://x.test/a.jpg', 'https://x.test/b.jpg']);
      expect(PaintingBinding.instance.imageCache.currentSize, before);
      expect(PaintingBinding.instance.imageCache.pendingImageCount, 0);
    });
  });
}

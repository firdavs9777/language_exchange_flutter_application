import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_widget.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/stories_rail_cache.dart';

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
  });
}

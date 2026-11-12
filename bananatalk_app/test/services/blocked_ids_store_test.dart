import 'dart:convert';

import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show MomentsFeedTab, filteredMomentsForTabProvider;
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/blocked_ids_store.dart';
import 'package:bananatalk_app/services/feed_first_page_cache.dart';
import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/stories_rail_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _post(String id, String authorId) => {
      '_id': id,
      'user': {'_id': authorId, 'name': 'A$authorId'},
      'description': 'hi',
    };

Map<String, dynamic> _ring(String userId) => {
      'user': {'_id': userId, 'name': 'U$userId'},
      'stories': <dynamic>[],
    };

Future<Set<String>> _blockedIds() async {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c.read(blockedUserIdsProvider.future);
}

/// A blocked author must not paint from a cache: not right after the block,
/// and not on an offline cold start (the block list then cannot be fetched).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'userId': 'me', 'token': 't'}));

  group('a successful block', () {
    test('drops the author from the feed and rail caches, and remembers it',
        () async {
      for (final mode in ['forYou', 'following']) {
        await FeedFirstPageCache().write(
          feedMode: mode,
          userId: 'me',
          rawMoments: [_post('p1', 'bad'), _post('p2', 'ok')],
        );
      }
      await StoriesRailCache().write(
        userId: 'me',
        rawData: [_ring('bad'), _ring('ok')],
        rawDiscover: [_ring('bad'), _ring('d1')],
      );

      final result = await http.runWithClient(
        () => BlockService.blockUser(
          currentUserId: 'me',
          blockedUserId: 'bad',
          blockedUserName: 'Bad',
        ),
        () => MockClient((req) async => http.Response('{}', 200)),
      );
      expect(result['success'], isTrue);

      for (final mode in ['forYou', 'following']) {
        final items =
            await FeedFirstPageCache().read(feedMode: mode, userId: 'me');
        expect(items!.map((m) => m['_id']), ['p2']);
      }
      final rail = await StoriesRailCache().read(userId: 'me');
      expect(rail!.data.map((g) => g['user']['_id']), ['ok']);
      expect(rail.discover.map((g) => g['user']['_id']), ['d1']);
      expect(await BlockedIdsStore().read(userId: 'me'), {'bad'});
    });

    test('a failed block changes nothing', () async {
      await FeedFirstPageCache().write(
        feedMode: 'forYou',
        userId: 'me',
        rawMoments: [_post('p1', 'bad')],
      );
      await http.runWithClient(
        () => BlockService.blockUser(
          currentUserId: 'me',
          blockedUserId: 'bad',
          blockedUserName: 'Bad',
        ),
        () => MockClient((req) async => http.Response('{}', 500)),
      );
      final items =
          await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'me');
      expect(items!.map((m) => m['_id']), ['p1']);
      expect(await BlockedIdsStore().read(userId: 'me'), isEmpty);
    });

    test('an unblock forgets the remembered id', () async {
      await BlockedIdsStore().write(userId: 'me', ids: {'bad', 'other'});
      await http.runWithClient(
        () => BlockService.unblockUser(
            currentUserId: 'me', blockedUserId: 'bad'),
        () => MockClient((req) async => http.Response('{}', 200)),
      );
      expect(await BlockedIdsStore().read(userId: 'me'), {'other'});
    });
  });

  group('blockedUserIdsProvider', () {
    test('a fetched list is remembered; offline reads the last known one',
        () async {
      final ok = MockClient((req) async => http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'userId': 'b1', 'user': {'name': 'B1'}},
              ],
            }),
            200,
          ));
      expect(await http.runWithClient(_blockedIds, () => ok), {'b1'});

      final offline =
          MockClient((req) async => throw http.ClientException('offline'));
      expect(await http.runWithClient(_blockedIds, () => offline), {'b1'});
    });

    test('a fetched empty list replaces the remembered one', () async {
      await BlockedIdsStore().write(userId: 'me', ids: {'old'});
      final empty = MockClient((req) async =>
          http.Response(jsonEncode({'success': true, 'data': []}), 200));
      expect(await http.runWithClient(_blockedIds, () => empty), isEmpty);
    });

    test("another account's remembered ids are not used", () async {
      await BlockedIdsStore().write(userId: 'someone', ids: {'x'});
      final offline =
          MockClient((req) async => throw http.ClientException('offline'));
      expect(await http.runWithClient(_blockedIds, () => offline), isEmpty);
    });

    test('the remembered ids are user-scoped (cleared on sign-out)', () {
      expect(isDeviceLevelPrefsKey(BlockedIdsStore.key), isFalse);
    });
  });

  test('offline cold start: a cached post by a remembered blocked author '
      'is filtered out of the feed', () async {
    SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
    await FeedFirstPageCache().write(
      feedMode: 'forYou',
      userId: 'me',
      rawMoments: [_post('p1', 'bad'), _post('p2', 'ok')],
    );
    await BlockedIdsStore().write(userId: 'me', ids: {'bad'});
    final offline =
        MockClient((req) async => throw http.ClientException('offline'));
    await http.runWithClient(() async {
      final c = ProviderContainer(overrides: [
        forYouMomentsProvider.overrideWith(() => PagedMomentsFeedNotifier(
              (ref, page) async => throw Exception('offline'),
              cacheFeedMode: 'forYou',
            )),
      ]);
      addTearDown(c.dispose);
      final filtered = filteredMomentsForTabProvider(MomentsFeedTab.forYou);
      c.listen(filtered, (_, __) {});
      await c.read(forYouMomentsProvider.future);
      await c.read(blockedUserIdsProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        c.read(filtered).valueOrNull?.map((m) => m.id).toList(),
        ['p2'],
      );
    }, () => offline);
  });
}

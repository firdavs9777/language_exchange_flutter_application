import 'dart:convert';

import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/hashtag_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/moment_fixture.dart';

Map<String, dynamic> _raw(String id) {
  final m = buildMoment(id: id);
  return {...m.toJson(), 'user': m.user.toJson()};
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HashtagService', () {
    test('suggest parses tags and sends q', () async {
      late http.Request seen;
      final s = HashtagService(
        client: MockClient((r) async {
          seen = r;
          return _json({
            'success': true,
            'data': [
              {'tag': 'food', 'postCount': 4},
              {'tag': '한국어', 'postCount': 2},
            ],
          });
        }),
      );
      final out = await s.suggest('fo od');
      expect(out.map((e) => e.tag), ['food', '한국어']);
      expect(out.first.postCount, 4);
      expect(seen.url.path, endsWith('/hashtags/suggest'));
      expect(seen.url.queryParameters['q'], 'fo od');
    });

    test('trending parses and sends the bearer token when signed in', () async {
      SharedPreferences.setMockInitialValues({'token': 'tok'});
      late http.Request seen;
      final s = HashtagService(
        client: MockClient((r) async {
          seen = r;
          return _json({
            'success': true,
            'data': [
              {'tag': 'a', 'postCount': 1},
            ],
          });
        }),
      );
      expect((await s.trending()).single.tag, 'a');
      expect(seen.url.path, endsWith('/hashtags/trending'));
      expect(seen.headers['Authorization'], 'Bearer tok');
    });

    test('no Authorization header when signed out', () async {
      late http.Request seen;
      final s = HashtagService(
        client: MockClient((r) async {
          seen = r;
          return _json({'success': true, 'data': []});
        }),
      );
      await s.trending();
      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('404 is empty for all three calls', () async {
      final s = HashtagService(client: MockClient((r) async => _json({}, 404)));
      expect(await s.suggest('x'), isEmpty);
      expect(await s.trending(), isEmpty);
      final page = await s.moments('x');
      expect(page.moments, isEmpty);
      expect(page.hasNextPage, isFalse);
      expect(page.postCount, 0);
      expect(page.relatedTopic, isNull);
      expect(page.tag, 'x');
    });

    test('other failures throw', () async {
      final s = HashtagService(client: MockClient((r) async => _json({}, 500)));
      expect(s.suggest('x'), throwsException);
      expect(s.trending(), throwsException);
      expect(s.moments('x'), throwsException);
      final s401 = HashtagService(
        client: MockClient((r) async => _json({}, 401)),
      );
      expect(s401.trending(), throwsException);
    });

    test('moments path is percent-encoded, with sort/page/limit', () async {
      late http.Request seen;
      final s = HashtagService(
        client: MockClient((r) async {
          seen = r;
          return _json({
            'success': true,
            'tag': '한국어',
            'postCount': 0,
            'data': [],
            'pagination': {'currentPage': 2, 'totalPages': 2},
          });
        }),
      );
      await s.moments('한국어', sort: 'recent', page: 2, limit: 12);
      expect(
        seen.url.toString(),
        contains('hashtags/${Uri.encodeComponent('한국어')}/moments?'),
      );
      expect(seen.url.toString(), contains('%ED%95%9C'));
      expect(seen.url.queryParameters, {
        'sort': 'recent',
        'page': '2',
        'limit': '12',
      });
    });

    test(
      'moments parses tag, postCount, relatedTopic, moments, paging',
      () async {
        final s = HashtagService(
          client: MockClient(
            (r) async => _json({
              'success': true,
              'tag': 'cafe',
              'postCount': 7,
              'relatedTopic': 'coffee',
              'data': [_raw('m1'), _raw('m2')],
              'pagination': {'currentPage': 1, 'totalPages': 3},
            }),
          ),
        );
        final page = await s.moments('café');
        expect(page.tag, 'cafe');
        expect(page.postCount, 7);
        expect(page.relatedTopic, 'coffee');
        expect(page.moments.map((m) => m.id), ['m1', 'm2']);
        expect(page.moments.first, isA<Moments>());
        expect(page.hasNextPage, isTrue);
      },
    );

    test('last page has no next; missing relatedTopic is null', () async {
      final s = HashtagService(
        client: MockClient(
          (r) async => _json({
            'success': true,
            'tag': 'a',
            'postCount': 1,
            'data': [_raw('m1')],
            'pagination': {'currentPage': 3, 'totalPages': 3},
          }),
        ),
      );
      final page = await s.moments('a', page: 3);
      expect(page.hasNextPage, isFalse);
      expect(page.relatedTopic, isNull);
    });

    test('a malformed item is skipped, not fatal', () async {
      final s = HashtagService(
        client: MockClient(
          (r) async => _json({
            'success': true,
            'data': [
              {'tag': 'ok', 'postCount': 1},
              'junk',
              {'postCount': 3},
            ],
          }),
        ),
      );
      expect((await s.trending()).map((e) => e.tag), ['ok']);
    });
  });

  group('providers', () {
    test('hashtagPageProvider pages, de-duplicates and exposes meta', () async {
      final calls = <int>[];
      final service = HashtagService(
        client: MockClient((r) async {
          final page = int.parse(r.url.queryParameters['page']!);
          calls.add(page);
          return _json({
            'success': true,
            'tag': 'cafe',
            'postCount': 20,
            'relatedTopic': 'coffee',
            'data': page == 1
                ? [for (var i = 0; i < 12; i++) _raw('m$i')]
                : [_raw('m11'), _raw('m12')],
            'pagination': {'currentPage': page, 'totalPages': 2},
          });
        }),
      );
      final container = ProviderContainer(
        overrides: [hashtagServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      const key = (tag: 'café', sort: 'top');
      final p = hashtagPageProvider(key);
      container.listen(p, (_, __) {});
      final first = await container.read(p.future);
      expect(first.length, 12);
      await Future<void>.delayed(Duration.zero);
      final meta = container.read(hashtagPageMetaProvider(key));
      expect(meta?.tag, 'cafe');
      expect(meta?.postCount, 20);
      expect(meta?.relatedTopic, 'coffee');

      await container.read(p.notifier).loadMore();
      expect(container.read(p).value!.length, 13);
      expect(calls, [1, 2]);
      expect(container.read(p.notifier).hasMore, isFalse);
    });

    test('same key gives the same provider; sort changes the key', () {
      expect(
        hashtagPageProvider((tag: 'a', sort: 'top')),
        same(hashtagPageProvider((tag: 'a', sort: 'top'))),
      );
      expect(
        hashtagPageProvider((tag: 'a', sort: 'top')),
        isNot(same(hashtagPageProvider((tag: 'a', sort: 'recent')))),
      );
    });

    test('loadMore failure sets loadMoreFailed and retry recovers', () async {
      var fail = false;
      final service = HashtagService(
        client: MockClient((r) async {
          final page = int.parse(r.url.queryParameters['page']!);
          if (page == 2 && fail) return _json({}, 500);
          return _json({
            'success': true,
            'tag': 'a',
            'postCount': 20,
            'data': page == 1
                ? [for (var i = 0; i < 12; i++) _raw('m$i')]
                : [_raw('n1')],
            'pagination': {'currentPage': page, 'totalPages': 2},
          });
        }),
      );
      final container = ProviderContainer(
        overrides: [hashtagServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      const key = (tag: 'a', sort: 'recent');
      final p = hashtagPageProvider(key);
      container.listen(p, (_, __) {});
      await container.read(p.future);
      fail = true;
      await container.read(p.notifier).loadMore();
      expect(container.read(p.notifier).loadMoreFailed, isTrue);
      expect(container.read(p).value!.length, 12);
      fail = false;
      await container.read(p.notifier).retryLoadMore();
      expect(container.read(p.notifier).loadMoreFailed, isFalse);
      expect(container.read(p).value!.length, 13);
    });

    test('suggest and trending providers', () async {
      final service = HashtagService(
        client: MockClient(
          (r) async => _json({
            'success': true,
            'data': [
              {'tag': 'x', 'postCount': 1},
            ],
          }),
        ),
      );
      final container = ProviderContainer(
        overrides: [hashtagServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      container.listen(hashtagSuggestProvider('x'), (_, __) {});
      container.listen(trendingHashtagsProvider, (_, __) {});
      expect(
        (await container.read(hashtagSuggestProvider('x').future)).single.tag,
        'x',
      );
      expect(
        (await container.read(trendingHashtagsProvider.future)).single.tag,
        'x',
      );
    });

    test('page 404 gives an empty list, not an error', () async {
      final service = HashtagService(
        client: MockClient((r) async => _json({}, 404)),
      );
      final container = ProviderContainer(
        overrides: [hashtagServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final p = hashtagPageProvider((tag: 'a', sort: 'top'));
      container.listen(p, (_, __) {});
      expect(await container.read(p.future), isEmpty);
    });
  });
}

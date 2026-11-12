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

    test(
      'a tag with / ? # % is percent-encoded into one path segment',
      () async {
        late http.Request seen;
        final s = HashtagService(
          client: MockClient((r) async {
            seen = r;
            return _json({'success': true, 'data': []});
          }),
        );
        await s.moments('a/b?c#d%e');
        expect(
          seen.url.toString(),
          contains('hashtags/a%2Fb%3Fc%23d%25e/moments?'),
        );
        expect(seen.url.pathSegments.last, 'moments');
      expect(seen.url.pathSegments, contains('a/b?c#d%e'));
        expect(seen.url.hasFragment, isFalse);
      },
    );

    test('a tag with nothing usable makes no request', () async {
      var calls = 0;
      final s = HashtagService(
        client: MockClient((r) async {
          calls++;
          return _json({'success': true, 'data': []});
        }),
      );
      for (final t in ['', '#', '🍜', '  ']) {
        final page = await s.moments(t);
        expect(page.moments, isEmpty);
        expect(page.hasNextPage, isFalse);
      }
      expect(calls, 0);
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
    ProviderContainer containerFor(HashtagService service) {
      final c = ProviderContainer(
        overrides: [hashtagServiceProvider.overrideWithValue(service)],
      );
      addTearDown(c.dispose);
      return c;
    }

    Map<String, dynamic> pageBody(
      int page,
      List<String> ids, {
      int total = 2,
    }) => {
      'success': true,
      'tag': 'cafe',
      'postCount': 20,
      'relatedTopic': 'coffee',
      'data': [for (final id in ids) _raw(id)],
      'pagination': {'currentPage': page, 'totalPages': total},
    };

    test('key helper normalises, so one page per tag', () {
      expect(hashtagPageKey('#Food'), hashtagPageKey('food'));
      expect(hashtagPageKey('#Food')!.sort, 'top');
      expect(hashtagPageKey('🍜'), isNull);
    });

    test(
      'state carries server tag, counts, related topic; pages; dedupes',
      () async {
        final calls = <int>[];
        final c = containerFor(
          HashtagService(
            client: MockClient((r) async {
              final page = int.parse(r.url.queryParameters['page']!);
              calls.add(page);
              return _json(
                page == 1
                    ? pageBody(1, [for (var i = 0; i < 12; i++) 'm$i'])
                    : pageBody(2, ['m11', 'm12']),
              );
            }),
          ),
        );
        final p = hashtagPageProvider(hashtagPageKey('Café')!);
        c.listen(p, (_, __) {});
        final first = await c.read(p.future);
        expect(first.tag, 'cafe');
        expect(first.postCount, 20);
        expect(first.relatedTopic, 'coffee');
        expect(first.moments.length, 12);
        expect(first.hasMore, isTrue);

        await c.read(p.notifier).loadMore();
        final s = c.read(p).value!;
        expect(s.moments.length, 13);
        expect(s.hasMore, isFalse);
        expect(s.tag, 'cafe');
        expect(calls, [1, 2]);
      },
    );

    test(
      'failed loadMore keeps the list, stops, retry re-requests page 2',
      () async {
        var fail = true;
        final calls = <int>[];
        final c = containerFor(
          HashtagService(
            client: MockClient((r) async {
              final page = int.parse(r.url.queryParameters['page']!);
              calls.add(page);
              if (page == 2 && fail) return _json({}, 500);
              return _json(
                page == 1
                    ? pageBody(1, [for (var i = 0; i < 12; i++) 'm$i'])
                    : pageBody(2, ['n1']),
              );
            }),
          ),
        );
        final p = hashtagPageProvider(hashtagPageKey('a', sort: 'recent')!);
        c.listen(p, (_, __) {});
        await c.read(p.future);
        await c.read(p.notifier).loadMore();
        expect(c.read(p).value!.loadMoreFailed, isTrue);
        expect(c.read(p).value!.moments.length, 12);
        await c.read(p.notifier).loadMore(); // stays quiet while failed
        expect(calls, [1, 2]);
        fail = false;
        await c.read(p.notifier).retryLoadMore();
        expect(calls, [1, 2, 2]);
        expect(c.read(p).value!.loadMoreFailed, isFalse);
        expect(c.read(p).value!.moments.length, 13);
      },
    );

    test('auto-dispose: leaving and reopening refetches', () async {
      var calls = 0;
      final c = containerFor(
        HashtagService(
          client: MockClient((r) async {
            calls++;
            return _json(pageBody(1, ['m1'], total: 1));
          }),
        ),
      );
      final p = hashtagPageProvider(hashtagPageKey('a')!);
      final sub = c.listen(p, (_, __) {});
      await c.read(p.future);
      sub.close();
      await Future<void>.delayed(Duration.zero);
      c.listen(p, (_, __) {});
      await c.read(p.future);
      expect(calls, 2);
    });

    test('patchMomentInFeeds-style hooks reach open pages', () async {
      final c = containerFor(
        HashtagService(
          client: MockClient(
            (r) async => _json(pageBody(1, ['m1', 'm2'], total: 1)),
          ),
        ),
      );
      final p = hashtagPageProvider(hashtagPageKey('a')!);
      c.listen(p, (_, __) {});
      await c.read(p.future);
      HashtagPageNotifier.patchEverywhere(
        'm1',
        (m) => buildMoment(id: 'm1', description: 'edited'),
      );
      expect(c.read(p).value!.moments.first.description, 'edited');
      HashtagPageNotifier.removeEverywhere('m2');
      expect(c.read(p).value!.moments.map((m) => m.id), ['m1']);
    });

    test(
      'invalidate (sign-out reset) drops the old state and reloads',
      () async {
        var n = 0;
        final c = containerFor(
          HashtagService(
            client: MockClient((r) async {
              n++;
              return _json(pageBody(1, ['u$n'], total: 1));
            }),
          ),
        );
        final p = hashtagPageProvider(hashtagPageKey('a')!);
        c.listen(p, (_, __) {});
        expect((await c.read(p.future)).moments.single.id, 'u1');
        c.invalidate(hashtagPageProvider);
        expect((await c.read(p.future)).moments.single.id, 'u2');
      },
    );

    test('suggest and trending providers', () async {
      final c = containerFor(
        HashtagService(
          client: MockClient(
            (r) async => _json({
              'success': true,
              'data': [
                {'tag': 'x', 'postCount': 1},
              ],
            }),
          ),
        ),
      );
      c.listen(hashtagSuggestProvider('x'), (_, __) {});
      c.listen(trendingHashtagsProvider, (_, __) {});
      expect(
        (await c.read(hashtagSuggestProvider('x').future)).single.tag,
        'x',
      );
      expect((await c.read(trendingHashtagsProvider.future)).single.tag, 'x');
    });

    test('page 404 gives an empty page, not an error', () async {
      final c = containerFor(
        HashtagService(client: MockClient((r) async => _json({}, 404))),
      );
      final p = hashtagPageProvider(hashtagPageKey('a')!);
      c.listen(p, (_, __) {});
      final s = await c.read(p.future);
      expect(s.moments, isEmpty);
      expect(s.hasMore, isFalse);
    });
  });
}

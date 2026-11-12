import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/feed/moment_card_skeleton.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_feed_widget.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show MomentsFeedTab, filteredMomentsForTabProvider;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/feed_first_page_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/moment_fixture.dart';

// Moments.toJson omits the author, so add it the way the server sends it.
Map<String, dynamic> _raw(String id) {
  final m = buildMoment(id: id);
  return {...m.toJson(), 'user': m.user.toJson()};
}

List<String> _ids(List<Moments>? m) => (m ?? []).map((e) => e.id).toList();

typedef _Provider
    = AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>;

_Provider _provider(MomentsPageFetcher fetch) =>
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      () => PagedMomentsFeedNotifier(fetch, cacheFeedMode: 'forYou'),
    );

Future<void> _seed(List<String> ids, {String userId = 'u1'}) =>
    FeedFirstPageCache().write(
      feedMode: 'forYou',
      userId: userId,
      rawMoments: [for (final id in ids) _raw(id)],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'u1'}));

  test('cached list is emitted first, then the fresh page replaces it',
      () async {
    await _seed(['old1', 'old2']);
    final gate = Completer<void>();
    final p = _provider((ref, page) async {
      await gate.future;
      return MomentsFeedPage(
        [buildMoment(id: 'new1'), buildMoment(id: 'old1')],
        hasMore: true,
      );
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final seen = <List<String>>[];
    container.listen(p, (_, next) {
      final v = next.valueOrNull;
      if (v != null) seen.add(_ids(v));
    });
    final fresh = container.read(p.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen, [
      ['old1', 'old2'],
    ]);
    gate.complete();
    await fresh;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, ['new1', 'old1']);
    expect(container.read(p.notifier).hasMore, isTrue);
  });

  test('a failing fetch keeps the cached list', () async {
    await _seed(['old1', 'old2']);
    final p = _provider((ref, page) async => throw Exception('offline'));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final result = await container.read(p.future);
    expect(_ids(result), ['old1', 'old2']);
    expect(container.read(p).hasError, isFalse);
  });

  test('an unparseable cached item is dropped', () async {
    await FeedFirstPageCache().write(
      feedMode: 'forYou',
      userId: 'u1',
      rawMoments: [
        _raw('ok'),
        {'_id': 'bad', 'user': 'not-a-map'},
      ],
    );
    final p = _provider((ref, page) async => throw Exception('offline'));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(_ids(await container.read(p.future)), ['ok']);
  });

  test('no parseable cached item behaves as no cache', () async {
    await FeedFirstPageCache().write(
      feedMode: 'forYou',
      userId: 'u1',
      rawMoments: [
        {'_id': 'bad', 'user': 'not-a-map'},
      ],
    );
    final p = _provider((ref, page) async => throw Exception('offline'));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(container.read(p.future), throwsException);
  });

  test('another user\'s cache is not shown; no user id reads and writes nothing',
      () async {
    await _seed(['old1'], userId: 'someone-else');
    final p = _provider((ref, page) async => MomentsFeedPage(
          [buildMoment(id: 'new1')],
          hasMore: false,
          rawMoments: [_raw('new1')],
        ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(_ids(await container.read(p.future)), ['new1']);

    SharedPreferences.setMockInitialValues({});
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    await c2.read(p.future);
    expect(
      await FeedFirstPageCache().read(feedMode: 'forYou', userId: ''),
      isNull,
    );
  });

  test('a successful page 1 is written to the cache; later pages are not',
      () async {
    final p = _provider((ref, page) async => MomentsFeedPage(
          [buildMoment(id: 'p$page')],
          hasMore: page < 2,
          rawMoments: [_raw('p$page')],
        ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(p.future);
    await container.read(p.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final cached = await FeedFirstPageCache()
        .read(feedMode: 'forYou', userId: 'u1');
    expect(cached!.map((m) => m['_id']), ['p1']);
  });

  test('an empty fresh page clears the cached posts', () async {
    await _seed(['old1']);
    final p = _provider((ref, page) async => const MomentsFeedPage(
          <Moments>[],
          hasMore: false,
          rawMoments: <Map<String, dynamic>>[],
        ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(p, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(container.read(p).valueOrNull, isEmpty);
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    // A cold start now finds no cache: a failing fetch surfaces the error.
    final failing = _provider((ref, page) async => throw Exception('x'));
    await expectLater(c2.read(failing.future), throwsException);
  });

  test('a fetch that outlives an account switch writes nothing', () async {
    final gate = Completer<void>();
    final p = _provider((ref, page) async {
      await gate.future;
      return MomentsFeedPage(
        [buildMoment(id: 'new1')],
        hasMore: false,
        rawMoments: [_raw('new1')],
      );
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final f = container.read(p.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    SharedPreferences.setMockInitialValues({'userId': 'u2'});
    gate.complete();
    await f;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'u1'),
        isNull);
    expect(await FeedFirstPageCache().read(feedMode: 'forYou', userId: 'u2'),
        isNull);
  });

  test('a cached list waits for the block list; a blocked author never shows',
      () async {
    await _seed(['b1', 'b2']);
    final fetchGate = Completer<void>();
    final blockedGate = Completer<Set<String>>();
    final container = ProviderContainer(overrides: [
      forYouMomentsProvider.overrideWith(() => PagedMomentsFeedNotifier(
            (ref, page) async {
              await fetchGate.future;
              return const MomentsFeedPage(<Moments>[], hasMore: false);
            },
            cacheFeedMode: 'forYou',
          )),
      blockedUserIdsProvider.overrideWith((ref) => blockedGate.future),
    ]);
    addTearDown(container.dispose);
    final filtered = filteredMomentsForTabProvider(MomentsFeedTab.forYou);
    container.listen(filtered, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(container.read(filtered).isLoading, isTrue);
    expect(container.read(filtered).valueOrNull, isNull);

    blockedGate.complete({'author-b1'});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(_ids(container.read(filtered).valueOrNull), ['b2']);
  });

  group('a rebuild with a list in hand does not repaint the disk cache', () {
    // The cache still holds the pre-like JSON; a like followed by the feed
    // refresh it triggers must never show the like undone.
    test('a like survives softRefresh on page 1; hasMore never flips',
        () async {
      await _seed(['m1', 'm2']);
      var calls = 0;
      final second = Completer<void>();
      final p = _provider((ref, page) async {
        calls++;
        if (calls == 1) {
          return MomentsFeedPage(
            [buildMoment(id: 'm1'), buildMoment(id: 'm2')],
            hasMore: true,
            rawMoments: [_raw('m1'), _raw('m2')],
          );
        }
        await second.future;
        return MomentsFeedPage(
          [buildMoment(id: 'm1', likeCount: 1), buildMoment(id: 'm2')],
          hasMore: true,
        );
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(p.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(p.notifier);
      final likes = <int>[];
      final hasMore = <bool>[];
      container.listen(p, (_, next) {
        final v = next.valueOrNull;
        if (v != null) likes.add(v.first.likeCount);
        hasMore.add(notifier.hasMore);
      });
      notifier.patchMoment('m1', (m) => m.copyWith(likeCount: 1));
      await notifier.softRefresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      second.complete();
      await container.read(p.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(likes, isNotEmpty);
      expect(likes, everyElement(1));
      expect(hasMore, everyElement(isTrue));
      expect(container.read(p).value!.first.likeCount, 1);
    });

    test('a like made while the cached page shows survives the refresh',
        () async {
      await _seed(['m1', 'm2']);
      final gate = Completer<void>();
      final p = _provider((ref, page) async {
        await gate.future;
        return MomentsFeedPage(
          [buildMoment(id: 'm1', likeCount: 1), buildMoment(id: 'm2')],
          hasMore: false,
        );
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(p, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(p.notifier);
      final likes = <int>[];
      container.listen(p, (_, next) {
        final v = next.valueOrNull;
        if (v != null) likes.add(v.first.likeCount);
      });
      notifier.patchMoment('m1', (m) => m.copyWith(likeCount: 1));
      await notifier.softRefresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      gate.complete();
      await container.read(p.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(likes, everyElement(1));
    });

    test('a removed post does not come back when the refetch fails',
        () async {
      await _seed(['m1', 'm2']);
      var calls = 0;
      final p = _provider((ref, page) async {
        calls++;
        if (calls > 1) throw Exception('offline');
        return MomentsFeedPage(
          [buildMoment(id: 'm1'), buildMoment(id: 'm2')],
          hasMore: false,
          rawMoments: [_raw('m1'), _raw('m2')],
        );
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final seen = <List<String>>[];
      await container.read(p.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      container.listen(p, (_, next) {
        final v = next.valueOrNull;
        if (v != null) seen.add(_ids(v));
      });
      container.read(p.notifier).removeMoment('m1');
      container.invalidate(p);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(seen, isNotEmpty);
      for (final ids in seen) {
        expect(ids, isNot(contains('m1')));
      }
      expect(_ids(container.read(p).valueOrNull), ['m2']);
    });

    test('a removed post is not in the cached list on the next cold start',
        () async {
      final p = _provider((ref, page) async => MomentsFeedPage(
            [buildMoment(id: 'm1'), buildMoment(id: 'm2')],
            hasMore: false,
            rawMoments: [_raw('m1'), _raw('m2')],
          ));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(p.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      container.read(p.notifier).removeMoment('m1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final offline = _provider((ref, page) async => throw Exception('x'));
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect(_ids(await c2.read(offline.future)), ['m2']);
    });
  });

  Widget host(AsyncValue<List<Moments>> value, {Brightness? b}) =>
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(brightness: b ?? Brightness.light),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MomentsFeedWidget(
              momentsAsync: value,
              isSearching: false,
              onRefresh: () {},
              activeTab: MomentsFeedTab.forYou,
            ),
          ),
        ),
      );

  testWidgets('no cache and loading shows skeleton cards, not a spinner',
      (tester) async {
    await tester.pumpWidget(host(const AsyncValue<List<Moments>>.loading()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('feed-skeleton')), findsOneWidget);
    expect(find.byType(MomentCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('skeletons then posts', (tester) async {
    await tester.pumpWidget(host(const AsyncValue<List<Moments>>.loading()));
    await tester.pumpWidget(host(AsyncValue.data(
      [buildMoment(id: 'a', description: 'hello feed')],
    )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('feed-skeleton')), findsNothing);
    expect(find.text('hello feed'), findsOneWidget);
  });

  testWidgets('skeleton lays out in dark theme at 320 px without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(
      const AsyncValue<List<Moments>>.loading(),
      b: Brightness.dark,
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(MomentCardSkeleton), findsWidgets);
  });
}

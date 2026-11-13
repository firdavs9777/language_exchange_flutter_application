import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

/// The card feed tabs used to fetch one page of 50 and stop.
List<Moments> _ids(Iterable<String> ids) =>
    ids.map((id) => buildMoment(id: id)).toList();

List<String> _idsOf(List<Moments>? moments) =>
    (moments ?? const <Moments>[]).map((m) => m.id).toList();

/// A three-page feed of two items per page; page 1 can be changed between
/// reads to simulate a new post.
class _FakeFeed {
  List<String> page1 = ['a', 'b'];
  final Map<int, List<String>> rest = {
    2: ['c', 'd'],
    3: ['e'],
  };
  final List<int> requested = [];
  bool failNext = false;

  Future<MomentsFeedPage> fetch(Ref ref, int page) async {
    requested.add(page);
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    final ids = page == 1 ? page1 : (rest[page] ?? const <String>[]);
    return MomentsFeedPage(_ids(ids), hasMore: page < 3);
  }
}

void main() {
  late _FakeFeed feed;
  late AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>> provider;
  late ProviderContainer container;

  setUp(() {
    feed = _FakeFeed();
    provider = AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      () => PagedMomentsFeedNotifier(feed.fetch),
    );
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  test('loadMore appends pages until the end', () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    expect(notifier.hasMore, isTrue);

    await notifier.loadMore();
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b', 'c', 'd']);
    await notifier.loadMore();
    expect(_idsOf(container.read(provider).valueOrNull),
        ['a', 'b', 'c', 'd', 'e']);
    expect(notifier.hasMore, isFalse);

    await notifier.loadMore();
    expect(feed.requested, [1, 2, 3], reason: 'no request past the end');
  });

  test('a failed page keeps the list and the next try fetches it again',
      () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    feed.failNext = true;
    await notifier.loadMore();
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b']);
    await notifier.loadMore();
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b', 'c', 'd']);
  });

  test('softRefresh re-reads page 1 and keeps the pages below', () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.loadMore();

    feed.page1 = ['new', 'a']; // a new post pushes 'b' to page 2
    await notifier.softRefresh();
    expect(_idsOf(container.read(provider).valueOrNull),
        ['new', 'a', 'c', 'd']);
  });

  test('invalidate reloads from page 1', () async {
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();
    container.invalidate(provider);
    expect(_idsOf(await container.read(provider.future)), ['a', 'b']);
  });

  test('appendMomentsPage drops repeats', () {
    expect(
      _idsOf(appendMomentsPage(_ids(['a', 'b']), _ids(['b', 'c']))),
      ['a', 'b', 'c'],
    );
  });

  test('mergeFreshFirstPage replaces only the first page', () {
    expect(
      _idsOf(mergeFreshFirstPage(_ids(['x', 'a']), _ids(['a', 'b', 'c']), 2)),
      ['x', 'a', 'c'],
    );
  });

  test('a feed page is 12 posts', () {
    expect(kMomentsFeedPageSize, 12);
  });

  test('a failed page sets loadMoreFailed and keeps the posts', () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    expect(notifier.loadMoreFailed, isFalse);
    feed.failNext = true;
    await notifier.loadMore();
    expect(notifier.loadMoreFailed, isTrue);
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b']);
    expect(notifier.hasMore, isTrue);
  });

  test('flipping loadMoreFailed notifies watchers', () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    var notified = 0;
    container.listen(provider, (_, __) => notified++);
    feed.failNext = true;
    await notifier.loadMore();
    expect(notified, 1);
    await notifier.retryLoadMore();
    expect(notified, 2, reason: 'the success rewrites the list');
  });

  test('retryLoadMore asks for the failed page again, once, without repeats',
      () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    feed.failNext = true;
    await notifier.loadMore();
    await notifier.retryLoadMore();
    expect(feed.requested, [1, 2, 2]);
    expect(notifier.loadMoreFailed, isFalse);
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b', 'c', 'd']);
  });

  test('a page of posts already shown appends nothing', () async {
    feed.rest[2] = ['a', 'b'];
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.loadMore();
    expect(_idsOf(container.read(provider).valueOrNull), ['a', 'b']);
    expect(notifier.loadMoreFailed, isFalse);
  });

  test('a reload clears loadMoreFailed', () async {
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    feed.failNext = true;
    await notifier.loadMore();
    container.invalidate(provider);
    await container.read(provider.future);
    expect(container.read(provider.notifier).loadMoreFailed, isFalse);
  });

  test('pull-to-refresh refetches page 1 even right after a fetch', () async {
    await container.read(provider.future);
    expect(feed.requested, [1]);
    // What MomentsMain._refresh does; the 60 s gate is only in
    // refreshMomentsIfStale.
    await container.refresh(provider.future);
    expect(feed.requested, [1, 1]);
  });

  test('the feed fetcher asks the server for 12 per page', () async {
    final limits = <int>[];
    final c = ProviderContainer(overrides: [
      momentsServiceProvider.overrideWithValue(_LimitSpy(limits)),
    ]);
    addTearDown(c.dispose);
    final p = AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      () => PagedMomentsFeedNotifier(momentsFeedFetcher('forYou')),
    );
    await c.read(p.future);
    expect(limits, [12]);
  });
}

class _LimitSpy extends MomentsService {
  _LimitSpy(this.limits);
  final List<int> limits;

  @override
  Future<Map<String, dynamic>> getMoments(
      {int page = 1, int limit = 10, String? feed, String? q}) async {
    limits.add(limit);
    return {'moments': <Moments>[], 'pagination': {'hasNextPage': false}};
  }
}

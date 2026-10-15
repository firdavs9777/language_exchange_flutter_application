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
}

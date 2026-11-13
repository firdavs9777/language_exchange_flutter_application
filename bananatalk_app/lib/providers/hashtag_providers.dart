import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart'
    show appendMomentsPage, kMomentsFeedPageSize;
import 'package:bananatalk_app/services/hashtag_service.dart';
import 'package:bananatalk_app/utils/hashtag_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hashtagServiceProvider = Provider<HashtagService>(
  (ref) => HashtagService(),
);

/// Suggestions for what the user typed after `#`.
final hashtagSuggestProvider = FutureProvider.autoDispose
    .family<List<HashtagCount>, String>(
      (ref, query) => ref.watch(hashtagServiceProvider).suggest(query),
    );

final trendingHashtagsProvider = FutureProvider.autoDispose<List<HashtagCount>>(
  (ref) => ref.watch(hashtagServiceProvider).trending(),
);

/// Key of a hashtag page: a tag cleaned with [normalizeHashtag] (build it
/// with [hashtagPageKey], so `Food`, `food` and `#food` are one page) and
/// the sort, `top` or `recent`. A record, so it is value-equal.
typedef HashtagPageKey = ({String tag, String sort});

/// The key for what the user typed or tapped; null when nothing usable is
/// left of it (there is no page to open).
HashtagPageKey? hashtagPageKey(String raw, {String sort = 'top'}) {
  final tag = normalizeHashtag(raw);
  return tag == null ? null : (tag: tag, sort: sort);
}

/// Everything a hashtag page shows. [tag] is as the server returned it (the
/// accent-folded form): display this once the page has loaded.
class HashtagPageState {
  const HashtagPageState({
    required this.tag,
    required this.postCount,
    this.relatedTopic,
    required this.moments,
    required this.hasMore,
    this.loadMoreFailed = false,
  });

  final String tag;
  final int postCount;
  final String? relatedTopic;
  final List<Moments> moments;

  /// Another page may exist below the loaded ones.
  final bool hasMore;

  /// The last [HashtagPageNotifier.loadMore] failed: show a Retry row and do
  /// not ask again by itself.
  final bool loadMoreFailed;

  HashtagPageState copyWith({
    List<Moments>? moments,
    bool? hasMore,
    bool? loadMoreFailed,
  }) => HashtagPageState(
    tag: tag,
    postCount: postCount,
    relatedTopic: relatedTopic,
    moments: moments ?? this.moments,
    hasMore: hasMore ?? this.hasMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// A hashtag page, paged like the feed (12 per page, de-duplicated by id).
/// Auto-dispose: reopening a page refetches it, leaving it frees it.
/// `ref.invalidate(hashtagPageProvider(key))` reloads page 1.
class HashtagPageNotifier
    extends AutoDisposeFamilyAsyncNotifier<HashtagPageState, HashtagPageKey> {
  /// The pages alive right now, so a like or delete made on a card reaches
  /// them like it reaches the feed tabs (see `patchMomentInFeeds`).
  static final Set<HashtagPageNotifier> _live = {};

  /// Applies [update] to moment [id] on every open hashtag page.
  static void patchEverywhere(String id, Moments Function(Moments) update) {
    for (final n in _live.toList()) {
      n.patchMoment(id, update);
    }
  }

  /// Drops moment [id] from every open hashtag page.
  static void removeEverywhere(String id) {
    for (final n in _live.toList()) {
      n.removeMoment(id);
    }
  }

  int _page = 1;
  bool _loadingMore = false;

  /// Bumped by every [build]; a load-more started under an older value
  /// belongs to the replaced list and writes nothing (during a reload the
  /// state still holds that list as its previous value).
  int _generation = 0;

  // Riverpod 2 has no `ref.mounted`: a fetch that lands after the page was
  // left must not write state.
  bool _alive = true;

  @override
  Future<HashtagPageState> build(HashtagPageKey arg) async {
    _live.add(this);
    _alive = true;
    ref.onDispose(() {
      _alive = false;
      _live.remove(this);
    });
    _generation++;
    _page = 1;
    _loadingMore = false;
    final first = await ref
        .read(hashtagServiceProvider)
        .moments(arg.tag, sort: arg.sort, limit: kMomentsFeedPageSize);
    return HashtagPageState(
      tag: first.tag,
      postCount: first.postCount,
      relatedTopic: first.relatedTopic,
      moments: first.moments,
      hasMore: first.hasNextPage && first.moments.isNotEmpty,
    );
  }

  /// Appends the next page. No-op while loading, before page 1, at the end,
  /// or while a failure waits for [retryLoadMore]. A failure keeps the list
  /// and sets `loadMoreFailed`; the page counter moves only on success.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        !current.hasMore ||
        current.loadMoreFailed ||
        _loadingMore) {
      return;
    }
    await _fetchNext(current);
  }

  /// The Retry row's action: asks again for the page that failed.
  Future<void> retryLoadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        !current.hasMore ||
        _loadingMore) {
      return;
    }
    await _fetchNext(current);
  }

  Future<void> _fetchNext(HashtagPageState current) async {
    _loadingMore = true;
    final generation = _generation;
    bool stale() =>
        !_alive ||
        generation != _generation ||
        !identical(state.valueOrNull, current);
    try {
      final next = await ref
          .read(hashtagServiceProvider)
          .moments(
            arg.tag,
            sort: arg.sort,
            page: _page + 1,
            limit: kMomentsFeedPageSize,
          );
      // Reloaded or disposed meanwhile: this page belongs to the old list.
      if (stale()) return;
      _page += 1;
      state = AsyncData(
        current.copyWith(
          moments: appendMomentsPage(current.moments, next.moments),
          hasMore: next.hasNextPage && next.moments.isNotEmpty,
          loadMoreFailed: false,
        ),
      );
    } catch (_) {
      if (!stale()) {
        state = AsyncData(current.copyWith(loadMoreFailed: true));
      }
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }

  /// Replaces moment [id] in the loaded pages (like, edit, save).
  void patchMoment(String id, Moments Function(Moments) update) {
    final current = state.valueOrNull;
    if (current == null || !current.moments.any((m) => m.id == id)) return;
    state = AsyncData(
      current.copyWith(
        moments: [for (final m in current.moments) m.id == id ? update(m) : m],
      ),
    );
  }

  /// Drops moment [id] from the loaded pages (deleted).
  void removeMoment(String id) {
    final current = state.valueOrNull;
    if (current == null || !current.moments.any((m) => m.id == id)) return;
    state = AsyncData(
      current.copyWith(
        moments: [
          for (final m in current.moments)
            if (m.id != id) m,
        ],
      ),
    );
  }
}

/// `ref.watch(hashtagPageProvider(hashtagPageKey('Café')!))`.
final hashtagPageProvider = AsyncNotifierProvider.autoDispose
    .family<HashtagPageNotifier, HashtagPageState, HashtagPageKey>(
      HashtagPageNotifier.new,
    );

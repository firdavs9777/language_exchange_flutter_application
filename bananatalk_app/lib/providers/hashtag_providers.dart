import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/hashtag_service.dart';
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

/// Key of a hashtag page: the tag as typed or tapped, and `top` / `recent`.
typedef HashtagPageKey = ({String tag, String sort});

/// The page-level fields (server-normalised `tag`, `postCount`,
/// `relatedTopic`) of a hashtag page; null until page 1 has loaded (and while
/// the server switch is off, when page 1 is empty).
final hashtagPageMetaProvider =
    StateProvider.family<HashtagPageMeta?, HashtagPageKey>((ref, key) => null);

typedef HashtagPagedProvider =
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>;

HashtagPagedProvider _buildHashtagPage(HashtagPageKey key) =>
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      // No cacheFeedMode: a hashtag page keeps nothing on disk.
      () => PagedMomentsFeedNotifier((ref, page) async {
        final result = await ref
            .read(hashtagServiceProvider)
            .moments(
              key.tag,
              sort: key.sort,
              page: page,
              limit: kMomentsFeedPageSize,
            );
        if (page == 1) {
          // Deferred: no other provider is written from inside a build.
          Future.microtask(() {
            ref
                .read(hashtagPageMetaProvider(key).notifier)
                .state = result.moments.isEmpty && result.postCount == 0
                ? null
                : HashtagPageMeta(
                    tag: result.tag,
                    postCount: result.postCount,
                    relatedTopic: result.relatedTopic,
                  );
          });
        }
        return MomentsFeedPage(result.moments, hasMore: result.hasNextPage);
      }),
    );

/// The moments of a hashtag page, paged like the feed
/// (`loadMore`, `loadMoreFailed`, `retryLoadMore`, id de-duplication).
/// Call as `hashtagPageProvider((tag: 'café', sort: 'top'))`; one provider
/// per key, created once and reused. Read the page-level fields with
/// [hashtagPageMetaProvider] under the same key.
class HashtagPageProviderFamily {
  const HashtagPageProviderFamily();

  static final Map<HashtagPageKey, HashtagPagedProvider> _cache = {};

  HashtagPagedProvider call(HashtagPageKey key) =>
      _cache.putIfAbsent(key, () => _buildHashtagPage(key));
}

const hashtagPageProvider = HashtagPageProviderFamily();

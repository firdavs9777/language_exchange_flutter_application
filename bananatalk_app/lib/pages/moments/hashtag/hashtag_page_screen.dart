import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/pages/moments/feed/feed_load_more_footer.dart';
import 'package:bananatalk_app/pages/moments/feed/moment_card_skeleton.dart';
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/utils/hidden_authors.dart';
import 'package:bananatalk_app/utils/hashtag_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A hashtag's page: post count, Top / Recent, the moments, a banner when
/// the server fell back to a related topic. [tag] is the route parameter
/// (percent-encoded, with or without `#`). With the server switch off the
/// endpoint answers 404, which reads as an empty page.
class HashtagPageScreen extends ConsumerStatefulWidget {
  const HashtagPageScreen({super.key, required this.tag});

  final String tag;

  @override
  ConsumerState<HashtagPageScreen> createState() => _HashtagPageScreenState();
}

class _HashtagPageScreenState extends ConsumerState<HashtagPageScreen> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typed = normalizeHashtag(widget.tag);
    final key = hashtagPageKey(widget.tag, sort: _sort);
    final page = key == null ? null : ref.watch(hashtagPageProvider(key));
    // As typed until the page loads, then the server's form of the tag.
    final shownTag = page?.valueOrNull?.tag ?? typed ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('#$shownTag')),
      body: Column(
        children: [
          _Header(
            sort: _sort,
            postCount: page?.valueOrNull?.postCount,
            onSort: (sort) => setState(() => _sort = sort),
          ),
          if (page?.valueOrNull?.relatedTopic case final topic?)
            Container(
              key: const ValueKey('hashtag-related'),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderMD,
              ),
              child: Text(
                l10n.hashtagShowingRelated(topic),
                style: context.bodySmall,
              ),
            ),
          Expanded(
            child: key == null || page == null
                ? _Empty(message: l10n.hashtagEmpty)
                : page.when(
                    data: (state) => state.moments.isEmpty
                        ? _Empty(message: l10n.hashtagEmpty)
                        : _MomentList(pageKey: key, state: state),
                    loading: () => ListView.builder(
                      key: const ValueKey('hashtag-skeleton'),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (_, __) => const MomentCardSkeleton(),
                    ),
                    error: (_, __) => _Failed(
                      onRetry: () => ref.invalidate(hashtagPageProvider(key)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.sort,
    required this.postCount,
    required this.onSort,
  });

  final String sort;
  final int? postCount;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: postCount == null
                ? const SizedBox.shrink()
                : Text(
                    l10n.hashtagPostCount(postCount!),
                    style: context.bodyMedium,
                  ),
          ),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'top', label: Text(l10n.hashtagSortTop)),
              ButtonSegment(
                value: 'recent',
                label: Text(l10n.hashtagSortRecent),
              ),
            ],
            selected: {sort},
            onSelectionChanged: (s) => onSort(s.single),
          ),
        ],
      ),
    );
  }
}

class _MomentList extends ConsumerWidget {
  const _MomentList({required this.pageKey, required this.state});

  final HashtagPageKey pageKey;
  final HashtagPageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(hashtagPageProvider(pageKey).notifier);
    // Same client-side filter as the feed: mute is local only, and the
    // block list includes the remembered one when it cannot be fetched.
    final moments = withoutHiddenAuthors(
      state.moments,
      blocked: ref.watch(blockedUserIdsProvider).valueOrNull ?? <String>{},
      muted: ref.watch(mutedMomentsProvider),
    );
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: moments.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == moments.length) {
          // Built only once the list is scrolled to its end: ask for more
          // (a no-op while loading or after a failure).
          if (!state.loadMoreFailed) {
            Future.microtask(notifier.loadMore);
          }
          return FeedLoadMoreFooter(
            failed: state.loadMoreFailed,
            onRetry: notifier.retryLoadMore,
          );
        }
        final moment = moments[index];
        return MomentCard(
          key: ValueKey(moment.id),
          moments: moment,
          onRefresh: () => ref.invalidate(hashtagPageProvider(pageKey)),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Icon(Icons.tag, size: 80, color: context.textHint),
              Spacing.gapLG,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.textMuted),
          Spacing.gapLG,
          Text(
            l10n.failedToLoadMoments,
            style: context.bodyLarge.copyWith(color: context.textSecondary),
          ),
          Spacing.gapSM,
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retry,
              style: context.labelLarge.copyWith(color: context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

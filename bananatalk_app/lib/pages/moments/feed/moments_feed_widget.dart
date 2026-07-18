import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show momentFilterProvider, MomentsFeedTab;
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart' show selectedTabProvider;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Index of the Community tab in `TabsScreen`'s page list (see
/// `lib/pages/menu_tab/TabBarMenu.dart`) — used by the Following empty state
/// to jump straight to Community so the user can follow people.
const int _communityTabIndex = 1;

/// Ad cadence: 1 native ad per this many organic moments.
const int _adEveryNPosts = 4;

/// Sentinel used in the interleaved feed item list to mark an ad slot.
/// Kept distinct from `Moments` so `itemBuilder` can tell items apart with
/// a simple type check.
class _AdSlot {
  const _AdSlot();
}

const _adSlot = _AdSlot();

/// Builds the single, explicit list of feed items (moments interspersed
/// with ad slots) that both drives `itemCount` and `itemBuilder` — so the
/// ad placement and the total item count can never drift apart (see I3 in
/// the moments audit: the previous index-math derived these separately and
/// both overshot/degraded to a much denser ad cadence than intended).
List<Object> _buildFeedItems(List<Moments> moments) {
  final items = <Object>[];
  for (var i = 0; i < moments.length; i++) {
    items.add(moments[i]);
    final isLastMoment = i == moments.length - 1;
    if (!isLastMoment && (i + 1) % _adEveryNPosts == 0) {
      items.add(_adSlot);
    }
  }
  return items;
}

/// Renders the scrollable moments feed (with ad-every-4 insertion) and the
/// matching empty-state / error-state views.  All data is supplied by the
/// orchestrator (`MomentsMain`) so this widget has no direct provider
/// dependencies beyond `momentFilterProvider` (needed for the clear-filters
/// button in the empty-state) and `selectedTabProvider` (Following empty
/// state's "Go to Community" action).
class MomentsFeedWidget extends ConsumerWidget {
  final AsyncValue<List<Moments>> momentsAsync;
  final ScrollController scrollController;
  final bool isSearching;
  final VoidCallback onRefresh;

  /// Which feed tab is currently active (For You / Following / Trending).
  /// Drives the copy shown in the empty state when there are no moments and
  /// no search/filter is active.
  final MomentsFeedTab activeTab;

  const MomentsFeedWidget({
    super.key,
    required this.momentsAsync,
    required this.scrollController,
    required this.isSearching,
    required this.onRefresh,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return momentsAsync.when(
      // Stale-while-revalidate refreshes (`refreshMomentsIfStale`) invalidate
      // the feed providers silently on tab-return/60s — don't flash the full
      // spinner over the still-valid previous list while that refetch runs.
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        // Interleave 1 native ad per _adEveryNPosts organic moments. The
        // item list is built explicitly (rather than derived from index
        // math) so placement and itemCount can never drift apart, and
        // there's no phantom trailing item.
        final items = _buildFeedItems(moments);

        return ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is! Moments) {
              return const NativeAdWidget();
            }

            return MomentCard(moments: item, onRefresh: onRefresh)
                .animate(
                  // Stable key (mirrors the comments list's per-item keys)
                  // so a card's local like/save state doesn't bind to the
                  // wrong moment if the list reorders/refreshes.
                  key: ValueKey(item.id),
                )
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: (index * 60).clamp(0, 600)),
                )
                .slideY(
                  begin: 0.03,
                  end: 0,
                  duration: 300.ms,
                  delay: Duration(milliseconds: (index * 60).clamp(0, 600)),
                  curve: Curves.easeOutCubic,
                );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.textMuted,
            ),
            Spacing.gapLG,
            Text(
              AppLocalizations.of(context)!.failedToLoadMoments,
              style: context.bodyLarge.copyWith(color: context.textSecondary),
            ),
            Spacing.gapSM,
            TextButton(
              onPressed: onRefresh,
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: context.labelLarge.copyWith(color: context.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(momentFilterProvider);
    final l10n = AppLocalizations.of(context)!;
    final noSearchOrFilter = !isSearching && !currentFilter.hasActiveFilters;
    final isFollowingEmpty = noSearchOrFilter && activeTab == MomentsFeedTab.following;

    final IconData icon = isSearching
        ? Icons.search_off
        : currentFilter.hasActiveFilters
        ? Icons.filter_alt_off
        : isFollowingEmpty
        ? Icons.person_add_alt_1_outlined
        : Icons.chat_bubble_outline;

    final String title = isSearching
        ? l10n.noResultsFound
        : currentFilter.hasActiveFilters
        ? l10n.noMomentsMatchFilters
        : isFollowingEmpty
        ? l10n.noFollowingMomentsTitle
        : l10n.noForYouMomentsTitle;

    final String body = isSearching
        ? l10n.tryDifferentSearch
        : currentFilter.hasActiveFilters
        ? l10n.tryAdjustingFilters
        : isFollowingEmpty
        ? l10n.noFollowingMomentsBody
        : l10n.noForYouMomentsBody;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 80,
                color: context.textHint,
              ),
              Spacing.gapLG,
              Text(
                title,
                style: context.titleLarge,
              ),
              Spacing.gapSM,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: context.bodySmall,
                ),
              ),
              if (currentFilter.hasActiveFilters) ...[
                Spacing.gapLG,
                ElevatedButton(
                  onPressed: () {
                    ref.read(momentFilterProvider.notifier).clearFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderXL,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.clearFilters),
                ),
              ] else if (isFollowingEmpty) ...[
                Spacing.gapLG,
                ElevatedButton(
                  onPressed: () {
                    ref.read(selectedTabProvider.notifier).state = _communityTabIndex;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderXL,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.goToCommunity),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

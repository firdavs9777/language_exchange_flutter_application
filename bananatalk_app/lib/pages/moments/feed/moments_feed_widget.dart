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
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        // Insert native ads every 4th item (after each 3 moments)
        const adInterval = 4;
        final totalAds = moments.length ~/ (adInterval - 1);
        final totalItems = moments.length + totalAds;

        return ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Every adInterval-th position is an ad
            if (index > 0 && index % adInterval == 0) {
              return const NativeAdWidget();
            }

            // Calculate real moment index by subtracting ad count
            final adsBefore = index ~/ adInterval;
            final momentIndex = index - adsBefore;
            if (momentIndex >= moments.length) {
              return const SizedBox.shrink();
            }

            return MomentCard(moments: moments[momentIndex], onRefresh: onRefresh)
                .animate()
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

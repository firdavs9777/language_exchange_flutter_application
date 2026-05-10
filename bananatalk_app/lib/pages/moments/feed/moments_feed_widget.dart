import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show momentFilterProvider;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Renders the scrollable moments feed (with ad-every-4 insertion) and the
/// matching empty-state / error-state views.  All data is supplied by the
/// orchestrator (`MomentsMain`) so this widget has no direct provider
/// dependencies beyond `momentFilterProvider` (needed for the clear-filters
/// button in the empty-state).
class MomentsFeedWidget extends ConsumerWidget {
  final AsyncValue<List<Moments>> momentsAsync;
  final ScrollController scrollController;
  final bool isSearching;
  final VoidCallback onRefresh;

  const MomentsFeedWidget({
    super.key,
    required this.momentsAsync,
    required this.scrollController,
    required this.isSearching,
    required this.onRefresh,
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(
                isSearching
                    ? Icons.search_off
                    : currentFilter.hasActiveFilters
                    ? Icons.filter_alt_off
                    : Icons.chat_bubble_outline,
                size: 80,
                color: context.textHint,
              ),
              Spacing.gapLG,
              Text(
                isSearching
                    ? AppLocalizations.of(context)!.noResultsFound
                    : currentFilter.hasActiveFilters
                    ? AppLocalizations.of(context)!.noMomentsMatchFilters
                    : AppLocalizations.of(context)!.noMomentsYet,
                style: context.titleLarge,
              ),
              Spacing.gapSM,
              Text(
                isSearching
                    ? AppLocalizations.of(context)!.tryDifferentSearch
                    : currentFilter.hasActiveFilters
                    ? AppLocalizations.of(context)!.tryAdjustingFilters
                    : AppLocalizations.of(context)!.beFirstToShareMoment,
                style: context.bodySmall,
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
              ],
            ],
          ),
        ),
      ],
    );
  }
}

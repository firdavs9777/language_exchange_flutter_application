import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/moments/create_moment.dart';
import 'package:bananatalk_app/pages/moments/moment_card.dart';
import 'package:bananatalk_app/pages/moments/moment_filter_bar.dart';
import 'package:bananatalk_app/pages/moments/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/moment_filter_utility.dart';
import 'package:bananatalk_app/pages/stories/stories_feed_widget.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

const String _momentFilterKey = 'moment_filter';

/// Persisted moment filter provider - loads from SharedPreferences on init
class MomentFilterNotifier extends StateNotifier<MomentFilter> {
  MomentFilterNotifier() : super(const MomentFilter()) {
    _loadSavedFilter();
  }

  Future<void> _loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilter = prefs.getString(_momentFilterKey);
      if (savedFilter != null) {
        final decoded = json.decode(savedFilter) as Map<String, dynamic>;
        state = MomentFilter.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading saved moment filter: $e');
    }
  }

  Future<void> _saveFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_momentFilterKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving moment filter: $e');
    }
  }

  void setFilter(MomentFilter filter) {
    state = filter;
    _saveFilter();
  }

  void clearFilters() {
    state = const MomentFilter();
    _saveFilter();
  }
}

final momentFilterProvider =
    StateNotifierProvider<MomentFilterNotifier, MomentFilter>(
  (ref) => MomentFilterNotifier(),
);

final filteredMomentsProvider = Provider<AsyncValue<List<Moments>>>((ref) {
  final momentsAsync = ref.watch(momentsFeedProvider);
  final filter = ref.watch(momentFilterProvider);
  final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

  return momentsAsync.whenData((moments) {
    // Get blocked user IDs
    final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

    // Filter out moments from blocked users
    final filteredByBlock = moments.where((moment) {
      return !blockedUserIds.contains(moment.user.id);
    }).toList();

    // Apply other filters
    return MomentFilterUtility.filterMoments(filteredByBlock, filter);
  });
});

class MomentsMain extends ConsumerStatefulWidget {
  const MomentsMain({super.key});

  @override
  ConsumerState<MomentsMain> createState() => _MomentsMainState();
}

class _MomentsMainState extends ConsumerState<MomentsMain> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  List<Moments> _searchResults = [];
  final ValueNotifier<int> _storiesRefreshNotifier = ValueNotifier(0);

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

  void _performSearch(String query) {
    final momentsAsync = ref.read(momentsFeedProvider);
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    momentsAsync.whenData((moments) {
      if (!mounted) return;
      setState(() {
        _searchResults = MomentFilterUtility.searchMoments(moments, query);
      });
    });
  }

  Future<void> _refresh() async {
    HapticUtils.onRefresh();
    setState(() {
      _searchResults = [];
    });
    // Refresh both moments and stories
    _storiesRefreshNotifier.value++;
    await ref.refresh(momentsFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(momentFilterProvider);
    final filteredMomentsAsync = ref.watch(filteredMomentsProvider);
    final displayedList = _showSearch && _searchController.text.isNotEmpty
        ? AsyncValue.data(_searchResults)
        : filteredMomentsAsync;
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        automaticallyImplyLeading: false,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchMoments,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: context.textHint),
                ),
                style: context.bodyLarge,
                onChanged: _performSearch,
              )
            : Text(
                AppLocalizations.of(context)!.moments,
                style: context.displaySmall,
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: textPrimary,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: textPrimary),
            onPressed: () {
              Navigator.of(context)
                  .push(AppPageRoute(builder: (_) => const CreateMoment()))
                  .then((_) => _refresh());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories + Highlights combined section
          if (!_showSearch)
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(
                  bottom: BorderSide(color: context.dividerColor, width: 0.5),
                ),
              ),
              child: StoriesFeedWidget(height: 130, avatarSize: 64, refreshNotifier: _storiesRefreshNotifier),
            ),
          if (!_showSearch)
            MomentFilterBar(
              currentFilter: currentFilter,
              onFilterChanged: (filter) =>
                  ref.read(momentFilterProvider.notifier).setFilter(filter),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF00BFA5),
              child: _buildMomentsList(displayedList),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FutureBuilder<String?>(
        future: SharedPreferences.getInstance().then(
          (prefs) => prefs.getString('userId'),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      AppPageRoute(builder: (_) => const CreateMoment()),
                    )
                    .then((_) => _refresh());
              },
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            );
          }

          final userId = snapshot.data!;
          final limitsAsync = ref.watch(userLimitsProvider(userId));
          final userAsync = ref.watch(userProvider);

          return limitsAsync.when(
            data: (limits) {
              return userAsync.when(
                data: (user) {
                  final canCreate = FeatureGate.canCreateMoment(user, limits);
                  return FloatingActionButton(
                    onPressed: canCreate
                        ? () async {
                            // Check again before navigating
                            final currentLimits = ref.read(
                              currentUserLimitsProvider(userId),
                            );
                            final currentUser = await ref.read(
                              userProvider.future,
                            );
                            if (!FeatureGate.canCreateMoment(
                              currentUser,
                              currentLimits,
                            )) {
                              if (mounted) {
                                await LimitExceededDialog.show(
                                  context: context,
                                  limitType: 'moments',
                                  limitInfo: currentLimits?.moments,
                                  resetTime: currentLimits?.resetTime,
                                  userId: userId,
                                );
                              }
                              return;
                            }
                            Navigator.of(context)
                                .push(
                                  AppPageRoute(
                                    builder: (_) => const CreateMoment(),
                                  ),
                                )
                                .then((_) => _refresh());
                          }
                        : () async {
                            await LimitExceededDialog.show(
                              context: context,
                              limitType: 'moments',
                              limitInfo: limits.moments,
                              resetTime: limits.resetTime,
                              userId: userId,
                            );
                          },
                    backgroundColor: canCreate
                        ? context.primaryColor
                        : context.textMuted,
                    child: Icon(Icons.add, color: colorScheme.onPrimary),
                  );
                },
                loading: () => FloatingActionButton(
                  onPressed: null,
                  backgroundColor: context.textMuted,
                  child: Icon(Icons.add, color: context.textOnPrimary),
                ),
                error: (error, stack) => FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          AppPageRoute(
                            builder: (_) => const CreateMoment(),
                          ),
                        )
                        .then((_) => _refresh());
                  },
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.add, color: colorScheme.onPrimary),
                ),
              );
            },
            loading: () => FloatingActionButton(
              onPressed: null,
              backgroundColor: context.textMuted,
              child: Icon(Icons.add, color: context.textOnPrimary),
            ),
            error: (error, stack) => FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      AppPageRoute(builder: (_) => const CreateMoment()),
                    )
                    .then((_) => _refresh());
              },
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildMomentsList(AsyncValue<List<Moments>> momentsAsync) {
    return momentsAsync.when(
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState();
        }

        // Insert native ads every 4th item (after each 3 moments)
        final adInterval = 4;
        final totalAds = moments.length ~/ (adInterval - 1);
        final totalItems = moments.length + totalAds;

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Every 6th position is an ad
            if (index > 0 && index % adInterval == 0) {
              return const NativeAdWidget();
            }

            // Calculate real moment index by subtracting ad count
            final adsBefore = index ~/ adInterval;
            final momentIndex = index - adsBefore;
            if (momentIndex >= moments.length) {
              return const SizedBox.shrink();
            }

            return MomentCard(moments: moments[momentIndex], onRefresh: _refresh)
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
              onPressed: _refresh,
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

  Widget _buildEmptyState() {
    final currentFilter = ref.watch(momentFilterProvider);
    final isSearching = _showSearch && _searchController.text.isNotEmpty;

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

import 'dart:convert';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_bar.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_utility.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_feed_widget.dart';
import 'package:bananatalk_app/pages/moments/feed/prompt_of_day_card.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_widget.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart' show selectedTabProvider;
import 'package:bananatalk_app/pages/moments/reels/reels_grid_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/app_shell_drawer.dart';
import 'package:bananatalk_app/pages/stories/create/create_story_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

const String _momentFilterKey = 'moment_filter';

/// Index of the Moments tab in `TabsScreen`'s page list (see
/// `lib/pages/menu_tab/TabBarMenu.dart`'s "Tab order" comment) — used to
/// trigger a stale-while-revalidate refresh when the user switches back
/// into this tab.
const int _momentsTabIndex = 3;

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
  final mutedUserIds = ref.watch(mutedMomentsProvider); // NEW

  return momentsAsync.whenData((moments) {
    // Get blocked user IDs
    final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

    // Filter out moments from blocked and muted users
    final filteredByBlockAndMute = moments.where((moment) {
      return !blockedUserIds.contains(moment.user.id) &&
             !mutedUserIds.contains(moment.user.id);
    }).toList();

    // Apply other filters
    return MomentFilterUtility.filterMoments(filteredByBlockAndMute, filter);
  });
});

/// Feed tabs shown above the moment filter bar.
///
/// Workstream G: [reels] is conditionally shown (hidden when
/// `appConfig.reelsEnabled == false`, see `_MomentsFeedTabBar`) and,
/// unlike the other three, does not share the card-feed body — the
/// Reels case branches to `ReelsGridScreen` entirely (see
/// `_MomentsMainState.build`), since it's a thumbnail grid landing, not a
/// scrollable list of `MomentCard`s.
enum MomentsFeedTab { forYou, following, trending, reels }

const String _momentsFeedTabKey = 'moments_feed_tab';

MomentsFeedTab _momentsFeedTabFromPrefs(String? value) {
  return MomentsFeedTab.values.firstWhere(
    (tab) => tab.name == value,
    orElse: () => MomentsFeedTab.forYou,
  );
}

/// Persisted "last selected feed tab" — mirrors [MomentFilterNotifier]'s
/// SharedPreferences persistence pattern.
class MomentsFeedTabNotifier extends StateNotifier<MomentsFeedTab> {
  MomentsFeedTabNotifier() : super(MomentsFeedTab.forYou) {
    _loadSavedTab();
  }

  Future<void> _loadSavedTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_momentsFeedTabKey);
      if (saved != null) {
        state = _momentsFeedTabFromPrefs(saved);
      }
    } catch (e) {
      debugPrint('Error loading saved moments feed tab: $e');
    }
  }

  Future<void> setTab(MomentsFeedTab tab) async {
    state = tab;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_momentsFeedTabKey, tab.name);
    } catch (e) {
      debugPrint('Error saving moments feed tab: $e');
    }
  }
}

final momentsFeedTabProvider =
    StateNotifierProvider<MomentsFeedTabNotifier, MomentsFeedTab>(
  (ref) => MomentsFeedTabNotifier(),
);

/// Base (unfiltered) moments provider for a given feed tab.
///
/// Reels intentionally has no case here — it's backed by the dedicated
/// paginated `reelsFeedProvider` (see `providers/reels_provider.dart`), not
/// this shared card-feed shape, and `MomentsMain.build` branches to
/// `ReelsGridScreen` before this function would ever be reached for that
/// tab. The `.reels` arm below only exists to satisfy switch exhaustiveness
/// and is unreachable in practice.
///
/// Public (not `_`-prefixed) so `invalidateMomentFeeds` in
/// `moments_providers.dart` can reuse this exact tab→provider mapping
/// instead of duplicating the switch (see moments audit I2/P1). Typed as
/// `FutureProvider<List<Moments>>` (not the broader `ProviderListenable`)
/// so callers can both `ref.watch(...)` it (as before) and
/// `ref.invalidate(...)` it — `invalidate` requires a `ProviderOrFamily`,
/// which `ProviderListenable` alone doesn't satisfy.
FutureProvider<List<Moments>> baseProviderFor(
    MomentsFeedTab tab) {
  switch (tab) {
    case MomentsFeedTab.forYou:
      return forYouMomentsProvider;
    case MomentsFeedTab.following:
      return followingMomentsProvider;
    case MomentsFeedTab.trending:
      return trendingMomentsProvider;
    case MomentsFeedTab.reels:
      return forYouMomentsProvider;
  }
}

/// Client-side filtered/blocked/muted moments for a given feed tab. Mirrors
/// [filteredMomentsProvider] but is parameterized by tab so each tab keeps
/// its own cached data and can be invalidated independently.
final filteredMomentsForTabProvider =
    Provider.family<AsyncValue<List<Moments>>, MomentsFeedTab>((ref, tab) {
  final momentsAsync = ref.watch(baseProviderFor(tab));
  final filter = ref.watch(momentFilterProvider);
  final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);
  final mutedUserIds = ref.watch(mutedMomentsProvider);

  return momentsAsync.whenData((moments) {
    final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

    final filteredByBlockAndMute = moments.where((moment) {
      return !blockedUserIds.contains(moment.user.id) &&
          !mutedUserIds.contains(moment.user.id);
    }).toList();

    return MomentFilterUtility.filterMoments(filteredByBlockAndMute, filter);
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
  void initState() {
    super.initState();
    // Stale-while-revalidate: pick up new moments on first mount if the
    // feed hasn't been fetched in the last 60s, without a spinner flash
    // (see `refreshMomentsIfStale` / the `skipLoadingOn*` flags on
    // `MomentsFeedWidget`'s `.when(...)`). Deferred to a post-frame
    // callback since invalidating providers during initState throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshMomentsIfStale(ref);
    });
  }

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
    // Search always operates over the default (unfiltered) feed regardless
    // of the active tab, matching prior search behavior.
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
    // Heal userProvider if it errored (e.g. after a bad userId was stored)
    final userState = ref.read(userProvider);
    if (userState.hasError) {
      ref.invalidate(userProvider);
      try { await ref.read(userProvider.future); } catch (_) {}
    }
    setState(() {
      _searchResults = [];
    });
    // Refresh both moments and stories
    _storiesRefreshNotifier.value++;

    // Reels has its own paginated provider/refresh, not the shared
    // FutureProvider<List<Moments>> shape the other three tabs use.
    final activeTab = ref.read(momentsFeedTabProvider);
    if (activeTab == MomentsFeedTab.reels) {
      await ref.read(reelsFeedProvider.notifier).refresh();
      return;
    }

    // Only invalidate the active tab's provider, so switching tabs doesn't
    // force a redundant re-fetch of tabs the user hasn't looked at.
    final Future<List<Moments>> activeTabFuture = switch (activeTab) {
      MomentsFeedTab.forYou => ref.refresh(forYouMomentsProvider.future),
      MomentsFeedTab.following => ref.refresh(followingMomentsProvider.future),
      MomentsFeedTab.trending => ref.refresh(trendingMomentsProvider.future),
      // Unreachable — handled above.
      MomentsFeedTab.reels => Future.value(const <Moments>[]),
    };
    await activeTabFuture;
  }

  @override
  Widget build(BuildContext context) {
    // Stale-while-revalidate: silently refresh the feed whenever the user
    // navigates back into the Moments tab (e.g. from Chats/Profile), so a
    // moment posted elsewhere shows up without a manual pull-to-refresh.
    ref.listen<int>(selectedTabProvider, (previous, next) {
      if (next == _momentsTabIndex) {
        refreshMomentsIfStale(ref);
      }
    });
    final currentFilter = ref.watch(momentFilterProvider);
    final activeTab = ref.watch(momentsFeedTabProvider);
    final reelsEnabled = ref.watch(appConfigProvider).maybeWhen(
          data: (config) => config?.reelsEnabled ?? false,
          orElse: () => false,
        );
    // If the kill switch flips off mid-session while the user happens to be
    // on the Reels tab, fall back to For You for rendering purposes rather
    // than showing a grid the tab bar no longer exposes a segment for.
    final effectiveTab =
        activeTab == MomentsFeedTab.reels && !reelsEnabled
            ? MomentsFeedTab.forYou
            : activeTab;
    final isReelsTab = effectiveTab == MomentsFeedTab.reels;

    // Reels is backed by its own paginated provider (see
    // `baseProviderFor`'s doc comment) — don't call the shared card-feed
    // family provider for it.
    final filteredMomentsAsync = isReelsTab
        ? const AsyncValue<List<Moments>>.data(<Moments>[])
        : ref.watch(filteredMomentsForTabProvider(effectiveTab));
    final displayedList = _showSearch && _searchController.text.isNotEmpty
        ? AsyncValue.data(_searchResults)
        : filteredMomentsAsync;
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;

    final isVip = ref.watch(userProvider).valueOrNull?.isVip ?? false;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      drawer: AppShellDrawer(
        currentTabIndex: 3,
        extraItems: [
          AppShellDrawerItem(
            icon: Icons.add_photo_alternate_outlined,
            label: AppLocalizations.of(context)!.createMoment,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(AppPageRoute(builder: (_) => const CreateMoment()))
                  .then((_) => _refresh());
            },
          ),
          AppShellDrawerItem(
            icon: Icons.auto_stories_outlined,
            label: AppLocalizations.of(context)!.createStory,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                AppPageRoute(
                  builder: (_) => CreateStoryScreen(
                    onStoryCreated: () => _storiesRefreshNotifier.value++,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        // Hamburger uses the default Scaffold drawer button when drawer is set.
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
            : Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.moments,
                    style: context.displaySmall,
                  ),
                  const SizedBox(width: 8),
                  isVip ? _buildVipBadge() : _buildGoVipChip(context),
                ],
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
          // Stories + Highlights combined section — not shown on the Reels
          // grid, which is a distinct full-bleed thumbnail landing.
          if (!_showSearch && !isReelsTab)
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
            _MomentsFeedTabBar(
              activeTab: effectiveTab,
              onTabChanged: (tab) {
                if (tab == activeTab) return;
                ref.read(momentsFeedTabProvider.notifier).setTab(tab);
              },
            ),
          // The mood/tag/language filter bar only applies to the shared
          // card-feed query — Reels has its own ranking, not a client-side
          // filter.
          if (!_showSearch && !isReelsTab)
            MomentFilterBar(
              currentFilter: currentFilter,
              onFilterChanged: (filter) =>
                  ref.read(momentFilterProvider.notifier).setFilter(filter),
            ),
          if (!_showSearch && effectiveTab == MomentsFeedTab.forYou)
            const PromptOfDayCard(),
          Expanded(
            child: isReelsTab
                ? ReelsGridScreen(
                    onPolicyDeclined: () => ref
                        .read(momentsFeedTabProvider.notifier)
                        .setTab(MomentsFeedTab.forYou),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: const Color(0xFF00BFA5),
                    child: MomentsFeedWidget(
                      momentsAsync: displayedList,
                      scrollController: _scrollController,
                      isSearching:
                          _showSearch && _searchController.text.isNotEmpty,
                      onRefresh: _refresh,
                      activeTab: effectiveTab,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isReelsTab
          ? null
          : Padding(
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

  /// "Go VIP" chip shown to non-VIP users next to the Moments title.
  /// Tappable → opens the VIP plans screen.
  Widget _buildGoVipChip(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          AppPageRoute(builder: (_) => const VipPlansScreen()),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  size: 11, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                AppLocalizations.of(context)!.filterVipPromoCta,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded,
                  size: 11, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  /// Small gold VIP pill rendered next to the Moments title in the AppBar
  /// for VIP users — mirrors the badge in the chat header.
  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented tab control for switching between the For You / Following /
/// Trending / Reels moments feeds. Mostly presentational — selection state
/// and data loading live in [momentsFeedTabProvider] and the per-tab feed
/// providers — but it's a [ConsumerWidget] so it can hide the Reels segment
/// entirely while the server-side `reelsEnabled` kill switch is off.
class _MomentsFeedTabBar extends ConsumerWidget {
  final MomentsFeedTab activeTab;
  final ValueChanged<MomentsFeedTab> onTabChanged;

  const _MomentsFeedTabBar({
    required this.activeTab,
    required this.onTabChanged,
  });

  static const Color _tealIndicator = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reelsEnabled = ref.watch(appConfigProvider).maybeWhen(
          data: (config) => config?.reelsEnabled ?? false,
          orElse: () => false,
        );
    final tabs = <MomentsFeedTab, String>{
      MomentsFeedTab.forYou: 'For You',
      MomentsFeedTab.following: l10n.following,
      MomentsFeedTab.trending: l10n.trending,
      // TODO(l10n): no `momentsTabReels` key exists yet in the arb files —
      // plain-string fallback, following the established pattern (see
      // `CommunityTabBar`'s "Rooms" tab) until a follow-up localizes it.
      if (reelsEnabled) MomentsFeedTab.reels: 'Reels',
    };

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: tabs.entries.map((entry) {
          final tab = entry.key;
          final label = entry.value;
          final isActive = tab == activeTab;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _tealIndicator : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _tealIndicator : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

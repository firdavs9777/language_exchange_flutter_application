import 'dart:async';
import 'dart:convert';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';
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
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart'
    show selectedTabProvider, kMomentsTabIndex;
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
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/app_shell_drawer.dart';
import 'package:bananatalk_app/pages/stories/create/create_story_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/widgets/guides/page_guide.dart';

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
/// the concrete paged provider (not the broader `ProviderListenable`)
/// so callers can `ref.watch(...)` it, `ref.invalidate(...)` it, and reach
/// its notifier for `loadMore` / `softRefresh`.
AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>> baseProviderFor(
  MomentsFeedTab tab,
) {
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

        return MomentFilterUtility.filterMoments(
          filteredByBlockAndMute,
          filter,
        );
      });
    });

class MomentsMain extends ConsumerStatefulWidget {
  const MomentsMain({super.key});

  @override
  ConsumerState<MomentsMain> createState() => _MomentsMainState();
}

class _MomentsMainState extends ConsumerState<MomentsMain> {
  /// The feed list's latest scroll metrics. The list is the inner scrollable
  /// of a NestedScrollView, which must own its controller, so paging reads
  /// the metrics from its notifications instead of a controller of our own.
  ScrollMetrics? _feedMetrics;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  List<Moments> _searchResults = [];
  final ValueNotifier<int> _storiesRefreshNotifier = ValueNotifier(0);
  Timer? _searchDebounce;
  int _searchGeneration = 0;

  /// How close to the end of the list (in pixels) the next page is asked
  /// for.
  static const double _loadMoreThreshold = 800;

  /// Below this many loaded moments, a list too short to scroll (e.g. most
  /// of a page hidden by filters) fetches the next page by itself.
  static const int _autoFillLimit = 200;

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

  /// Asks the active tab for its next page when the reader nears the end.
  /// Not while searching (results are one server page) or on Reels (its
  /// own provider pages itself).
  void _maybeLoadMore() {
    if (!mounted) return;
    if (_showSearch && _searchController.text.isNotEmpty) return;
    final tab = ref.read(momentsFeedTabProvider);
    if (tab == MomentsFeedTab.reels) return;
    final metrics = _feedMetrics;
    // Not laid out yet: its metrics notification will call back.
    if (metrics == null) return;
    if (metrics.extentAfter > _loadMoreThreshold) return;
    final provider = baseProviderFor(tab);
    final notifier = ref.read(provider.notifier);
    if (!notifier.hasMore) return;
    // A list too short to scroll asks by itself, but only up to a bound so
    // a filter that hides everything cannot page through the whole feed.
    final scrollable = metrics.maxScrollExtent > 0;
    final loaded = ref.read(provider).valueOrNull?.length ?? 0;
    if (!scrollable && loaded >= _autoFillLimit) return;
    notifier.loadMore();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  /// Searches the server (caption, title and tags across every moment, not
  /// just the loaded page), debounced, plus author-name matches among the
  /// moments already loaded — the server search does not cover names.
  void _performSearch(String query) {
    _searchDebounce?.cancel();
    final generation = ++_searchGeneration;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final tab = ref.read(momentsFeedTabProvider);
    final loaded = tab == MomentsFeedTab.reels
        ? const <Moments>[]
        : ref.read(baseProviderFor(tab)).valueOrNull ?? const <Moments>[];
    final local = MomentFilterUtility.searchMoments(loaded, trimmed);
    setState(() => _searchResults = local);

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final response = await ref
            .read(momentsServiceProvider)
            .getMoments(page: 1, limit: kMomentsFeedPageSize, q: trimmed);
        final raw = response['moments'];
        final remote = raw is List ? raw.cast<Moments>() : <Moments>[];
        if (!mounted || generation != _searchGeneration) return;
        setState(() => _searchResults = appendMomentsPage(remote, local));
      } catch (_) {
        // Offline / server error: the local matches stay.
      }
    });
  }

  Future<void> _refresh() async {
    HapticUtils.onRefresh();
    // Heal userProvider if it errored (e.g. after a bad userId was stored)
    final userState = ref.read(userProvider);
    if (userState.hasError) {
      ref.invalidate(userProvider);
      try {
        await ref.read(userProvider.future);
      } catch (_) {}
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
    // force a redundant re-fetch of tabs the user hasn't looked at. A full
    // reload: back to page 1.
    final Future<List<Moments>> activeTabFuture =
        ref.refresh(baseProviderFor(activeTab).future);
    await activeTabFuture;
  }

  @override
  Widget build(BuildContext context) {
    // Stale-while-revalidate: silently refresh the feed whenever the user
    // navigates back into the Moments tab (e.g. from Chats/Profile), so a
    // moment posted elsewhere shows up without a manual pull-to-refresh.
    ref.listen<int>(selectedTabProvider, (previous, next) {
      if (next == kMomentsTabIndex) {
        refreshMomentsIfStale(ref);
      }
    });
    final currentFilter = ref.watch(momentFilterProvider);
    final activeTab = ref.watch(momentsFeedTabProvider);
    final reelsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(
          data: (config) => config?.reelsEnabled ?? false,
          orElse: () => false,
        );
    // If the kill switch flips off mid-session while the user happens to be
    // on the Reels tab, fall back to For You for rendering purposes rather
    // than showing a grid the tab bar no longer exposes a segment for.
    final effectiveTab = activeTab == MomentsFeedTab.reels && !reelsEnabled
        ? MomentsFeedTab.forYou
        : activeTab;
    final isReelsTab = effectiveTab == MomentsFeedTab.reels;

    // Reels is backed by its own paginated provider (see
    // `baseProviderFor`'s doc comment) — don't call the shared card-feed
    // family provider for it.
    final filteredMomentsAsync = isReelsTab
        ? const AsyncValue<List<Moments>>.data(<Moments>[])
        : ref.watch(filteredMomentsForTabProvider(effectiveTab));
    final isSearching = _showSearch && _searchController.text.isNotEmpty;
    final displayedList = isSearching
        ? AsyncValue.data(_searchResults)
        : filteredMomentsAsync;
    // Watched so the trailing spinner follows the paged state.
    final hasMorePages = !isReelsTab &&
        !isSearching &&
        ref.watch(baseProviderFor(effectiveTab)).hasValue &&
        ref.read(baseProviderFor(effectiveTab).notifier).hasMore;
    // A page that did not fill the screen (filters, blocks) asks for the
    // next one by itself; a scroll would never come.
    if (hasMorePages) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    }
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
        ],
      ),
      // One scroll: the guide, stories and today's prompt scroll away with
      // the feed; only the tab row (with the filter button) stays pinned.
      // Before, six fixed bands stacked above the list and left a sliver of
      // screen for the moments themselves.
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF00BFA5),
        // The feed list is the NestedScrollView's inner scrollable (depth 1);
        // a pull on the header itself is the outer one (depth 0).
        notificationPredicate: (n) => n.depth <= 1,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Hidden on the Reels grid: that tab is a full-bleed thumbnail
            // wall, and a tinted card at the top of it reads as a broken cell.
            if (!isReelsTab)
              SliverToBoxAdapter(
                child: PageGuide(
                  surface: GuideSurface.moments,
                  icon: Icons.add_a_photo_rounded,
                  accent: AppColors.accent,
                  title: AppLocalizations.of(context)!.guideMomentsTitle,
                  body: AppLocalizations.of(context)!.guideMomentsBody,
                  ctaLabel: AppLocalizations.of(context)!.guideMomentsCta,
                  onCta: () => Navigator.of(context)
                      .push(AppPageRoute(builder: (_) => const CreateMoment())),
                ),
              ),
            if (!_showSearch && !isReelsTab)
              SliverToBoxAdapter(
                child: StoriesFeedWidget(
                  height: 104,
                  avatarSize: 56,
                  refreshNotifier: _storiesRefreshNotifier,
                ),
              ),
            if (!_showSearch && effectiveTab == MomentsFeedTab.forYou)
              const SliverToBoxAdapter(child: PromptOfDayCard()),
            if (!_showSearch)
              SliverPersistentHeader(
                pinned: true,
                delegate: _FeedHeaderDelegate(
                  showActiveFilters:
                      !isReelsTab && currentFilter.hasActiveFilters,
                  child: Column(
                    children: [
                      _MomentsFeedTabBar(
                        activeTab: effectiveTab,
                        onTabChanged: (tab) {
                          if (tab == activeTab) return;
                          ref.read(momentsFeedTabProvider.notifier).setTab(tab);
                        },
                        // The filters only apply to the card feeds; Reels has
                        // its own ranking.
                        trailing: isReelsTab
                            ? null
                            : MomentFilterButton(
                                currentFilter: currentFilter,
                                onFilterChanged: (filter) => ref
                                    .read(momentFilterProvider.notifier)
                                    .setFilter(filter),
                              ),
                      ),
                      if (!isReelsTab)
                        MomentActiveFilters(
                          currentFilter: currentFilter,
                          onFilterChanged: (filter) => ref
                              .read(momentFilterProvider.notifier)
                              .setFilter(filter),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          body: isReelsTab
              ? ReelsGridScreen(
                  onPolicyDeclined: () => ref
                      .read(momentsFeedTabProvider.notifier)
                      .setTab(MomentsFeedTab.forYou),
                )
              : NotificationListener<Notification>(
                  // Scroll updates, plus the metrics notification a list sends
                  // after layout, so a first page too short to scroll still
                  // asks for the next one.
                  onNotification: (n) {
                    final ScrollMetrics? m = n is ScrollNotification && n.depth == 0
                        ? n.metrics
                        : n is ScrollMetricsNotification && n.depth == 0
                            ? n.metrics
                            : null;
                    if (m != null && m.axis == Axis.vertical) {
                      _feedMetrics = m;
                      _maybeLoadMore();
                    }
                    return false;
                  },
                  child: MomentsFeedWidget(
                    momentsAsync: displayedList,
                    isSearching: isSearching,
                    onRefresh: _refresh,
                    activeTab: effectiveTab,
                    hasMore: hasMorePages,
                  ),
                ),
        ),
      ),
      floatingActionButton: isReelsTab
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: FloatingTabBar.fabLift(context)),
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
                              AppPageRoute(
                                builder: (_) => const CreateMoment(),
                              ),
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
                          final canCreate = FeatureGate.canCreateMoment(
                            user,
                            limits,
                          );
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
                                          context: this.context,
                                          limitType: 'moments',
                                          limitInfo: currentLimits?.moments,
                                          resetTime: currentLimits?.resetTime,
                                          userId: userId,
                                        );
                                      }
                                      return;
                                    }
                                    if (!mounted) return;
                                    Navigator.of(this.context)
                                        .push(
                                          AppPageRoute(
                                            builder: (_) =>
                                                const CreateMoment(),
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
                            child: Icon(
                              Icons.add,
                              color: colorScheme.onPrimary,
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
        onTap: () => Navigator.of(
          context,
        ).push(AppPageRoute(builder: (_) => const VipPlansScreen())),
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
              const Icon(
                Icons.workspace_premium,
                size: 11,
                color: Colors.white,
              ),
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
              const Icon(
                Icons.arrow_forward_rounded,
                size: 11,
                color: Colors.white,
              ),
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

/// Pinned header of the feed: the tab row, plus the active-filter chips when
/// any filter is on. Its height follows that, so it is never taller than
/// what it shows.
class _FeedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool showActiveFilters;

  _FeedHeaderDelegate({required this.child, required this.showActiveFilters});

  double get _height =>
      _MomentsFeedTabBar.height +
      (showActiveFilters ? MomentActiveFilters.height : 0);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: context.surfaceColor,
      elevation: overlapsContent || shrinkOffset > 0 ? 1 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FeedHeaderDelegate oldDelegate) => true;
}

/// For You / Reels / Following / Trending as one compact, left-aligned row
/// that scrolls sideways when a locale's labels do not fit, with [trailing]
/// (the filter button) pinned at the end. Selection state and data loading
/// live in [momentsFeedTabProvider] and the per-tab feed providers; it is a
/// [ConsumerWidget] only to hide Reels while the server's `reelsEnabled`
/// kill switch is off.
class _MomentsFeedTabBar extends ConsumerWidget {
  final MomentsFeedTab activeTab;
  final ValueChanged<MomentsFeedTab> onTabChanged;
  final Widget? trailing;

  const _MomentsFeedTabBar({
    required this.activeTab,
    required this.onTabChanged,
    this.trailing,
  });

  static const double height = 48;
  static const Color _tealIndicator = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reelsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(
          data: (config) => config?.reelsEnabled ?? false,
          orElse: () => false,
        );
    // Insertion order is the on-screen order. Reels sits directly after
    // For You so it's the first thing reachable from the default tab.
    final tabs = <MomentsFeedTab, String>{
      MomentsFeedTab.forYou: l10n.momentsTabForYou,
      if (reelsEnabled) MomentsFeedTab.reels: l10n.momentsTabReels,
      MomentsFeedTab.following: l10n.following,
      MomentsFeedTab.trending: l10n.trending,
    };

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: tabs.entries.map((entry) {
                final tab = entry.key;
                final isActive = tab == activeTab;
                return Semantics(
                  selected: isActive,
                  button: true,
                  child: InkWell(
                    key: Key('moments-tab-${tab.name}'),
                    onTap: () => onTabChanged(tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? _tealIndicator : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: context.titleSmall.copyWith(
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? context.textPrimary : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

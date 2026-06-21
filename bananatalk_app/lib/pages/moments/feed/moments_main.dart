import 'dart:convert';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_bar.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_utility.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_feed_widget.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_widget.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
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
              child: MomentsFeedWidget(
                momentsAsync: displayedList,
                scrollController: _scrollController,
                isSearching: _showSearch && _searchController.text.isNotEmpty,
                onRefresh: _refresh,
              ),
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

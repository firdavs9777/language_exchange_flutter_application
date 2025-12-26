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
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

final momentFilterProvider = StateProvider<MomentFilter>(
  (ref) => const MomentFilter(),
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
    setState(() {
      _searchResults = [];
    });
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
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        automaticallyImplyLeading: false,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchMoments,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: secondaryText),
                ),
                style: TextStyle(fontSize: 16, color: textPrimary),
                onChanged: _performSearch,
              )
            : Text(
                'Moments',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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
                  .push(MaterialPageRoute(builder: (_) => const CreateMoment()))
                  .then((_) => _refresh());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories at the top
          if (!_showSearch)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: const StoriesFeedWidget(height: 100, avatarSize: 64),
            ),
          if (!_showSearch)
            MomentFilterBar(
              currentFilter: currentFilter,
              onFilterChanged: (filter) =>
                  ref.read(momentFilterProvider.notifier).state = filter,
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
      floatingActionButton: FutureBuilder<String?>(
        future: SharedPreferences.getInstance().then(
          (prefs) => prefs.getString('userId'),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const CreateMoment()),
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
                                  MaterialPageRoute(
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
                        ? colorScheme.primary
                        : Colors.grey,
                    child: Icon(Icons.add, color: colorScheme.onPrimary),
                  );
                },
                loading: () => FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.add, color: colorScheme.onPrimary),
                ),
                error: (error, stack) => FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
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
              backgroundColor: Colors.grey,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
            error: (error, stack) => FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const CreateMoment()),
                    )
                    .then((_) => _refresh());
              },
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMomentsList(AsyncValue<List<Moments>> momentsAsync) {
    return momentsAsync.when(
      data: (moments) {
        print(moments);
        if (moments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: moments.length,
          itemBuilder: (context, index) {
            return MomentCard(moments: moments[index], onRefresh: _refresh);
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
              color: context.textSecondary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load moments',
              style: TextStyle(fontSize: 16, color: context.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _refresh,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
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
                color: context.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No results found'
                    : currentFilter.hasActiveFilters
                    ? 'No moments match your filters'
                    : 'No moments yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Try a different search term'
                    : currentFilter.hasActiveFilters
                    ? 'Try adjusting your filters'
                    : 'Be the first to share a moment!',
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              if (currentFilter.hasActiveFilters) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(momentFilterProvider.notifier).state =
                        const MomentFilter();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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

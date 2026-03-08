import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/services/interaction_service.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// View mode for partner discovery
enum PartnerViewMode { list, swipe }

/// Partner Discovery Tab with list view (default) and swipe cards (Quick Match)
class PartnerDiscoveryTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;

  const PartnerDiscoveryTab({
    super.key,
    required this.filters,
    required this.searchQuery,
  });

  @override
  ConsumerState<PartnerDiscoveryTab> createState() =>
      _PartnerDiscoveryTabState();
}

class _PartnerDiscoveryTabState extends ConsumerState<PartnerDiscoveryTab> {
  String _userId = '';
  final Set<String> _sessionSkippedUsers = {}; // Local session cache for instant UI
  final Set<String> _sessionWavedUsers = {}; // Local session cache for instant UI
  Set<String> _serverExcludedUsers = {}; // Users excluded by server (persisted skips/waves)
  bool _isProcessingSwipe = false; // Prevent double swipes
  bool _initialLoadDone = false;
  PartnerFilterParams? _lastFilters;
  String _lastSearchQuery = '';

  // View mode state
  PartnerViewMode _viewMode = PartnerViewMode.list; // Default to list view
  static const _viewModeKey = 'partner_discovery_view_mode';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadServerExcludedUsers();
    _loadViewMode();
    _scrollController.addListener(_onScroll);

    // Load initial data after user info is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load saved view mode preference
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_viewModeKey);
    if (savedMode != null && mounted) {
      setState(() {
        _viewMode = savedMode == 'swipe' ? PartnerViewMode.swipe : PartnerViewMode.list;
      });
    }
  }

  /// Save view mode preference
  Future<void> _saveViewMode(PartnerViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode == PartnerViewMode.swipe ? 'swipe' : 'list');
  }

  /// Toggle between list and swipe view
  void _toggleViewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _viewMode = _viewMode == PartnerViewMode.list
          ? PartnerViewMode.swipe
          : PartnerViewMode.list;
    });
    _saveViewMode(_viewMode);
  }

  /// Handle scroll for pagination in list view
  void _onScroll() {
    if (_viewMode != PartnerViewMode.list) return;

    final partnerState = ref.read(partnerFilterProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        partnerState.hasMore &&
        !partnerState.isLoadingMore) {
      ref.read(partnerFilterProvider.notifier).loadMore();
    }
  }

  /// Load excluded users from server (skipped + waved)
  Future<void> _loadServerExcludedUsers() async {
    try {
      final excluded = await InteractionService.getExcludedUsers();
      if (mounted) {
        setState(() {
          _serverExcludedUsers = excluded;
        });
      }
      debugPrint('📋 Loaded ${excluded.length} excluded users from server');
    } catch (e) {
      debugPrint('❌ Error loading excluded users: $e');
    }
  }

  @override
  void didUpdateWidget(PartnerDiscoveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when filters or search query change
    if (oldWidget.filters != widget.filters ||
        oldWidget.searchQuery != widget.searchQuery) {
      _refreshData();
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
    });
  }

  void _loadInitialData() {
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      // Load will happen when we watch userProvider in build
    }
  }

  void _refreshData() {
    if (_lastFilters != null) {
      ref.read(partnerFilterProvider.notifier).loadWithFilters(_lastFilters!);
    }
  }

  /// Build filter params from current user and UI filters
  /// Uses filter screen selection if available, otherwise user's profile languages
  ///
  /// IMPORTANT: API semantics are inverted for language exchange matching:
  /// - API nativeLanguage param → finds users LEARNING this language
  /// - API learningLanguage param → finds users who SPEAK this language natively
  ///
  /// So when the user selects "Native Language: French" in filter (wants to SEE French speakers),
  /// we pass it as learningLanguage to the API.
  PartnerFilterParams _buildFilterParams(String? myNative, String? myLearning) {
    debugPrint('🎯 _buildFilterParams called');
    debugPrint('   My profile: native=$myNative, learning=$myLearning');
    debugPrint('   UI filters received: ${widget.filters}');
    // Check if filter screen has language selections
    // Filter native = "show users who speak X natively"
    // Filter learning = "show users who are learning X"
    final filterNative = widget.filters['nativeLanguage']?.toString();
    final filterLearning = widget.filters['learningLanguage']?.toString();

    final hasFilterNative = filterNative != null && filterNative.isNotEmpty;
    final hasFilterLearning = filterLearning != null && filterLearning.isNotEmpty;

    // Determine effective languages
    String? apiNativeParam; // API: finds users LEARNING this language
    String? apiLearningParam; // API: finds users who SPEAK this natively

    if (hasFilterNative || hasFilterLearning) {
      // User is using explicit filters - only apply what they selected
      // Don't mix with exchange matching to avoid OR confusion
      if (hasFilterNative) {
        // User wants to see speakers of filterNative → pass as learningLanguage to API
        apiLearningParam = filterNative;
      }
      if (hasFilterLearning) {
        // User wants to see learners of filterLearning → pass as nativeLanguage to API
        apiNativeParam = filterLearning;
      }
    } else {
      // No explicit filters - use language exchange matching (default behavior)
      // Find users who speak what I'm learning OR are learning what I speak
      apiLearningParam = myLearning;
      apiNativeParam = myNative;
    }

    debugPrint('🔧 Filter transform:');
    debugPrint('   UI filterNative=$filterNative → API learningLanguage=$apiLearningParam');
    debugPrint('   UI filterLearning=$filterLearning → API nativeLanguage=$apiNativeParam');
    debugPrint('   Mode: ${(hasFilterNative || hasFilterLearning) ? 'EXPLICIT FILTER' : 'EXCHANGE MATCHING'}');

    final params = PartnerFilterParams(
      nativeLanguage: apiNativeParam,
      learningLanguage: apiLearningParam,
      gender: widget.filters['gender']?.toString(),
      minAge: widget.filters['minAge'] as int?,
      maxAge: widget.filters['maxAge'] as int?,
      onlineOnly: widget.filters['onlineOnly'] == true,
      country: widget.filters['country']?.toString(),
      languageLevel: widget.filters['languageLevel']?.toString(),
      search: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
    );

    debugPrint('📤 Final PartnerFilterParams:');
    debugPrint('   nativeLanguage: ${params.nativeLanguage}');
    debugPrint('   learningLanguage: ${params.learningLanguage}');
    debugPrint('   gender: ${params.gender}');
    debugPrint('   minAge: ${params.minAge}');
    debugPrint('   maxAge: ${params.maxAge}');
    debugPrint('   country: ${params.country}');
    debugPrint('   onlineOnly: ${params.onlineOnly}');

    return params;
  }

  /// Filter out session-skipped/waved users (local cache for instant UI feedback)
  /// Server-side already excludes persisted skips/waves, this is just for current session
  List<Community> _filterSessionUsers(List<Community> users, Set<String> blockedUserIds) {
    return users.where((user) {
      if (user.id == _userId) return false;
      if (blockedUserIds.contains(user.id)) return false;
      // Session-level exclusions (for instant UI before server syncs)
      if (_sessionSkippedUsers.contains(user.id)) return false;
      if (_sessionWavedUsers.contains(user.id)) return false;
      // Server-excluded users (in case they weren't filtered server-side)
      if (_serverExcludedUsers.contains(user.id)) return false;
      return true;
    }).toList();
  }

  // Send wave sticker message in background (fire and forget)
  // Uses special wave sticker format that renders as a big friendly greeting
  Future<void> _sendWaveSticker(String receiverId) async {
    try {
      final messageService = ref.read(messageServiceProvider);
      // Send wave sticker - this will be detected and rendered as a big wave sticker
      await messageService.sendMessage(
        receiver: receiverId,
        message: '👋',  // Wave emoji - renders as big sticker
      );
    } catch (e) {
      debugPrint('Error sending wave sticker: $e');
    }
  }

  void _onWaveFromButton(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved locally for instant UI
    _sessionWavedUsers.add(community.id);

    // Persist to server in background
    InteractionService.waveUser(community.id).then((result) {
      debugPrint('👋 Wave result: $result');
    });

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userId: community.id,
          userName: community.name,
          profilePicture: community.profileImageUrl,
          isVip: community.isVip,
        ),
      ),
    );

    // Send wave sticker in background
    _sendWaveSticker(community.id);
  }

  void _onWaveFromSwipe(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved locally for instant UI
    _sessionWavedUsers.add(community.id);

    // Persist to server in background
    InteractionService.waveUser(community.id).then((result) {
      debugPrint('👋 Wave (swipe) result: $result');
    });

    // Update state to show next card
    setState(() {
      _isProcessingSwipe = false;
    });

    // Navigate after state update
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              userId: community.id,
              userName: community.name,
              profilePicture: community.profileImageUrl,
              isVip: community.isVip,
            ),
          ),
        );
      }
    });

    // Send wave sticker in background
    _sendWaveSticker(community.id);
  }

  void _onMessage(Community community) {
    // Navigate directly to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userId: community.id,
          userName: community.name,
          profilePicture: community.profileImageUrl,
          isVip: community.isVip,
        ),
      ),
    );
  }

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleCommunity(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerState = ref.watch(partnerFilterProvider);
    final currentUserAsync = ref.watch(userProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        // Build filter params from user's languages
        final filterParams = _buildFilterParams(
          currentUser.native_language,
          currentUser.language_to_learn,
        );

        // Load data if filters changed, search query changed, or initial load
        final searchChanged = _lastSearchQuery != widget.searchQuery;
        if (_lastFilters != filterParams || searchChanged) {
          _lastFilters = filterParams;
          _lastSearchQuery = widget.searchQuery;
          // Schedule the load for after the build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(partnerFilterProvider.notifier).loadWithFilters(filterParams);
          });
        }

        // Show loading on initial load
        if (partnerState.isLoading && partnerState.users.isEmpty) {
          return _buildLoading();
        }

        // Show error if any
        if (partnerState.error != null && partnerState.users.isEmpty) {
          return _buildError(partnerState.error);
        }

        final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

        // Apply session-based filters (skipped, waved, search)
        final filteredCommunities = _filterSessionUsers(
          partnerState.users,
          blockedUserIds,
        );

        debugPrint('🔍 Partner filter (server-side): ${partnerState.users.length} users, ${filteredCommunities.length} after session filter');

        // Load more when running low on users
        // But don't load more if server returned 0 users (search/filters matched nothing)
        if (filteredCommunities.length < 5 &&
            partnerState.users.isNotEmpty &&
            partnerState.hasMore &&
            !partnerState.isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(partnerFilterProvider.notifier).loadMore();
          });
        }

        if (filteredCommunities.isEmpty) {
          // If still loading more, show loading indicator
          if (partnerState.isLoadingMore) {
            return _buildLoading();
          }
          return _buildEmptyState();
        }

        // Build content based on view mode
        return Column(
          children: [
            // View mode toggle
            _buildViewToggle(),
            // Content
            Expanded(
              child: _viewMode == PartnerViewMode.list
                  ? _buildListView(filteredCommunities, partnerState.isLoadingMore, partnerState.hasMore)
                  : _buildCardStack(filteredCommunities, partnerState.isLoadingMore),
            ),
          ],
        );
      },
      loading: () => _buildLoading(),
      error: (e, s) => _buildError(e),
    );
  }

  /// Build view mode toggle
  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.containerColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: Icons.view_list_rounded,
                  label: 'List',
                  isSelected: _viewMode == PartnerViewMode.list,
                  onTap: () {
                    if (_viewMode != PartnerViewMode.list) _toggleViewMode();
                  },
                ),
                _buildViewModeButton(
                  icon: Icons.style_rounded,
                  label: 'Quick Match',
                  isSelected: _viewMode == PartnerViewMode.swipe,
                  onTap: () {
                    if (_viewMode != PartnerViewMode.swipe) _toggleViewMode();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build list view of partners
  Widget _buildListView(List<Community> communities, bool isLoadingMore, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(partnerFilterProvider.notifier).refresh();
        setState(() {
          _sessionSkippedUsers.clear();
          _sessionWavedUsers.clear();
        });
        await _loadServerExcludedUsers();
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: communities.length + (isLoadingMore || hasMore ? 1 : 0),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: context.dividerColor,
        ),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == communities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final community = communities[index];
          return PartnerListItem(
            user: community,
            onTap: () => _viewProfile(community),
            onWave: () => _onWaveFromButton(community),
            onMessage: () => _onMessage(community),
          );
        },
      ),
    );
  }

  Widget _buildCardStack(List<Community> communities, [bool isLoadingMore = false]) {
    if (communities.isEmpty) {
      return _buildAllDoneState();
    }

    final currentCommunity = communities.first;
    final hasNextCard = communities.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Show next card behind (if exists)
          if (hasNextCard)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.92,
                child: Opacity(
                  opacity: 0.4,
                  child: IgnorePointer(
                    child: PartnerCard(
                      user: communities[1],
                    ),
                  ),
                ),
              ),
            ),
          // Show loading indicator for next card if loading more
          if (!hasNextCard && isLoadingMore)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.92,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderXXL,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          // Current card - Swipeable
          Positioned.fill(
            child: Dismissible(
              key: ValueKey('card_${currentCommunity.id}'),
              direction: _isProcessingSwipe
                  ? DismissDirection.none
                  : DismissDirection.horizontal,
              dismissThresholds: const {
                DismissDirection.startToEnd: 0.25,
                DismissDirection.endToStart: 0.25,
              },
              movementDuration: const Duration(milliseconds: 200),
              onDismissed: (direction) {
                if (_isProcessingSwipe) return;
                _isProcessingSwipe = true;

                if (direction == DismissDirection.endToStart) {
                  // Swiped left - Skip
                  _sessionSkippedUsers.add(currentCommunity.id);
                  // Persist to server in background
                  InteractionService.skipUser(currentCommunity.id).then((result) {
                    debugPrint('⏭️ Skip (swipe) result: $result');
                  });
                  setState(() {
                    _isProcessingSwipe = false;
                  });
                } else {
                  // Swiped right - Wave
                  _onWaveFromSwipe(currentCommunity);
                }
              },
              background: _buildSwipeBackground(true),
              secondaryBackground: _buildSwipeBackground(false),
              child: PartnerCard(
                user: currentCommunity,
                onTap: () => _viewProfile(currentCommunity),
                onSkip: () {
                  if (_isProcessingSwipe) return;
                  _sessionSkippedUsers.add(currentCommunity.id);
                  // Persist to server in background
                  InteractionService.skipUser(currentCommunity.id).then((result) {
                    debugPrint('⏭️ Skip (button) result: $result');
                  });
                  setState(() {});
                },
                onWave: () => _onWaveFromButton(currentCommunity),
                onMessage: () => _onMessage(currentCommunity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(bool isWave) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: isWave
            ? AppColors.success.withOpacity(0.2)
            : context.textMuted.withOpacity(0.2),
        borderRadius: AppRadius.borderXXL,
      ),
      alignment: isWave ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWave ? Icons.waving_hand_rounded : Icons.close_rounded,
            color: isWave ? AppColors.success : context.textMuted,
            size: 48,
          ),
          Spacing.gapSM,
          Text(
            isWave ? 'Wave' : 'Skip',
            style: context.titleLarge.copyWith(
              color: isWave ? AppColors.success : context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentUserAsync = ref.watch(userProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        final nativeLang = currentUser.native_language;
        final learningLang = currentUser.language_to_learn;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 50,
                    color: context.textOnPrimary,
                  ),
                ),
                Spacing.gapXXL,
                Text(
                  'No partners found',
                  style: context.displaySmall,
                ),
                Spacing.gapMD,
                Text(
                  learningLang.isNotEmpty && nativeLang.isNotEmpty
                      ? 'No users found who speak $learningLang natively or want to learn $nativeLang.'
                      : 'Try adjusting your filters to find language exchange partners.',
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(color: context.textSecondary),
                ),
                Spacing.gapSM,
                Text(
                  'Try adjusting your filters or check back later.',
                  textAlign: TextAlign.center,
                  style: context.bodySmall.copyWith(color: context.textMuted),
                ),
                Spacing.gapXXL,
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(partnerFilterProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xxl,
                      vertical: Spacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildLoading(),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: context.textMuted,
              ),
              Spacing.gapLG,
              Text(
                'No partners found',
                style: context.titleLarge,
              ),
              Spacing.gapSM,
              Text(
                'Try adjusting your filters or search.',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoneState() {
    final partnerState = ref.watch(partnerFilterProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 50,
                color: context.textOnPrimary,
              ),
            ),
            Spacing.gapXXL,
            Text(
              partnerState.hasMore ? 'Loading more...' : 'All caught up!',
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              partnerState.hasMore
                  ? 'Finding more language partners for you...'
                  : 'You\'ve seen all available partners. Check back later for more!',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            if (partnerState.isLoadingMore)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xxl),
                child: CircularProgressIndicator(color: context.primaryColor),
              ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () {
                ref.read(partnerFilterProvider.notifier).refresh();
                setState(() {
                  _sessionSkippedUsers.clear();
                  _sessionWavedUsers.clear();
                  _isProcessingSwipe = false;
                });
                // Reload server excluded users
                _loadServerExcludedUsers();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start Over'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xxl,
                  vertical: Spacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.primaryColor,
          ),
          Spacing.gapLG,
          Text(
            'Finding partners...',
            style: context.bodyMedium.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: context.textMuted,
            ),
            Spacing.gapLG,
            Text(
              'Something went wrong',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: context.bodySmall,
            ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () {
                ref.read(partnerFilterProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

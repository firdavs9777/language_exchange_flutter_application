import 'dart:math' as math;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/services/interaction_service.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_filter_chip.dart';
import 'package:bananatalk_app/pages/community/widgets/visitor_recall_card.dart';

/// View mode for partner discovery
enum PartnerViewMode { list, swipe }

/// Partner Discovery Tab with list view (default) and swipe cards (Quick Match)
class PartnerDiscoveryTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;
  final VoidCallback? onClearFilters;

  const PartnerDiscoveryTab({
    super.key,
    required this.filters,
    required this.searchQuery,
    this.onClearFilters,
  });

  @override
  ConsumerState<PartnerDiscoveryTab> createState() =>
      _PartnerDiscoveryTabState();
}

class _PartnerDiscoveryTabState extends ConsumerState<PartnerDiscoveryTab> {
  String _userId = '';
  final Set<String> _sessionSkippedUsers = {}; // Local session cache
  final Set<String> _sessionWavedUsers = {}; // Local session cache
  Set<String> _serverExcludedUsers = {}; // Persisted skips/waves from server
  bool _isProcessingSwipe = false; // Prevent double swipes
  PartnerFilterParams? _lastFilters;
  String _lastSearchQuery = '';

  // Tracks which user ids have already played their entrance animation so it
  // runs once per user instead of replaying on every list rebuild.
  final Set<String> _animatedIds = {};

  // View mode state
  PartnerViewMode _viewMode = PartnerViewMode.list; // Default to list view
  static const _viewModeKey = 'partner_discovery_view_mode';
  final ScrollController _scrollController = ScrollController();

  // Quick filter chips state
  bool _quickOnlineOnly = false;
  String? _quickNativeLanguage; // "Show users who speak X natively"
  String? _quickLearningLanguage; // "Show users who are learning X"
  String? _sort; // null = default, 'recently_active' = sort by lastSeenAt

  // Tracks whether the list has been scrolled — used to elevate the chip bar.
  bool _isScrolled = false;

  // Whether the user dismissed the "set your location" banner this session.
  bool _locationReminderDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadServerExcludedUsers();
    _loadViewMode();
    _scrollController.addListener(_onScroll);
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
        _viewMode = savedMode == 'swipe'
            ? PartnerViewMode.swipe
            : PartnerViewMode.list;
      });
    }
  }

  /// Save view mode preference
  Future<void> _saveViewMode(PartnerViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _viewModeKey,
      mode == PartnerViewMode.swipe ? 'swipe' : 'list',
    );
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

    // Track scroll for sticky chip elevation
    final scrolled = _scrollController.position.pixels > 8;
    if (scrolled != _isScrolled && mounted) {
      setState(() => _isScrolled = scrolled);
    }

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
        setState(() => _serverExcludedUsers = excluded);
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  @override
  void didUpdateWidget(PartnerDiscoveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data only when filters/search actually change by VALUE.
    //
    // NOTE: filters is a Map, and the parent hands us a fresh Map instance on
    // every rebuild (e.g. tab switches). Comparing with `!=` would treat every
    // parent rebuild as a change and trigger a needless reload, so we compare
    // contents with mapEquals.
    final filtersChanged = !mapEquals(oldWidget.filters, widget.filters);
    final searchChanged = oldWidget.searchQuery != widget.searchQuery;
    if (filtersChanged || searchChanged) {
      _lastFilters = null; // build() will pick up the change and reload
      _lastSearchQuery = '';
      _animatedIds.clear();
      if (filtersChanged) _locationReminderDismissed = false;
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _userId = prefs.getString('userId') ?? '');
  }

  /// Build filter params from current user and UI filters.
  ///
  /// IMPORTANT: API semantics are inverted for language-exchange matching:
  /// - API nativeLanguage param → finds users LEARNING this language
  /// - API learningLanguage param → finds users who SPEAK this language natively
  ///
  /// So when the user selects "Native Language: French" (wants to SEE French
  /// speakers), we pass it as learningLanguage to the API.
  PartnerFilterParams _buildFilterParams(String? myNative, String? myLearning) {
    final filterNative = widget.filters['nativeLanguage']?.toString();
    final filterLearning = widget.filters['learningLanguage']?.toString();

    final hasFilterNative = filterNative != null && filterNative.isNotEmpty;
    final hasFilterLearning =
        filterLearning != null && filterLearning.isNotEmpty;

    String? apiNativeParam; // API: finds users LEARNING this language
    String? apiLearningParam; // API: finds users who SPEAK this natively

    if (hasFilterNative || hasFilterLearning) {
      // Explicit filters — apply only what was selected (no exchange mixing).
      if (hasFilterNative) apiLearningParam = filterNative;
      if (hasFilterLearning) apiNativeParam = filterLearning;
    } else {
      // Default: language-exchange matching.
      apiLearningParam = myLearning;
      apiNativeParam = myNative;
    }

    // Quick chips override the full filter screen and focus on one criterion.
    if (_quickNativeLanguage != null) {
      apiLearningParam = _quickNativeLanguage;
      if (_quickLearningLanguage == null) apiNativeParam = null;
    }
    if (_quickLearningLanguage != null) {
      apiNativeParam = _quickLearningLanguage;
      if (_quickNativeLanguage == null) apiLearningParam = null;
    }

    return PartnerFilterParams(
      nativeLanguage: apiNativeParam,
      learningLanguage: apiLearningParam,
      gender: widget.filters['gender']?.toString(),
      minAge: widget.filters['minAge'] as int?,
      maxAge: widget.filters['maxAge'] as int?,
      onlineOnly: widget.filters['onlineOnly'] == true || _quickOnlineOnly,
      country: widget.filters['country']?.toString(),
      languageLevel: widget.filters['languageLevel']?.toString(),
      search: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
      sort: _sort,
    );
  }

  /// Filter out session-skipped/waved/blocked users for instant UI feedback.
  List<Community> _filterSessionUsers(
    List<Community> users,
    Set<String> blockedUserIds,
  ) {
    return users.where((user) {
      if (user.id == _userId) return false;
      if (blockedUserIds.contains(user.id)) return false;
      if (_sessionSkippedUsers.contains(user.id)) return false;
      if (_sessionWavedUsers.contains(user.id)) return false;
      if (_serverExcludedUsers.contains(user.id)) return false;
      return true;
    }).toList();
  }

  /// Send wave sticker message in background (fire and forget).
  Future<void> _sendWaveSticker(String receiverId) async {
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(receiver: receiverId, message: '👋');
    } catch (_) {
      // Non-fatal: wave still recorded server-side via waveUser.
    }
  }

  void _navigateToChat(Community community) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ChatScreen(
          userId: community.id,
          userName: community.name,
          profilePicture: community.profileImageUrl,
          isVip: community.isVip,
        ),
      ),
    );
  }

  void _onWaveFromButton(Community community) {
    HapticFeedback.mediumImpact();
    _sessionWavedUsers.add(community.id);
    InteractionService.waveUser(community.id);
    _navigateToChat(community);
    _sendWaveSticker(community.id);
  }

  void _onWaveFromSwipe(Community community) {
    HapticFeedback.mediumImpact();
    _sessionWavedUsers.add(community.id);
    InteractionService.waveUser(community.id);
    setState(() => _isProcessingSwipe = false);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _navigateToChat(community);
    });
    _sendWaveSticker(community.id);
  }

  void _onMessage(Community community) => _navigateToChat(community);

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => SingleCommunity(community: community)),
    );
  }

  void _skip(Community community) {
    _sessionSkippedUsers.add(community.id);
    InteractionService.skipUser(community.id);
  }

  @override
  Widget build(BuildContext context) {
    final partnerState = ref.watch(partnerFilterProvider);
    final currentUserAsync = ref.watch(userProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        final filterParams = _buildFilterParams(
          currentUser.native_language,
          currentUser.language_to_learn,
        );

        // Reload when filters or search query change (or on first build).
        final searchChanged = _lastSearchQuery != widget.searchQuery;
        if (_lastFilters != filterParams || searchChanged) {
          _lastFilters = filterParams;
          _lastSearchQuery = widget.searchQuery;
          Future(() {
            if (!mounted) return;
            ref
                .read(partnerFilterProvider.notifier)
                .loadWithFilters(filterParams);
          });
        }

        if (partnerState.isLoading && partnerState.users.isEmpty) {
          return _buildLoading();
        }
        if (partnerState.error != null && partnerState.users.isEmpty) {
          return _buildError(partnerState.error);
        }

        final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
        var filteredCommunities = _filterSessionUsers(
          partnerState.users,
          blockedUserIds,
        );

        // Client-side: new users only.
        if (widget.filters['newUsersOnly'] == true) {
          filteredCommunities = filteredCommunities
              .where((u) => u.isNewUser)
              .toList();
        }

        // Client-side: prioritize nearby (sort by distance).
        if (widget.filters['prioritizeNearby'] == true) {
          _sortByProximity(filteredCommunities, currentUser);
        }

        // Top up when running low (but not if the server returned nothing).
        if (filteredCommunities.length < 5 &&
            partnerState.users.isNotEmpty &&
            partnerState.hasMore &&
            !partnerState.isLoadingMore) {
          Future(() {
            if (!mounted) return;
            ref.read(partnerFilterProvider.notifier).loadMore();
          });
        }

        if (filteredCommunities.isEmpty) {
          if (partnerState.isLoadingMore) return _buildLoading();
          return _buildEmptyState();
        }

        final myCoords = currentUser.location.coordinates;
        final userHasLocation =
            myCoords.length >= 2 && (myCoords[0] != 0.0 || myCoords[1] != 0.0);

        return Column(
          children: [
            // Sticky bar: view toggle + quick filter chips, elevates on scroll.
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                boxShadow: _isScrolled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggle(),
                  _buildQuickFilterChips(currentUser),
                ],
              ),
            ),
            if (widget.filters['prioritizeNearby'] == true &&
                !userHasLocation &&
                !_locationReminderDismissed)
              _buildLocationReminder(),
            Expanded(
              child: _viewMode == PartnerViewMode.list
                  ? _buildListView(
                      filteredCommunities,
                      partnerState.isLoadingMore,
                      partnerState.hasMore,
                      currentUser,
                    )
                  : _buildCardStack(
                      filteredCommunities,
                      partnerState.isLoadingMore,
                    ),
            ),
          ],
        );
      },
      loading: () => _buildLoading(),
      error: (e, s) => _buildError(e),
    );
  }

  /// Sort communities by distance from the current user, in place.
  void _sortByProximity(List<Community> list, dynamic currentUser) {
    final myCoords = currentUser.location.coordinates;
    final myHasCoords =
        myCoords.length >= 2 && (myCoords[0] != 0.0 || myCoords[1] != 0.0);
    final myCountry = currentUser.location.country;

    list.sort((a, b) {
      final aCoords = a.location.coordinates;
      final bCoords = b.location.coordinates;
      final aHasCoords =
          aCoords.length >= 2 && (aCoords[0] != 0.0 || aCoords[1] != 0.0);
      final bHasCoords =
          bCoords.length >= 2 && (bCoords[0] != 0.0 || bCoords[1] != 0.0);

      if (aHasCoords && !bHasCoords) return -1;
      if (!aHasCoords && bHasCoords) return 1;
      if (!aHasCoords && !bHasCoords) return 0;

      if (myHasCoords) {
        final aDist = _haversineDistance(
          myCoords[0],
          myCoords[1],
          aCoords[0],
          aCoords[1],
        );
        final bDist = _haversineDistance(
          myCoords[0],
          myCoords[1],
          bCoords[0],
          bCoords[1],
        );
        return aDist.compareTo(bDist);
      }

      if (myCountry.isNotEmpty) {
        final aMatch = a.location.country == myCountry;
        final bMatch = b.location.country == myCountry;
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
      }
      return 0;
    });
  }

  /// Build view mode toggle
  Widget _buildViewToggle() {
    final l10n = AppLocalizations.of(context)!;
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
                _ViewModeButton(
                  icon: Icons.view_list_rounded,
                  label: l10n.listView,
                  isSelected: _viewMode == PartnerViewMode.list,
                  onTap: () {
                    if (_viewMode != PartnerViewMode.list) _toggleViewMode();
                  },
                ),
                _ViewModeButton(
                  icon: Icons.style_rounded,
                  label: l10n.quickMatch,
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

  /// Build quick filter chips
  Widget _buildQuickFilterChips(dynamic currentUser) {
    final l10n = AppLocalizations.of(context)!;
    final String userLearning = currentUser.language_to_learn ?? '';
    final String userNative = currentUser.native_language ?? '';

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Recently Active sort chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CommunityFilterChip(
              label: l10n.sortRecentlyActive,
              icon: Icons.access_time_rounded,
              isSelected: _sort == 'recently_active',
              onTap: () {
                setState(() {
                  _sort = _sort == 'recently_active' ? null : 'recently_active';
                });
                _lastFilters = null; // Force reload
              },
            ),
          ),
          // Online Now chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildLanguageChip(
              labelWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.onlineNow),
                ],
              ),
              selected: _quickOnlineOnly,
              onSelected: (selected) {
                setState(() => _quickOnlineOnly = selected);
                _lastFilters = null; // Force reload
              },
            ),
          ),
          // "Speaks [user's learning language]" chip
          if (userLearning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildLanguageChip(
                label: l10n.speaksLanguage(_capitalizeFirst(userLearning)),
                selected: _quickNativeLanguage == userLearning,
                onSelected: (selected) {
                  setState(() {
                    _quickNativeLanguage = selected ? userLearning : null;
                  });
                  _lastFilters = null; // Force reload
                },
              ),
            ),
          // "Learning [user's native language]" chip
          if (userNative.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildLanguageChip(
                label: l10n.learningLanguage(_capitalizeFirst(userNative)),
                selected: _quickLearningLanguage == userNative,
                onSelected: (selected) {
                  setState(() {
                    _quickLearningLanguage = selected ? userNative : null;
                  });
                  _lastFilters = null; // Force reload
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Shared FilterChip styling for the quick chips (removes the duplicated
  /// styling block that was repeated 3×).
  Widget _buildLanguageChip({
    String? label,
    Widget? labelWidget,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: labelWidget ?? Text(label ?? ''),
      selected: selected,
      onSelected: onSelected,
      selectedColor: context.primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : context.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: context.containerColor,
      side: BorderSide(
        color: selected ? context.primaryColor : context.dividerColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  /// Banner reminding user to set location for nearby feature.
  Widget _buildLocationReminder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 18,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.setLocationReminder,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _locationReminderDismissed = true),
            child: Icon(Icons.close, size: 16, color: Colors.orange.shade400),
          ),
        ],
      ),
    );
  }

  /// Haversine distance in km between two coordinates.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double deg) => deg * math.pi / 180;

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }

  /// Build list view of partners.
  Widget _buildListView(
    List<Community> communities,
    bool isLoadingMore,
    bool hasMore, [
    dynamic currentUser,
  ]) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(partnerFilterProvider.notifier).refresh();
        setState(() {
          _sessionSkippedUsers.clear();
          _sessionWavedUsers.clear();
          _animatedIds.clear();
        });
        await _loadServerExcludedUsers();
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: communities.length + 1 + (isLoadingMore || hasMore ? 1 : 0),
        separatorBuilder: (context, index) => index == 0
            ? const SizedBox.shrink()
            : Divider(height: 1, color: context.dividerColor),
        itemBuilder: (context, index) {
          // Header (index 0): profile-visitor card + banner ad.
          // VisitorRecallCard collapses to zero height when there are no
          // visitors, so it scrolls away with the list and never pins the top.
          if (index == 0) {
            return const Column(
              children: [
                VisitorRecallCard(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BannerAdWidget(),
                ),
              ],
            );
          }

          final realIndex = index - 1;

          // Loading indicator at the end.
          if (realIndex == communities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final community = communities[realIndex];
          final item = PartnerListItem(
            user: community,
            currentUser: currentUser is Community ? currentUser : null,
            onTap: () => _viewProfile(community),
            onWave: () => _onWaveFromButton(community),
            onMessage: () => _onMessage(community),
          );

          // Animate each user in once, not on every rebuild.
          if (!_animatedIds.add(community.id)) return item;

          final delay = Duration(milliseconds: (index * 40).clamp(0, 400));
          return item
              .animate()
              .fadeIn(duration: 300.ms, delay: delay)
              .slideX(
                begin: 0.04,
                end: 0,
                duration: 300.ms,
                delay: delay,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }

  Widget _buildCardStack(
    List<Community> communities, [
    bool isLoadingMore = false,
  ]) {
    if (communities.isEmpty) return _buildAllDoneState();

    final currentCommunity = communities.first;
    final hasNextCard = communities.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Stack(
        children: [
          if (hasNextCard)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.92,
                child: Opacity(
                  opacity: 0.4,
                  child: IgnorePointer(
                    child: PartnerCard(user: communities[1]),
                  ),
                ),
              ),
            ),
          if (!hasNextCard && isLoadingMore)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.92,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.sm,
                  ),
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
                if (direction == DismissDirection.endToStart) {
                  // Swiped left → Skip
                  _skip(currentCommunity);
                  setState(() {});
                } else {
                  // Swiped right → Wave
                  _isProcessingSwipe = true;
                  _onWaveFromSwipe(currentCommunity);
                }
              },
              background: _SwipeBackground(isWave: true),
              secondaryBackground: _SwipeBackground(isWave: false),
              child: PartnerCard(
                user: currentCommunity,
                onTap: () => _viewProfile(currentCommunity),
                onSkip: () {
                  if (_isProcessingSwipe) return;
                  _skip(currentCommunity);
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

  /// Check if any non-default filters are active.
  bool get _hasActiveFilters {
    final f = widget.filters;
    return f['gender'] != null ||
        f['nativeLanguage'] != null ||
        f['learningLanguage'] != null ||
        f['languageLevel'] != null ||
        f['country'] != null ||
        (f['minAge'] != null && f['minAge'] != 18) ||
        (f['maxAge'] != null && f['maxAge'] != 100) ||
        f['onlineOnly'] == true ||
        _quickOnlineOnly ||
        _quickNativeLanguage != null ||
        _quickLearningLanguage != null;
  }

  Widget _buildEmptyState() {
    final currentUserAsync = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    return currentUserAsync.when(
      data: (currentUser) {
        final nativeLang = currentUser.native_language;
        final learningLang = currentUser.language_to_learn;

        return Center(
          child: SingleChildScrollView(
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
                Text(l10n.noPartnersFound, style: context.displaySmall),
                Spacing.gapMD,
                Text(
                  learningLang.isNotEmpty && nativeLang.isNotEmpty
                      ? l10n.noUsersFoundForLanguages(learningLang, nativeLang)
                      : l10n.tryAdjustingFilters,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Spacing.gapXXL,
                if (_hasActiveFilters) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _quickOnlineOnly = false;
                          _quickNativeLanguage = null;
                          _quickLearningLanguage = null;
                        });
                        widget.onClearFilters?.call();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: Text(l10n.removeAllFilters),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primaryColor,
                        side: BorderSide(color: context.primaryColor),
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMD,
                        ),
                      ),
                    ),
                  ),
                  Spacing.gapSM,
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _quickNativeLanguage = null;
                        _quickLearningLanguage = null;
                        _lastFilters = null;
                      });
                      ref
                          .read(partnerFilterProvider.notifier)
                          .loadWithFilters(
                            PartnerFilterParams(
                              gender: widget.filters['gender']?.toString(),
                              minAge: widget.filters['minAge'] as int?,
                              maxAge: widget.filters['maxAge'] as int?,
                              country: widget.filters['country']?.toString(),
                              onlineOnly: _quickOnlineOnly,
                            ),
                          );
                    },
                    icon: const Icon(Icons.people_rounded),
                    label: Text(l10n.browseAllUsers),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textSecondary,
                      side: BorderSide(color: context.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                  ),
                ),
                Spacing.gapSM,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(partnerFilterProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.refresh),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
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
              Text(l10n.noPartnersFound, style: context.titleLarge),
              Spacing.gapSM,
              Text(
                l10n.tryAdjustingFilters,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoneState() {
    final partnerState = ref.watch(partnerFilterProvider);
    final l10n = AppLocalizations.of(context)!;

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
              partnerState.hasMore ? l10n.loadingMore : l10n.allCaughtUp,
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              partnerState.hasMore
                  ? l10n.findingMorePartners
                  : l10n.seenAllPartners,
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
                  _animatedIds.clear();
                  _isProcessingSwipe = false;
                });
                _loadServerExcludedUsers();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.startOver),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xxl,
                  vertical: Spacing.md,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
              ),
            ),
            Spacing.gapSM,
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _quickOnlineOnly = false;
                  _quickNativeLanguage = null;
                  _quickLearningLanguage = null;
                });
                widget.onClearFilters?.call();
              },
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.changeFilters),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                side: BorderSide(color: context.primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xxl,
                  vertical: Spacing.md,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() => const UserListSkeleton(count: 6);

  Widget _buildError(dynamic error) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.somethingWentWrong, style: context.titleLarge),
            Spacing.gapSM,
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: context.bodySmall,
            ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(partnerFilterProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
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

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SwipeBackground extends StatelessWidget {
  final bool isWave;

  const _SwipeBackground({required this.isWave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isWave
            ? AppColors.success.withValues(alpha: 0.2)
            : context.textMuted.withValues(alpha: 0.2),
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
}

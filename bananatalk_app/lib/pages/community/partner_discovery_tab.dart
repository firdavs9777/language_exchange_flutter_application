import 'dart:math' as math;
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
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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

  // Quick filter chips state
  bool _quickOnlineOnly = false;
  String? _quickNativeLanguage; // "Show users who speak X natively"
  String? _quickLearningLanguage; // "Show users who are learning X"

  // Tracks whether the list has been scrolled — used to elevate the sticky chip bar
  bool _isScrolled = false;

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
        setState(() {
          _serverExcludedUsers = excluded;
        });
      }
    } catch (e) {
    }
  }

  @override
  void didUpdateWidget(PartnerDiscoveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when filters or search query change
    if (oldWidget.filters != widget.filters ||
        oldWidget.searchQuery != widget.searchQuery) {
      // Reset tracked values so build() will pick up the change
      _lastFilters = null;
      _lastSearchQuery = '';
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


    // Quick filter chips override full filter screen values
    // When a quick chip is active, ONLY apply that filter (clear the other)
    // so results are focused on just the selected criterion
    if (_quickNativeLanguage != null) {
      // Quick chip: "Speaks X" → pass as learningLanguage to API (inverted semantics)
      apiLearningParam = _quickNativeLanguage;
      // Clear the other param so we only filter by this criterion
      if (_quickLearningLanguage == null) {
        apiNativeParam = null;
      }
    }
    if (_quickLearningLanguage != null) {
      // Quick chip: "Learning X" → pass as nativeLanguage to API (inverted semantics)
      apiNativeParam = _quickLearningLanguage;
      // Clear the other param so we only filter by this criterion
      if (_quickNativeLanguage == null) {
        apiLearningParam = null;
      }
    }

    final params = PartnerFilterParams(
      nativeLanguage: apiNativeParam,
      learningLanguage: apiLearningParam,
      gender: widget.filters['gender']?.toString(),
      minAge: widget.filters['minAge'] as int?,
      maxAge: widget.filters['maxAge'] as int?,
      onlineOnly: widget.filters['onlineOnly'] == true || _quickOnlineOnly,
      country: widget.filters['country']?.toString(),
      languageLevel: widget.filters['languageLevel']?.toString(),
      search: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
    );


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
    }
  }

  void _onWaveFromButton(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved locally for instant UI
    _sessionWavedUsers.add(community.id);

    // Persist to server in background
    InteractionService.waveUser(community.id).then((result) {
    });

    // Navigate to chat
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

    // Send wave sticker in background
    _sendWaveSticker(community.id);
  }

  void _onWaveFromSwipe(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved locally for instant UI
    _sessionWavedUsers.add(community.id);

    // Persist to server in background
    InteractionService.waveUser(community.id).then((result) {
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
    });

    // Send wave sticker in background
    _sendWaveSticker(community.id);
  }

  void _onMessage(Community community) {
    // Navigate directly to chat screen
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

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      AppPageRoute(
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
          // Schedule the load after the current frame to avoid provider conflicts
          Future(() {
            if (!mounted) return;
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
        var filteredCommunities = _filterSessionUsers(
          partnerState.users,
          blockedUserIds,
        );

        // Client-side: filter new users only
        if (widget.filters['newUsersOnly'] == true) {
          filteredCommunities = filteredCommunities
              .where((u) => u.isNewUser)
              .toList();
        }

        // Client-side: prioritize nearby (sort by distance from current user)
        if (widget.filters['prioritizeNearby'] == true) {
          final myCoords = currentUser.location.coordinates;
          final myHasCoords = myCoords.length >= 2 && (myCoords[0] != 0.0 || myCoords[1] != 0.0);

          filteredCommunities.sort((a, b) {
            final aCoords = a.location.coordinates;
            final bCoords = b.location.coordinates;
            final aHasCoords = aCoords.length >= 2 && (aCoords[0] != 0.0 || aCoords[1] != 0.0);
            final bHasCoords = bCoords.length >= 2 && (bCoords[0] != 0.0 || bCoords[1] != 0.0);

            // Users without coordinates go to the bottom
            if (aHasCoords && !bHasCoords) return -1;
            if (!aHasCoords && bHasCoords) return 1;
            if (!aHasCoords && !bHasCoords) return 0;

            // If current user has coordinates, sort by distance
            if (myHasCoords) {
              final aDist = _haversineDistance(myCoords[0], myCoords[1], aCoords[0], aCoords[1]);
              final bDist = _haversineDistance(myCoords[0], myCoords[1], bCoords[0], bCoords[1]);
              return aDist.compareTo(bDist);
            }

            // Fallback: same country first
            final myCountry = currentUser.location.country;
            if (myCountry.isNotEmpty) {
              final aMatch = a.location.country == myCountry;
              final bMatch = b.location.country == myCountry;
              if (aMatch && !bMatch) return -1;
              if (!aMatch && bMatch) return 1;
            }
            return 0;
          });
        }

        // Load more when running low on users
        // But don't load more if server returned 0 users (search/filters matched nothing)
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
          // If still loading more, show loading indicator
          if (partnerState.isLoadingMore) {
            return _buildLoading();
          }
          return _buildEmptyState();
        }

        // Check if user has location set (for nearby banner)
        final myCoords = currentUser.location.coordinates;
        final userHasLocation = myCoords.length >= 2 && (myCoords[0] != 0.0 || myCoords[1] != 0.0);

        // Build content based on view mode
        return Column(
          children: [
            // Sticky bar: view toggle + quick filter chips. Elevation animates on scroll.
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
            // Location reminder when prioritize nearby is on but no location
            if (widget.filters['prioritizeNearby'] == true && !userHasLocation)
              _buildLocationReminder(),
            // Content
            Expanded(
              child: _viewMode == PartnerViewMode.list
                  ? _buildListView(filteredCommunities, partnerState.isLoadingMore, partnerState.hasMore, currentUser)
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
                  label: AppLocalizations.of(context)!.listView,
                  isSelected: _viewMode == PartnerViewMode.list,
                  onTap: () {
                    if (_viewMode != PartnerViewMode.list) _toggleViewMode();
                  },
                ),
                _buildViewModeButton(
                  icon: Icons.style_rounded,
                  label: AppLocalizations.of(context)!.quickMatch,
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

  /// Build quick filter chips
  Widget _buildQuickFilterChips(dynamic currentUser) {
    final String userLearning = currentUser.language_to_learn ?? '';
    final String userNative = currentUser.native_language ?? '';

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Online Now chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
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
                  Text(AppLocalizations.of(context)!.onlineNow),
                ],
              ),
              selected: _quickOnlineOnly,
              onSelected: (selected) {
                setState(() => _quickOnlineOnly = selected);
                _lastFilters = null; // Force reload
              },
              selectedColor: context.primaryColor,
              labelStyle: TextStyle(
                color: _quickOnlineOnly ? Colors.white : context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: context.containerColor,
              side: BorderSide(
                color: _quickOnlineOnly ? context.primaryColor : context.dividerColor,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          ),
          // "Speaks [user's learning language]" chip
          if (userLearning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(AppLocalizations.of(context)!.speaksLanguage(_capitalizeFirst(userLearning))),
                selected: _quickNativeLanguage == userLearning,
                onSelected: (selected) {
                  setState(() {
                    _quickNativeLanguage = selected ? userLearning : null;
                  });
                  _lastFilters = null; // Force reload
                },
                selectedColor: context.primaryColor,
                labelStyle: TextStyle(
                  color: _quickNativeLanguage == userLearning ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: context.containerColor,
                side: BorderSide(
                  color: _quickNativeLanguage == userLearning ? context.primaryColor : context.dividerColor,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            ),
          // "Learning [user's native language]" chip
          if (userNative.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(AppLocalizations.of(context)!.learningLanguage(_capitalizeFirst(userNative))),
                selected: _quickLearningLanguage == userNative,
                onSelected: (selected) {
                  setState(() {
                    _quickLearningLanguage = selected ? userNative : null;
                  });
                  _lastFilters = null; // Force reload
                },
                selectedColor: context.primaryColor,
                labelStyle: TextStyle(
                  color: _quickLearningLanguage == userNative ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: context.containerColor,
                side: BorderSide(
                  color: _quickLearningLanguage == userNative ? context.primaryColor : context.dividerColor,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }

  /// Banner reminding user to set location for nearby feature
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
          const Icon(Icons.location_off_rounded, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.setLocationReminder,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              // Dismiss the banner by turning off prioritize nearby
              setState(() {});
            },
            child: Icon(Icons.close, size: 16, color: Colors.orange.shade400),
          ),
        ],
      ),
    );
  }

  /// Haversine distance in km between two coordinates
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double deg) => deg * math.pi / 180;

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }

  /// Build list view of partners
  Widget _buildListView(List<Community> communities, bool isLoadingMore, bool hasMore, [dynamic currentUser]) {
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
        itemCount: communities.length + 1 + (isLoadingMore || hasMore ? 1 : 0),
        separatorBuilder: (context, index) => index == 0
            ? const SizedBox.shrink()
            : Divider(
                height: 1,
                color: context.dividerColor,
              ),
        itemBuilder: (context, index) {
          // Banner ad at position 0
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: BannerAdWidget(),
            );
          }

          final realIndex = index - 1;

          // Loading indicator at the end
          if (realIndex == communities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final community = communities[realIndex];
          return PartnerListItem(
            user: community,
            currentUser: currentUser is Community ? currentUser : null,
            onTap: () => _viewProfile(community),
            onWave: () => _onWaveFromButton(community),
            onMessage: () => _onMessage(community),
          )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
              )
              .slideX(
                begin: 0.04,
                end: 0,
                duration: 300.ms,
                delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                curve: Curves.easeOutCubic,
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
      padding: const EdgeInsets.only(bottom: 100),
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

  /// Check if any non-default filters are active
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
                Text(
                  AppLocalizations.of(context)!.noPartnersFound,
                  style: context.displaySmall,
                ),
                Spacing.gapMD,
                Text(
                  learningLang.isNotEmpty && nativeLang.isNotEmpty
                      ? AppLocalizations.of(context)!.noUsersFoundForLanguages(learningLang, nativeLang)
                      : AppLocalizations.of(context)!.tryAdjustingFilters,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(color: context.textSecondary),
                ),
                Spacing.gapXXL,
                // Actionable buttons
                if (_hasActiveFilters) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Clear quick filters
                        setState(() {
                          _quickOnlineOnly = false;
                          _quickNativeLanguage = null;
                          _quickLearningLanguage = null;
                        });
                        // Clear full filters
                        widget.onClearFilters?.call();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: Text(AppLocalizations.of(context)!.removeAllFilters),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primaryColor,
                        side: BorderSide(color: context.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
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
                      // Clear only language filters, keep other filters
                      setState(() {
                        _quickNativeLanguage = null;
                        _quickLearningLanguage = null;
                        _lastFilters = null;
                      });
                      ref.read(partnerFilterProvider.notifier).loadWithFilters(
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
                    label: Text(AppLocalizations.of(context)!.browseAllUsers),
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
                    onPressed: () {
                      ref.read(partnerFilterProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context)!.refresh),
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
              Text(
                AppLocalizations.of(context)!.noPartnersFound,
                style: context.titleLarge,
              ),
              Spacing.gapSM,
              Text(
                AppLocalizations.of(context)!.tryAdjustingFilters,
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
              partnerState.hasMore ? AppLocalizations.of(context)!.loadingMore : AppLocalizations.of(context)!.allCaughtUp,
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              partnerState.hasMore
                  ? AppLocalizations.of(context)!.findingMorePartners
                  : AppLocalizations.of(context)!.seenAllPartners,
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
              label: Text(AppLocalizations.of(context)!.startOver),
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
            Spacing.gapSM,
            OutlinedButton.icon(
              onPressed: () {
                // Clear quick filters and full filters
                setState(() {
                  _quickOnlineOnly = false;
                  _quickNativeLanguage = null;
                  _quickLearningLanguage = null;
                });
                widget.onClearFilters?.call();
              },
              icon: const Icon(Icons.tune_rounded),
              label: Text(AppLocalizations.of(context)!.changeFilters),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                side: BorderSide(color: context.primaryColor),
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
    return const UserListSkeleton(count: 6);
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
              AppLocalizations.of(context)!.somethingWentWrong,
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
              label: Text(AppLocalizations.of(context)!.retry),
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

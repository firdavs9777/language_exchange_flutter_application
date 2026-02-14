import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Partner Discovery Tab with swipeable cards
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
  final Set<String> _skippedUsers = {};
  final Set<String> _wavedUsers = {};
  bool _isProcessingSwipe = false; // Prevent double swipes
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didUpdateWidget(PartnerDiscoveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when filters change
    if (oldWidget.filters != widget.filters) {
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
      ref.read(paginatedCommunityProvider.notifier).loadInitial();
    }
  }

  void _refreshData() {
    ref.read(paginatedCommunityProvider.notifier).refresh();
  }

  void _loadMoreIfNeeded(int filteredCount) {
    // Load more when we have less than 5 filtered users available
    if (filteredCount < 5) {
      final state = ref.read(paginatedCommunityProvider);
      if (state.hasMore && !state.isLoadingMore) {
        ref.read(paginatedCommunityProvider.notifier).loadMore();
      }
    }
  }

  /// Normalize gender values to handle different formats
  String _normalizeGender(String gender) {
    final normalized = gender.toLowerCase().trim();
    const maleVariants = ['male', 'm', 'man', 'boy', '남성', '남자', '男', '男性', 'мужской', 'мужчина', 'masculino', 'hombre', 'ذكر'];
    const femaleVariants = ['female', 'f', 'woman', 'girl', '여성', '여자', '女', '女性', 'женский', 'женщина', 'femenino', 'mujer', 'أنثى'];
    const otherVariants = ['other', 'non-binary', 'nonbinary', 'nb', '기타', '其他', 'другой', 'otro', 'آخر'];

    if (maleVariants.contains(normalized)) return 'male';
    if (femaleVariants.contains(normalized)) return 'female';
    if (otherVariants.contains(normalized)) return 'other';

    return normalized;
  }

  /// Normalize country names to handle different languages and formats
  /// Maps localized country names to their English equivalents
  String _normalizeCountry(String country) {
    // Country name mapping (localized name -> English name)
    const countryMap = {
      // Korean
      '대한민국': 'south korea',
      '한국': 'south korea',
      '북한': 'north korea',
      '일본': 'japan',
      '중국': 'china',
      '미국': 'united states',
      '영국': 'united kingdom',
      '프랑스': 'france',
      '독일': 'germany',
      '호주': 'australia',
      '캐나다': 'canada',
      '러시아': 'russia',
      '필리핀': 'philippines',
      // Chinese
      '中国': 'china',
      '中國': 'china',
      '日本': 'japan',
      '韩国': 'south korea',
      '韓國': 'south korea',
      '美国': 'united states',
      '美國': 'united states',
      '英国': 'united kingdom',
      '英國': 'united kingdom',
      '法国': 'france',
      '法國': 'france',
      '德国': 'germany',
      '德國': 'germany',
      '澳大利亚': 'australia',
      '澳洲': 'australia',
      '加拿大': 'canada',
      '俄罗斯': 'russia',
      '俄羅斯': 'russia',
      '菲律宾': 'philippines',
      '菲律賓': 'philippines',
      // Japanese
      '日本国': 'japan',
      'アメリカ': 'united states',
      'イギリス': 'united kingdom',
      '韓国': 'south korea',
      'オーストラリア': 'australia',
      'カナダ': 'canada',
      'フランス': 'france',
      'ドイツ': 'germany',
      'ロシア': 'russia',
      'フィリピン': 'philippines',
      // Russian
      'сша': 'united states',
      'соединённые штаты': 'united states',
      'америка': 'united states',
      'россия': 'russia',
      'китай': 'china',
      'япония': 'japan',
      'корея': 'south korea',
      'южная корея': 'south korea',
      'филиппины': 'philippines',
      // Spanish
      'estados unidos': 'united states',
      'reino unido': 'united kingdom',
      'alemania': 'germany',
      'francia': 'france',
      'japón': 'japan',
      'corea del sur': 'south korea',
      'filipinas': 'philippines',
      // Arabic
      'الولايات المتحدة': 'united states',
      'أمريكا': 'united states',
      'الصين': 'china',
      'اليابان': 'japan',
      'كوريا الجنوبية': 'south korea',
      'روسيا': 'russia',
      'الفلبين': 'philippines',
      // Common abbreviations
      'us': 'united states',
      'usa': 'united states',
      'uk': 'united kingdom',
      'uae': 'united arab emirates',
      'kr': 'south korea',
      'jp': 'japan',
      'cn': 'china',
      'ph': 'philippines',
      'au': 'australia',
      'ca': 'canada',
      'de': 'germany',
      'fr': 'france',
      'ru': 'russia',
      // Common variations
      'america': 'united states',
      'korea': 'south korea',
      'republic of korea': 'south korea',
      "people's republic of china": 'china',
      'prc': 'china',
    };

    final normalized = country.toLowerCase().trim();
    return countryMap[normalized] ?? normalized;
  }

  List<Community> _getFilteredCommunities(
    List<Community> communities,
    String? myNativeLanguage,
    String? myLanguageToLearn,
    Set<String> blockedUserIds,
  ) {
    return communities.where((community) {
      // Exclude current user
      if (community.id == _userId) return false;

      // Exclude blocked users
      if (blockedUserIds.contains(community.id)) return false;

      // Exclude already skipped or waved
      if (_skippedUsers.contains(community.id)) return false;
      if (_wavedUsers.contains(community.id)) return false;

      // Apply age filter - only filter out users who have age data that doesn't match
      // Users without age data are included (we can't verify their age)
      final minAge = widget.filters['minAge'] as int?;
      final maxAge = widget.filters['maxAge'] as int?;
      final hasCustomAgeFilter = (minAge != null && minAge > 18) || (maxAge != null && maxAge < 100);

      if (hasCustomAgeFilter) {
        final age = community.age;
        if (age != null) {
          if (minAge != null && age < minAge) return false;
          if (maxAge != null && age > maxAge) return false;
        }
      }

      // Apply gender filter with normalization
      if (widget.filters['gender'] != null &&
          widget.filters['gender'].toString().isNotEmpty) {
        final filterGender = _normalizeGender(widget.filters['gender'].toString());
        final communityGender = _normalizeGender(community.gender);

        if (communityGender.isNotEmpty && filterGender.isNotEmpty && filterGender != communityGender) {
          return false;
        }
      }

      // Apply online only filter
      if (widget.filters['onlineOnly'] == true && !community.isOnline) {
        return false;
      }

      // Apply country filter - with multi-language support
      if (widget.filters['country'] != null &&
          widget.filters['country'].toString().isNotEmpty) {
        final filterCountry = widget.filters['country'].toString().toLowerCase().trim();
        final userCountry = community.location.country.toLowerCase().trim();

        // Skip empty or "not specified" country values
        if (userCountry.isEmpty || userCountry == 'not specified') {
          return false;
        }

        // Normalize country names for comparison (handle different languages/formats)
        final normalizedFilterCountry = _normalizeCountry(filterCountry);
        final normalizedUserCountry = _normalizeCountry(userCountry);

        // Check for match using normalized names
        final isMatch = normalizedUserCountry == normalizedFilterCountry ||
            normalizedUserCountry.contains(normalizedFilterCountry) ||
            normalizedFilterCountry.contains(normalizedUserCountry) ||
            userCountry.contains(filterCountry) ||
            filterCountry.contains(userCountry);

        if (!isMatch) return false;
      }

      // Apply language level filter
      if (widget.filters['languageLevel'] != null &&
          widget.filters['languageLevel'].toString().isNotEmpty) {
        if (community.languageLevel?.toUpperCase() !=
            widget.filters['languageLevel'].toString().toUpperCase()) {
          return false;
        }
      }

      // Language exchange matching
      final hasNativeLanguageFilter =
          widget.filters['nativeLanguage'] != null &&
              widget.filters['nativeLanguage'].toString().isNotEmpty;

      if (hasNativeLanguageFilter) {
        final filterLang = widget.filters['nativeLanguage'].toString().toLowerCase();
        final communityLang = community.native_language.toLowerCase();
        if (filterLang != communityLang) return false;
      } else {
        // Default language exchange matching
        bool isLanguageMatch = false;
        final communityNative = community.native_language.toLowerCase();
        final communityLearning = community.language_to_learn.toLowerCase();

        if (myLanguageToLearn != null && myLanguageToLearn.isNotEmpty) {
          if (communityNative == myLanguageToLearn.toLowerCase()) {
            isLanguageMatch = true;
          }
        }
        if (!isLanguageMatch &&
            myNativeLanguage != null &&
            myNativeLanguage.isNotEmpty) {
          if (communityLearning == myNativeLanguage.toLowerCase()) {
            isLanguageMatch = true;
          }
        }
        if (!isLanguageMatch) return false;
      }

      // Apply search query
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        return community.name.toLowerCase().contains(query) ||
            community.bio.toLowerCase().contains(query) ||
            community.native_language.toLowerCase().contains(query) ||
            community.language_to_learn.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  // Send Hi message in background (fire and forget)
  Future<void> _sendHiMessage(String receiverId) async {
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(
        receiver: receiverId,
        message: 'Hi 👋',
      );
    } catch (e) {
      debugPrint('Error sending Hi message: $e');
    }
  }

  void _onWaveFromButton(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved
    _wavedUsers.add(community.id);

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

    // Send "Hi 👋" message in background
    _sendHiMessage(community.id);
  }

  void _onWaveFromSwipe(Community community) {
    HapticFeedback.mediumImpact();

    // Mark as waved
    _wavedUsers.add(community.id);

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

    // Send "Hi 👋" message in background
    _sendHiMessage(community.id);
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
    final communityState = ref.watch(paginatedCommunityProvider);
    final currentUserAsync = ref.watch(userProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

    // Show loading on initial load
    if (communityState.isLoading && communityState.users.isEmpty) {
      return _buildLoading();
    }

    // Show error if any
    if (communityState.error != null && communityState.users.isEmpty) {
      return _buildError(communityState.error);
    }

    return currentUserAsync.when(
      data: (currentUser) {
        final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
        final filteredCommunities = _getFilteredCommunities(
          communityState.users,
          currentUser.native_language,
          currentUser.language_to_learn,
          blockedUserIds,
        );

        // Check if we need to load more
        _loadMoreIfNeeded(filteredCommunities.length);

        if (filteredCommunities.isEmpty) {
          // If still loading more, show loading indicator
          if (communityState.isLoadingMore) {
            return _buildLoading();
          }
          return _buildEmptyState();
        }

        return _buildCardStack(filteredCommunities, communityState.isLoadingMore);
      },
      loading: () => _buildLoading(),
      error: (e, s) => _buildError(e),
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
                  _skippedUsers.add(currentCommunity.id);
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
                  _skippedUsers.add(currentCommunity.id);
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
                Icons.people_outline_rounded,
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
              'Try adjusting your filters or search to find language exchange partners.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () {
                ref.read(paginatedCommunityProvider.notifier).refresh();
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
  }

  Widget _buildAllDoneState() {
    final communityState = ref.watch(paginatedCommunityProvider);

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
              communityState.hasMore ? 'Loading more...' : 'All caught up!',
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              communityState.hasMore
                  ? 'Finding more language partners for you...'
                  : 'You\'ve seen all available partners. Check back later for more!',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            if (communityState.isLoadingMore)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xxl),
                child: CircularProgressIndicator(color: context.primaryColor),
              ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () {
                ref.read(paginatedCommunityProvider.notifier).refresh();
                setState(() {
                  _skippedUsers.clear();
                  _wavedUsers.clear();
                  _isProcessingSwipe = false;
                });
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
                ref.read(paginatedCommunityProvider.notifier).refresh();
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

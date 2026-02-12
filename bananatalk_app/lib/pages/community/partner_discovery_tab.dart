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

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
    });
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

      // Apply age filter
      if (widget.filters['minAge'] != null || widget.filters['maxAge'] != null) {
        final age = community.age;
        if (age != null) {
          final minAge = widget.filters['minAge'] as int?;
          final maxAge = widget.filters['maxAge'] as int?;
          if (minAge != null && age < minAge) return false;
          if (maxAge != null && age > maxAge) return false;
        }
      }

      // Apply gender filter
      if (widget.filters['gender'] != null &&
          widget.filters['gender'].toString().isNotEmpty) {
        final filterGender = widget.filters['gender'].toString().toLowerCase();
        final communityGender = community.gender.toLowerCase();
        if (filterGender != communityGender) return false;
      }

      // Apply online only filter
      if (widget.filters['onlineOnly'] == true && !community.isOnline) {
        return false;
      }

      // Apply country filter
      if (widget.filters['country'] != null &&
          widget.filters['country'].toString().isNotEmpty) {
        final filterCountry = widget.filters['country'].toString().toLowerCase();
        final userCountry = community.location.country.toLowerCase();
        if (!userCountry.contains(filterCountry) && !filterCountry.contains(userCountry)) {
          return false;
        }
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
      debugPrint('✅ Hi message sent to $receiverId');
    } catch (e) {
      debugPrint('❌ Error sending Hi message: $e');
    }
  }

  void _onWaveFromButton(Community community) {
    debugPrint('👋 Wave button pressed for: ${community.name}');
    debugPrint('📸 Image URLs: ${community.effectiveImageUrls}');
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
    debugPrint('👋 Wave swipe for: ${community.name}');
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
    final communityAsync = ref.watch(communityProvider);
    final currentUserAsync = ref.watch(userProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

    return communityAsync.when(
      data: (communities) {
        return currentUserAsync.when(
          data: (currentUser) {
            final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
            final filteredCommunities = _getFilteredCommunities(
              communities,
              currentUser.native_language,
              currentUser.language_to_learn,
              blockedUserIds,
            );

            if (filteredCommunities.isEmpty) {
              return _buildEmptyState();
            }

            return _buildCardStack(filteredCommunities);
          },
          loading: () => _buildLoading(),
          error: (e, s) => _buildError(e),
        );
      },
      loading: () => _buildLoading(),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildCardStack(List<Community> communities) {
    debugPrint('🔄 Building card stack: ${communities.length} users available');
    debugPrint('📋 Skipped: ${_skippedUsers.length}, Waved: ${_wavedUsers.length}');

    if (communities.isEmpty) {
      return _buildAllDoneState();
    }

    // Always show the first available user (list is already filtered)
    final currentCommunity = communities.first;
    final hasNextCard = communities.length > 1;

    debugPrint('👤 Current user: ${currentCommunity.name}, images: ${currentCommunity.effectiveImageUrls.length}');
    if (currentCommunity.profileImageUrl != null) {
      debugPrint('🖼️ First image URL: ${currentCommunity.profileImageUrl}');
    }

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

                debugPrint('📱 Dismissed: $direction for ${currentCommunity.name}');

                if (direction == DismissDirection.endToStart) {
                  // Swiped left - Skip
                  _skippedUsers.add(currentCommunity.id);
                  setState(() {
                    _isProcessingSwipe = false;
                  });
                  debugPrint('⏭️ Skip complete');
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
                  debugPrint('🔘 Skip button pressed');
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWave
            ? const Color(0xFF4CAF50).withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: isWave ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWave ? Icons.waving_hand_rounded : Icons.close_rounded,
            color: isWave ? const Color(0xFF4CAF50) : Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            isWave ? 'Wave' : 'Skip',
            style: TextStyle(
              color: isWave ? const Color(0xFF4CAF50) : Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No partners found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or search to find language exchange partners.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(communityProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDoneState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve seen all available partners. Check back later for more!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(communityProvider);
                setState(() {
                  _skippedUsers.clear();
                  _wavedUsers.clear();
                  _isProcessingSwipe = false;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start Over'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF00BFA5),
          ),
          SizedBox(height: 16),
          Text(
            'Finding partners...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(communityProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

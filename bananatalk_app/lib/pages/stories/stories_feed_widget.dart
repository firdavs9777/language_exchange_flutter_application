import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/story_viewer_screen.dart';
import 'package:bananatalk_app/pages/stories/create_story_screen.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Horizontal story feed widget (like Instagram stories row)
class StoriesFeedWidget extends ConsumerStatefulWidget {
  final VoidCallback? onCreateStory;
  final double height;
  final double avatarSize;

  const StoriesFeedWidget({
    Key? key,
    this.onCreateStory,
    this.height = 100,
    this.avatarSize = 64,
  }) : super(key: key);

  @override
  ConsumerState<StoriesFeedWidget> createState() => _StoriesFeedWidgetState();
}

class _StoriesFeedWidgetState extends ConsumerState<StoriesFeedWidget> {
  List<UserStories> _stories = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  UserStories? _myStories;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories({bool showLoading = true}) async {
    // Only show loading spinner on first load
    if (showLoading && !_hasLoadedOnce) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      // Load my stories
      final myStoriesResponse = await StoriesService.getMyStories();

      if (myStoriesResponse.success && myStoriesResponse.data.isNotEmpty) {
        _myStories = myStoriesResponse.data.first;
      } else {
        _myStories = null;
      }

      // Load stories feed
      final response = await StoriesService.getStoriesFeed();

      if (mounted) {
        if (response.success) {
          // Get current user ID to filter out own stories from feed (avoid duplicates)
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');

          // Get blocked user IDs
          final blockedUserIdsAsync = ref.read(blockedUserIdsProvider);
          final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

          // Filter out stories from blocked users AND current user (to avoid duplicates)
          final filteredStories = response.data.where((userStories) {
            // Filter out blocked users
            if (blockedUserIds.contains(userStories.user.id)) return false;
            // Filter out current user's stories (they're shown separately in _myStories)
            if (currentUserId != null && userStories.user.id == currentUserId) return false;
            return true;
          }).toList();

          setState(() {
            _stories = filteredStories;
            _isLoading = false;
            _isRefreshing = false;
            _hasLoadedOnce = true;
          });
        } else if (response.blocked) {
          setState(() {
            _stories = [];
            _isLoading = false;
            _isRefreshing = false;
            _hasLoadedOnce = true;
          });
        } else {
          setState(() {
            _error = response.error;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _hasLoadedOnce ? null : 'Failed to load stories: $e'; // Don't show error if we have cached data
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  /// Refresh stories silently in background
  Future<void> _refreshStoriesSilently() async {
    await _loadStories(showLoading: false);
  }

  void _openStoryViewer(int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerScreen(
            userStories: _stories,
            initialUserIndex: initialIndex,
            onStoriesUpdated: _refreshStoriesSilently,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _openMyStories() {
    if (_myStories != null && _myStories!.activeStories.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return StoryViewerScreen(
              userStories: [_myStories!],
              initialUserIndex: 0,
              isOwnStory: true,
              onStoriesUpdated: _refreshStoriesSilently,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  void _createStory() {
    if (widget.onCreateStory != null) {
      widget.onCreateStory!();
    } else {
      Navigator.push(
        context,
        AppPageRoute(
          builder: (context) => CreateStoryScreen(
            onStoryCreated: _refreshStoriesSilently,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shimmer loading state
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: 6,
          itemBuilder: (context, index) => _buildShimmerItem(),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: context.textMuted, size: 20),
              Spacing.hGapSM,
              Text(
                'Stories unavailable',
                style: context.labelSmall,
              ),
              TextButton(
                onPressed: _loadStories,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppLocalizations.of(context)!.retry, style: context.labelSmall.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    // Show stories feed (at minimum show "Your Story")
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        itemCount: _stories.length + 1, // +1 for my story / add story
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryItem();
          }
          return _buildStoryItem(_stories[index - 1], index - 1);
        },
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        width: widget.avatarSize + 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerLoading(
              child: Container(
                width: widget.avatarSize,
                height: widget.avatarSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Spacing.gapXS,
            ShimmerLoading(
              child: Container(
                width: 48,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStoryItem() {
    final hasActiveStories = _myStories?.activeStories.isNotEmpty == true;
    final imageUrl = (_myStories?.user.images.isNotEmpty == true || _myStories?.user.imageUrls.isNotEmpty == true)
        ? (_myStories!.user.images.isNotEmpty
            ? _myStories!.user.images.first
            : _myStories!.user.imageUrls.first)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (hasActiveStories) {
            _openMyStories();
          } else {
            _createStory();
          }
        },
        onLongPress: hasActiveStories ? _createStory : null,
        child: SizedBox(
          width: widget.avatarSize + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar with gradient ring if has stories
                  if (hasActiveStories)
                    StoryGradientRing(
                      size: widget.avatarSize,
                      strokeWidth: 2.5,
                      isViewed: false,
                      hasStory: true,
                      isOwnStory: true,
                      animate: false,
                      child: ClipOval(
                        child: CachedImageWidget(
                          imageUrl: imageUrl ?? '',
                          fit: BoxFit.cover,
                          placeholderColor: context.containerColor,
                          errorWidget: Container(
                            color: context.containerColor,
                            child: Icon(Icons.person, color: context.textMuted, size: 28),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: widget.avatarSize,
                      height: widget.avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: CachedImageWidget(
                            imageUrl: imageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholderColor: context.containerColor,
                            errorWidget: Container(
                              color: context.containerColor,
                              child: Icon(Icons.person, color: context.textMuted, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Add button (always visible at bottom right)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF833AB4), Color(0xFFE1306C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surfaceColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Spacing.gapXS,
              Text(
                'Your Story',
                style: context.captionSmall.copyWith(
                  color: context.textSecondary,
                  fontWeight: hasActiveStories ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(UserStories userStories, int index) {
    final hasUnseen = userStories.hasUnviewed;
    final isCloseFriend = userStories.stories.any((s) => s.privacy == StoryPrivacy.closeFriends);
    final imageUrl = (userStories.user.images.isNotEmpty || userStories.user.imageUrls.isNotEmpty)
        ? (userStories.user.images.isNotEmpty
            ? userStories.user.images.first
            : userStories.user.imageUrls.first)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openStoryViewer(index);
        },
        child: SizedBox(
          width: widget.avatarSize + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with animated gradient ring
              StoryGradientRing(
                size: widget.avatarSize,
                strokeWidth: 2.5,
                isViewed: !hasUnseen,
                isCloseFriend: isCloseFriend,
                hasStory: true,
                animate: hasUnseen,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.surfaceColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageUrl != null
                        ? CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholderColor: context.containerColor,
                            errorWidget: _buildAvatarPlaceholder(userStories.user.name),
                          )
                        : _buildAvatarPlaceholder(userStories.user.name),
                  ),
                ),
              ),
              Spacing.gapXS,
              Text(
                userStories.user.name ?? 'User',
                style: context.captionSmall.copyWith(
                  color: context.textSecondary,
                  fontWeight: hasUnseen ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String? name) {
    return Container(
      color: context.containerColor,
      alignment: Alignment.center,
      child: Text(
        name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
        style: context.titleMedium.copyWith(color: context.textSecondary),
      ),
    );
  }
}

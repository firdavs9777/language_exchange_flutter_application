import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_state.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/pages/stories/create/create_story_screen.dart';
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
  final ValueNotifier<int>? refreshNotifier;

  const StoriesFeedWidget({
    super.key,
    this.onCreateStory,
    this.height = 130,
    this.avatarSize = 64,
    this.refreshNotifier,
  });

  @override
  ConsumerState<StoriesFeedWidget> createState() => _StoriesFeedWidgetState();
}

class _StoriesFeedWidgetState extends ConsumerState<StoriesFeedWidget> with WidgetsBindingObserver {
  List<UserStories> _stories = [];
  bool _isLoading = true;
  String? _error;
  UserStories? _myStories;

  /// One load at a time. Without this, tapping Retry three times fires three
  /// requests whose responses land in an arbitrary order, and the last one to
  /// arrive wins — which can be the oldest failure.
  bool _inFlight = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshNotifier?.addListener(_onRefreshNotified);
    // Coming back online is the single most likely reason this row can
    // succeed now when it could not a moment ago, and making the user notice
    // the banner and tap it is asking them to do the phone's job.
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _loadStories();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> status) {
    final online =
        status.isNotEmpty && status.any((r) => r != ConnectivityResult.none);
    // Only when there is something to fix. A reconnect while the feed is
    // healthy should not cost a request.
    if (online && _error != null) _loadStories();
  }

  void _onRefreshNotified() {
    _loadStories(showLoading: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadStories(showLoading: false);
    }
  }

  Future<void> _loadStories({bool showLoading = true}) async {
    if (_inFlight) return;
    _inFlight = true;

    final hasCached = _stories.isNotEmpty;
    if (mounted && storiesFeedShowsShimmer(
      explicitLoad: showLoading,
      hasCachedStories: hasCached,
    )) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Load my stories
      final myStoriesResponse = await StoriesService.getMyStories();

      // Only a *successful* answer may clear this. Treating a failed call as
      // "you have no stories" made your own ring vanish from the row
      // whenever this one request flaked, which reads as the story having
      // been deleted.
      if (myStoriesResponse.success) {
        _myStories = myStoriesResponse.data.isNotEmpty
            ? myStoriesResponse.data.first
            : null;
      }

      // Load stories feed
      final response = await StoriesService.getStoriesFeed();
      if (!mounted) return;

      // `blocked` is not a failure — it is a complete answer that happens to
      // be empty, so it clears the banner like any other success.
      final ok = response.success || response.blocked;

      List<UserStories> next = _stories;
      if (response.success) {
        // Get current user ID to filter out own stories from feed (avoid duplicates)
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('userId');

        // Get blocked user IDs
        final blockedUserIdsAsync = ref.read(blockedUserIdsProvider);
        final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};

        // Filter out stories from blocked users AND current user (to avoid duplicates)
        next = response.data.where((userStories) {
          // Filter out blocked users
          if (blockedUserIds.contains(userStories.user.id)) return false;
          // Filter out current user's stories (they're shown separately in _myStories)
          if (currentUserId != null && userStories.user.id == currentUserId) return false;
          return true;
        }).toList();
      } else if (response.blocked) {
        next = const [];
      }

      if (!mounted) return;
      setState(() {
        _stories = next;
        _isLoading = false;
        _error = storiesFeedError(
          succeeded: ok,
          error: response.error,
          hasCachedStories: hasCached,
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = storiesFeedError(
            succeeded: false,
            error: 'Failed to load stories: $e',
            hasCachedStories: hasCached,
          );
        });
      }
    } finally {
      _inFlight = false;
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
    ).then((_) => _loadStories(showLoading: false));
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
      ).then((_) => _loadStories(showLoading: false));
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
      final l10n = AppLocalizations.of(context)!;
      return SizedBox(
        height: widget.height,
        // The whole row is the target. The 'Try again' label is a ~60pt strip
        // in the middle of a 130pt band, and on a failure the rest of the band
        // does nothing at all — so every near-miss tap read as a dead button.
        child: InkWell(
          key: const Key('stories-error-retry'),
          onTap: _loadStories,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: context.textMuted, size: 20),
                Spacing.hGapSM,
                Text(l10n.storiesLoadError, style: context.labelSmall),
                Spacing.hGapSM,
                Text(
                  l10n.storiesRetry,
                  style: context.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
              if (hasActiveStories)
                _buildStoryDots(
                  context,
                  _myStories!.activeStories.length,
                  _myStories!.activeStories.length - _myStories!.unviewedCount,
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
                () {
                  final userName = userStories.user.name.isNotEmpty ? userStories.user.name : 'User';
                  return userName.length > 8 ? '${userName.substring(0, 8)}...' : userName;
                }(),
                style: context.captionSmall.copyWith(color: context.textMuted),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              _buildStoryDots(
                context,
                userStories.activeStories.length,
                userStories.activeStories.length - userStories.unviewedCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryDots(BuildContext context, int totalStories, int viewedStories) {
    final dotCount = totalStories.clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(dotCount, (i) {
          final isViewed = i < viewedStories;
          return Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isViewed ? Theme.of(context).colorScheme.outline : AppColors.primary,
            ),
          );
        }),
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

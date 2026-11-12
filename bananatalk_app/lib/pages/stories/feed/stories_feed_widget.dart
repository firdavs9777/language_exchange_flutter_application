import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/stories_rail_cache.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_rail_order.dart';
import 'package:bananatalk_app/pages/stories/story_precache.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
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

  /// Seams for tests; the defaults are the real service, cache and preloader.
  final Future<StoriesFeedResult> Function()? feedLoader;
  final Future<StoriesResponse> Function()? myStoriesLoader;
  final StoriesRailCache? cache;
  final StoryPrecacher precache;

  const StoriesFeedWidget({
    super.key,
    this.onCreateStory,
    this.height = 130,
    this.avatarSize = 64,
    this.refreshNotifier,
    this.feedLoader,
    this.myStoriesLoader,
    this.cache,
    this.precache = precacheStoryImages,
  });

  @override
  ConsumerState<StoriesFeedWidget> createState() => _StoriesFeedWidgetState();
}

class _StoriesFeedWidgetState extends ConsumerState<StoriesFeedWidget> with WidgetsBindingObserver {
  /// The groups as the server sent them (unfiltered); [_entries] filters and
  /// orders them for the current flag, block list and user.
  List<UserStories> _followed = [];
  List<UserStories> _discover = [];

  /// Null until the block list has loaded. A rail painted from the cache
  /// waits for it, so a person you blocked never flashes up.
  Set<String>? _blocked;
  String? _currentUserId;

  /// Set once a fresh answer has landed, so a slow cache read cannot paint
  /// over it.
  bool _freshApplied = false;
  List<String> _lastPrecached = const [];
  late final StoriesRailCache _cache = widget.cache ?? StoriesRailCache();
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
    _loadCachedRail();
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

  bool get _discoverEnabled => ref
      .read(appConfigProvider)
      .maybeWhen(data: (c) => c?.storyDiscoverEnabled ?? false, orElse: () => false);

  List<RailEntry> _entries(bool discoverEnabled) => orderStoriesRail(
        followed: _followed,
        discover: _discover,
        discoverEnabled: discoverEnabled,
        blockedUserIds: _blocked ?? const {},
        currentUserId: _currentUserId,
      );

  /// The block list, or null when it cannot be read.
  Future<Set<String>?> _loadBlocked() async {
    try {
      return await ref.read(blockedUserIdsProvider.future);
    } catch (_) {
      return null;
    }
  }

  /// Draws the last rail at once. Skipped when it belongs to another user,
  /// is too old, or the block list cannot be read (its entries could be
  /// someone you have since blocked).
  Future<void> _loadCachedRail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final snapshot = await _cache.read(userId: userId);
      if (snapshot == null || !mounted || _freshApplied) return;
      final blocked = await _loadBlocked();
      if (blocked == null || !mounted || _freshApplied) return;
      final parsed = StoriesFeedResult.fromJson(
        {'success': true, 'data': snapshot.data, 'discover': snapshot.discover},
        userId,
      );
      setState(() {
        _followed = parsed.followed;
        _discover = parsed.discover;
        _blocked = blocked;
        _currentUserId = userId;
        _isLoading = false;
      });
      _schedulePrecache();
    } catch (e) {
      debugPrint('Stories rail cache unavailable: $e');
    }
  }

  /// Preloads the first story of the first three rings once the rail is up.
  void _schedulePrecache() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final urls = storiesRailPrecacheUrls(_entries(_discoverEnabled));
      if (urls.isEmpty || _lastPrecached.join('|') == urls.join('|')) return;
      _lastPrecached = urls;
      await widget.precache(context, urls);
    });
  }

  Future<void> _loadStories({bool showLoading = true}) async {
    if (_inFlight) return;
    _inFlight = true;

    final hasCached = _followed.isNotEmpty || _discover.isNotEmpty;
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
      final prefs = await SharedPreferences.getInstance();
      final userIdBefore = prefs.getString('userId') ?? '';

      // Load my stories
      final myStoriesResponse =
          await (widget.myStoriesLoader ?? StoriesService.getMyStories)();

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
      final response =
          await (widget.feedLoader ?? StoriesService.getStoriesFeed)();
      if (!mounted) return;

      // A rail fetched for one account must not be drawn or cached for
      // another that signed in while it was in flight.
      final userIdNow = (await SharedPreferences.getInstance()).getString('userId') ?? '';
      if (!mounted) return;
      if (userIdNow != userIdBefore) {
        setState(() => _isLoading = false);
        return;
      }

      final ok = response.success;
      if (response.success) {
        // Own stories are filtered out of the rail (they have their own
        // ring); blocked users too, once the block list is known.
        final blocked = await _loadBlocked();
        if (!mounted) return;
        _freshApplied = true;
        setState(() {
          _followed = response.followed;
          _discover = response.discover;
          _blocked = blocked ?? _blocked ?? <String>{};
          _currentUserId = userIdNow;
          _isLoading = false;
          _error = null;
        });
        _schedulePrecache();
        // An empty answer overwrites the cache too, or the next open would
        // paint rings that no longer exist.
        if (userIdNow.isNotEmpty) {
          unawaited(_cache.write(
            userId: userIdNow,
            rawData: response.rawData,
            rawDiscover: response.rawDiscover,
          ));
        }
        return;
      }

      setState(() {
        _isLoading = false;
        _error = storiesFeedError(
          succeeded: ok,
          error: response.error,
          hasCachedStories: hasCached,
        );
      });
    } catch (e) {
      // _error only switches the row to its localized retry state; the raw
      // text is for the log.
      debugPrint('Failed to load stories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = storiesFeedError(
            succeeded: false,
            error: e.toString(),
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

  void _openStoryViewer(List<RailEntry> entries, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerScreen(
            userStories: entries.map((e) => e.group).toList(),
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
    final entries = _entries(ref.watch(appConfigProvider).maybeWhen(
          data: (c) => c?.storyDiscoverEnabled ?? false,
          orElse: () => false,
        ));
    // Shimmer loading state
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: 5,
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
        itemCount: entries.length + 1, // +1 for my story / add story
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryItem();
          }
          return _buildStoryItem(entries, index - 1);
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
    final myThumb = _myStories?.user.avatarThumb;
    final imageUrl = (myThumb != null && myThumb.isNotEmpty)
        ? myThumb
        : (_myStories?.user.images.isNotEmpty == true || _myStories?.user.imageUrls.isNotEmpty == true)
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
                AppLocalizations.of(context)!.yourStory,
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

  Widget _buildStoryItem(List<RailEntry> entries, int index) {
    final entry = entries[index];
    final userStories = entry.group;
    final hasUnseen = userStories.hasUnviewed;
    final isCloseFriend = userStories.stories.any((s) => s.privacy == StoryPrivacy.closeFriends);
    final thumb = userStories.user.avatarThumb;
    final imageUrl = (thumb != null && thumb.isNotEmpty)
        ? thumb
        : (userStories.user.images.isNotEmpty || userStories.user.imageUrls.isNotEmpty)
        ? (userStories.user.images.isNotEmpty
            ? userStories.user.images.first
            : userStories.user.imageUrls.first)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openStoryViewer(entries, index);
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
                  final userName = userStories.user.name.isNotEmpty ? userStories.user.name : AppLocalizations.of(context)!.storyUserFallback;
                  return userName.length > 8 ? '${userName.substring(0, 8)}...' : userName;
                }(),
                style: context.captionSmall.copyWith(color: context.textMuted),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              // A Discover ring says so instead of showing progress dots (the
              // rail is one line short of room for both).
              if (entry.isDiscover)
                Text(
                  AppLocalizations.of(context)!.storiesDiscoverLabel,
                  key: const Key('stories-discover-label'),
                  style: context.captionSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              else
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

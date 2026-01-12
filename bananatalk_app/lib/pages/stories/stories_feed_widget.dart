import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/story_viewer_screen.dart';
import 'package:bananatalk_app/pages/stories/create_story_screen.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      print('📚 Loading my stories...');
      final myStoriesResponse = await StoriesService.getMyStories();
      print('📚 My stories response: success=${myStoriesResponse.success}, count=${myStoriesResponse.count}, data.length=${myStoriesResponse.data.length}');
      
      if (myStoriesResponse.success && myStoriesResponse.data.isNotEmpty) {
        _myStories = myStoriesResponse.data.first;
        print('📚 My stories loaded: ${_myStories?.stories.length} stories, active=${_myStories?.activeStories.length}');
      } else {
        print('📚 No my stories found: ${myStoriesResponse.error ?? myStoriesResponse.message}');
        _myStories = null;
      }

      // Load stories feed
      print('📚 Loading stories feed...');
      final response = await StoriesService.getStoriesFeed();
      print('📚 Feed response: success=${response.success}, count=${response.count}, data.length=${response.data.length}');

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
          print('📚 Stories feed loaded: ${_stories.length} users with stories (filtered from ${response.data.length}, removed own stories)');
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
          print('📚 Stories feed error: ${response.error}');
        }
      }
    } catch (e) {
      print('📚 Exception loading stories: $e');
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
        MaterialPageRoute(
          builder: (context) => CreateStoryScreen(
            onStoryCreated: _refreshStoriesSilently,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show at least the "Your Story" button
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
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
              Icon(Icons.error_outline, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'Stories unavailable',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              TextButton(
                onPressed: _loadStories,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppLocalizations.of(context)!.retry, style: const TextStyle(fontSize: 12)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

  Widget _buildMyStoryItem() {
    final hasActiveStories = _myStories?.activeStories.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: hasActiveStories ? _openMyStories : _createStory,
        child: SizedBox(
          width: widget.avatarSize + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: widget.avatarSize,
                    height: widget.avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasActiveStories
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: CachedCircleAvatar(
                        imageUrl: (_myStories?.user.images.isNotEmpty == true || _myStories?.user.imageUrls.isNotEmpty == true)
                            ? (_myStories!.user.images.isNotEmpty 
                                ? _myStories!.user.images.first 
                                : _myStories!.user.imageUrls.first)
                            : null,
                        backgroundColor: Colors.grey[200],
                        errorWidget: Icon(Icons.person, color: Colors.grey[400], size: 28),
                      ),
                    ),
                  ),
                  if (!hasActiveStories)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your Story',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _openStoryViewer(index),
        child: SizedBox(
          width: widget.avatarSize + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: widget.avatarSize,
                height: widget.avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasUnseen
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFF77737),
                            Color(0xFFE1306C),
                            Color(0xFFC13584),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: hasUnseen
                      ? null
                      : Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CachedCircleAvatar(
                      imageUrl: (userStories.user.images.isNotEmpty || userStories.user.imageUrls.isNotEmpty)
                          ? (userStories.user.images.isNotEmpty
                              ? userStories.user.images.first
                              : userStories.user.imageUrls.first)
                          : null,
                      backgroundColor: Colors.grey[200],
                      errorWidget: Text(
                        userStories.user.name?.isNotEmpty == true
                            ? userStories.user.name![0].toUpperCase()
                            : '?',
                        style: TextStyle(color: Colors.grey[600], fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userStories.user.name ?? 'User',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
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
}


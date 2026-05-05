import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/blocked_content_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/story/story_progress_bar.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/pages/stories/create_story_screen.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:bananatalk_app/utils/app_page_route.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<UserStories> userStories;
  final int initialUserIndex;
  final bool isOwnStory;
  final VoidCallback? onStoriesUpdated;

  const StoryViewerScreen({
    Key? key,
    required this.userStories,
    this.initialUserIndex = 0,
    this.isOwnStory = false,
    this.onStoriesUpdated,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _userPageController;
  late int _currentUserIndex;
  int _currentStoryIndex = 0;
  bool _isPaused = false;
  Timer? _timer;

  late AnimationController _progressController;
  final Duration _storyDuration = const Duration(seconds: 5);

  bool _showReplyField = false;
  final TextEditingController _replyController = TextEditingController();

  // Blocked state
  bool _isBlocked = false;

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Swipe to dismiss
  double _dragOffset = 0;
  bool _isDragging = false;

  // Cube transition
  double _cubeOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _cubeOffset = widget.initialUserIndex.toDouble();
    _userPageController = PageController(initialPage: widget.initialUserIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    // Set immersive mode for story viewing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializeCurrentStory();
    _markAsViewed();
  }

  Future<void> _initializeCurrentStory() async {
    final story = _currentStory;
    if (story == null) return;

    // Dispose previous video controller if any
    await _disposeVideoController();

    if (story.isVideo) {
      await _initializeVideoPlayer(story);
    } else {
      _startStoryTimer();
    }
  }

  Future<void> _initializeVideoPlayer(Story story) async {
    final videoUrl = ImageUtils.normalizeImageUrl(story.mediaUrl);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Set video duration for progress
        final videoDuration = _videoController!.value.duration;
        _progressController.duration = videoDuration;

        await _videoController!.play();
        _progressController.forward();

        // Listen for video end
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      // Fall back to default timer if video fails
      _startStoryTimer();
    }
  }

  void _videoListener() {
    if (_videoController == null) return;

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (duration.inMilliseconds > 0) {
      final progress = position.inMilliseconds / duration.inMilliseconds;
      _progressController.value = progress.clamp(0.0, 1.0);
    }
  }

  Future<void> _disposeVideoController() async {
    _videoController?.removeListener(_videoListener);
    await _videoController?.dispose();
    _videoController = null;
    setState(() {
      _isVideoInitialized = false;
    });
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _progressController.dispose();
    _userPageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  List<Story> get _currentStories =>
      widget.userStories[_currentUserIndex].activeStories;

  Story? get _currentStory =>
      _currentStories.isNotEmpty && _currentStoryIndex < _currentStories.length
          ? _currentStories[_currentStoryIndex]
          : null;

  UserStories get _currentUser => widget.userStories[_currentUserIndex];

  void _startStoryTimer() {
    _progressController.reset();
    _progressController.forward();
  }

  void _pauseStory() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
      _videoController?.pause();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
      _videoController?.play();
    }
  }

  Future<void> _markAsViewed() async {
    final story = _currentStory;
    if (story != null && !widget.isOwnStory) {
      await StoriesService.viewStory(storyId: story.id);
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _markAsViewed();
      _initializeCurrentStory();
    } else {
      // Move to next user's stories
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _initializeCurrentStory();
    } else {
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.userStories.length - 1) {
      // Reset story index for next user
      setState(() {
        _currentStoryIndex = 0;
      });
      _userPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // All stories viewed, close viewer
      // Defer pop to avoid calling during animation callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      // Reset story index for previous user
      setState(() {
        _currentStoryIndex = 0;
      });
      _userPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onUserPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    _markAsViewed();
    _initializeCurrentStory();
  }

  Future<void> _sendReaction(String emoji) async {
    final story = _currentStory;
    if (story == null) return;

    final result = await StoriesService.reactToStory(
      storyId: story.id,
      emoji: emoji,
    );

    if (mounted) {
      if (result['blocked'] == true) {
        setState(() => _isBlocked = true);
        BlockedContentSnackbar.show(context, message: "You can't react to this story");
      } else if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.sent(emoji))),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    final story = _currentStory;
    final message = _replyController.text.trim();
    
    if (story == null || message.isEmpty) return;

    final result = await StoriesService.replyToStory(
      storyId: story.id,
      message: message,
    );

    if (mounted) {
      if (result['blocked'] == true) {
        setState(() => _isBlocked = true);
        BlockedContentSnackbar.show(context, message: "You can't reply to this story");
      } else if (result['success'] == true) {
        _replyController.clear();
        setState(() => _showReplyField = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.replySent)),
        );
      }
      _resumeStory();
    }
  }

  Future<void> _deleteStory() async {
    final story = _currentStory;
    if (story == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteStory),
        content: Text(AppLocalizations.of(context)!.thisStoryWillBeRemovedPermanently),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await StoriesService.deleteStory(storyId: story.id);
      
      if (mounted) {
        if (result['success'] == true) {
          widget.onStoriesUpdated?.call();
          if (_currentStories.length <= 1) {
            Navigator.pop(context);
          } else {
            _nextStory();
          }
        }
      }
    }
  }

  Future<void> _reportStory() async {
    final story = _currentStory;
    if (story == null) return;

    _pauseStory();

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => ReportDialog(
          type: 'story',
          reportedId: story.id,
          reportedUserId: story.user.id,
        ),
      );

      _resumeStory();
    }
  }

  void _shareStory() {
    final story = _currentStory;
    if (story == null) return;

    final userName = _currentUser.user.name ?? 'User';
    final storyText = story.text?.isNotEmpty == true ? '\n"${story.text}"' : '';
    final shareText = 'Check out $userName\'s story on Bananatalk!$storyText\n\nhttps://bananatalk.com/story/${story.id}';

    Share.share(shareText);
  }

  void _addMoreToStory() async {
    _pauseStory();

    await Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => CreateStoryScreen(
          onStoryCreated: () {
            widget.onStoriesUpdated?.call();
          },
        ),
      ),
    );

    _resumeStory();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: BlockedContentWidget.stories(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
        onTapDown: (details) => _pauseStory(),
        onTapUp: (details) {
          _resumeStory();
          final screenWidth = MediaQuery.of(context).size.width;
          // Tap left 30% for previous, right 70% for next
          if (details.globalPosition.dx < screenWidth * 0.3) {
            HapticFeedback.selectionClick();
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 0.3) {
            HapticFeedback.selectionClick();
            _nextStory();
          }
        },
        onTapCancel: () => _resumeStory(),
        onLongPressStart: (_) {
          HapticFeedback.mediumImpact();
          _pauseStory();
        },
        onLongPressEnd: (_) => _resumeStory(),
        // Swipe down to close
        onVerticalDragStart: (_) {
          _isDragging = true;
          _pauseStory();
        },
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0) {
            setState(() {
              _dragOffset += details.delta.dy;
            });
          }
        },
        onVerticalDragEnd: (details) {
          _isDragging = false;
          if (_dragOffset > 100 || (details.velocity.pixelsPerSecond.dy > 500)) {
            // Close the viewer
            Navigator.pop(context);
          } else {
            // Snap back
            setState(() {
              _dragOffset = 0;
            });
            _resumeStory();
          }
        },
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _dragOffset)
            ..scale(1 - (_dragOffset / 1000).clamp(0.0, 0.2)),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: 1 - (_dragOffset / 400).clamp(0.0, 0.5),
            child: _buildCubePageView(),
          ),
        ),
      ),
          // Seen-by bar for own stories — outside GestureDetector so taps work
          if (widget.isOwnStory && _currentStory != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                                    _showViewersList(_currentStory!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Seen by ${_currentStory!.viewCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCubePageView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _cubeOffset = _userPageController.page ?? _currentUserIndex.toDouble();
          });
        }
        return false;
      },
      child: PageView.builder(
        controller: _userPageController,
        onPageChanged: _onUserPageChanged,
        itemCount: widget.userStories.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, userIndex) {
          // Calculate cube rotation
          final diff = userIndex - _cubeOffset;
          final rotationY = diff * -0.4; // Rotation angle
          final isOnRight = diff > 0;

          return Transform(
            alignment: isOnRight ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(rotationY),
            child: _buildStoryView(),
          );
        },
      ),
    );
  }

  Widget _buildStoryView() {
    final story = _currentStory;
    
    if (story == null) {
      return const Center(
        child: Text('No stories', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Story image/video
        story.isVideo
            ? _buildVideoPlayer(story)
            : CachedImageWidget(
                imageUrl: story.mediaUrl,
                fit: BoxFit.contain,
                errorWidget: Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                  ),
                ),
              ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Progress bars - enhanced with StoryProgressBar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return StoryProgressBar(
                totalSegments: _currentStories.length,
                currentSegment: _currentStoryIndex,
                currentProgress: _progressController.value,
                height: 2.5,
                spacing: 4,
              );
            },
          ),
        ),

        // User info header
        Positioned(
          top: MediaQuery.of(context).padding.top + 18,
          left: 12,
          right: 12,
          child: Row(
            children: [
              // Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: story.privacy == StoryPrivacy.closeFriends
                      ? const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                        )
                      : null,
                ),
                child: CachedCircleAvatar(
                  imageUrl: (_currentUser.user.images.isNotEmpty || _currentUser.user.imageUrls.isNotEmpty)
                      ? (_currentUser.user.images.isNotEmpty
                          ? _currentUser.user.images.first
                          : _currentUser.user.imageUrls.first)
                      : null,
                  radius: 18,
                  errorWidget: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentUser.user.name?.isNotEmpty == true
                          ? _currentUser.user.name![0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _currentUser.user.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (story.privacy == StoryPrivacy.closeFriends) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Close Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(story.createdAt),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button (always visible)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              // Menu button (for own stories: delete, for others: report)
              if (widget.isOwnStory)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    _pauseStory();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.visibility, color: Theme.of(context).iconTheme.color),
                              title: Text(AppLocalizations.of(context)!.views('${story.viewCount}'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
                              title: Text(AppLocalizations.of(context)!.share, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () {
                                Navigator.pop(context);
                                _shareStory();
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.add_circle_outline, color: Theme.of(context).iconTheme.color),
                              title: Text('Add more to story', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () {
                                Navigator.pop(context);
                                _addMoreToStory();
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.bookmark_add_outlined, color: Theme.of(context).iconTheme.color),
                              title: Text('Save to Highlight', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () {
                                Navigator.pop(context);
                                _saveToHighlight(story);
                              },
                            ),
                            const Divider(color: Colors.grey, height: 1),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteStory();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ).then((_) => _resumeStory());
                  },
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportStory();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.reportStory, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Text overlay
        if (story.text != null && story.text!.isNotEmpty)
          Positioned(
            bottom: _showReplyField ? 80 : 120,
            left: 16,
            right: 16,
            child: Text(
              story.text!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.black),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Reply / Reactions
        if (!widget.isOwnStory)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: _showReplyField
                ? _buildReplyField()
                : _buildReactionBar(),
          ),

        // Seen by bar is now rendered at top-level Stack (outside GestureDetector)
      ],
    );
  }

  Widget _buildSeenByBar(Story story) {
    final viewCount = story.viewCount;
    return GestureDetector(
      onTap: () => _showViewersList(story),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Seen by $viewCount',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _saveToHighlight(Story story) async {
    _pauseStory();

    // Check if story is already in a highlight
    if (story.highlightId != null && story.highlightId!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already saved to a highlight'),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) _resumeStory();
      return;
    }

    // Fetch existing highlights to show options
    final highlightsResponse = await StoriesService.getMyHighlights();
    final existingHighlights = highlightsResponse.success ? highlightsResponse.data : <StoryHighlight>[];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Save to Highlight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              // Existing highlights
              if (existingHighlights.isNotEmpty) ...[
                ...existingHighlights.map((h) {
                  // Check if story already in this highlight
                  final alreadyIn = h.stories.any((s) => s.id == story.id);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: h.coverImage != null && h.coverImage!.isNotEmpty
                          ? NetworkImage(h.coverImage!)
                          : null,
                      child: h.coverImage == null || h.coverImage!.isEmpty
                          ? const Icon(Icons.auto_stories, size: 20)
                          : null,
                    ),
                    title: Text(h.title),
                    subtitle: Text('${h.storyCount} stories'),
                    trailing: alreadyIn
                        ? const Icon(Icons.check_circle, color: Color(0xFF00BFA5))
                        : null,
                    onTap: alreadyIn ? null : () async {
                      Navigator.pop(ctx);
                      try {
                        await StoriesService.addToHighlight(highlightId: h.id, storyId: story.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to "${h.title}"'),
                              backgroundColor: const Color(0xFF00BFA5),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  );
                }),
                const Divider(height: 1),
              ],
              // Create new highlight
              ListTile(
                leading: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF00BFA5),
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: const Text('Create New Highlight'),
                onTap: () async {
                  Navigator.pop(ctx);
                  _createNewHighlight(story);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) _resumeStory();
    });
  }

  void _createNewHighlight(Story story) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Highlight'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Highlight name...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) Navigator.pop(ctx, title);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        await StoriesService.createHighlight(title: result, storyId: story.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created highlight "$result"'),
              backgroundColor: const Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showViewersList(Story story) {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Seen by ${story.viewCount}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: StoriesService.getStoryViewers(storyId: story.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.data == null || snapshot.data!['success'] != true) {
                      debugPrint('👁️ Viewers response: ${snapshot.data}');
                      return const Center(child: Text('Failed to load viewers'));
                    }
                    // Service returns 'views' key with List<StoryView>
                    final viewsList = snapshot.data!['views'] as List? ?? [];
                    if (viewsList.isEmpty) {
                      return const Center(child: Text('No views yet'));
                    }
                    return ListView.builder(
                      itemCount: viewsList.length,
                      itemBuilder: (context, index) {
                        final view = viewsList[index];
                        // view is a StoryView object
                        String userName = 'User';
                        String? userImage;
                        String userId = '';
                        DateTime viewedAt = DateTime.now();
                        Community? userCommunity;
                        if (view is StoryView) {
                          userName = view.user?.name ?? 'User';
                          userImage = view.user?.imageUrls.isNotEmpty == true
                              ? view.user!.imageUrls.first
                              : (view.user?.images.isNotEmpty == true ? view.user!.images.first : null);
                          userId = view.userId;
                          viewedAt = view.viewedAt;
                          userCommunity = view.user;
                        }
                        return ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            if (userCommunity != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SingleCommunity(community: userCommunity!),
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: userImage != null && userImage.isNotEmpty
                                ? NetworkImage(userImage)
                                : null,
                            child: userImage == null || userImage.isEmpty
                                ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Text(userName),
                          trailing: Text(
                            _formatTime(viewedAt),
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) _resumeStory();
    });
  }

  Widget _buildReactionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _pauseStory();
                setState(() => _showReplyField = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white60, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reply to story...',
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ..._buildQuickReactions(),
        ],
      ),
    );
  }

  List<Widget> _buildQuickReactions() {
    const reactions = ['❤️', '🔥', '😂', '😢', '😮', '👏'];
    return reactions.map((emoji) => _buildQuickReaction(emoji)).toList();
  }

  Widget _buildQuickReaction(String emoji) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _sendReaction(emoji);
        // Show brief animation feedback
        _showReactionAnimation(emoji);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  void _showReactionAnimation(String emoji) {
    // Show a brief overlay animation for the reaction
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Sent!', style: TextStyle(color: Colors.white)),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 100, left: 80, right: 80),
      ),
    );
  }

  Widget _buildReplyField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _replyController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.reply2,
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _sendReply(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _sendReply,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () {
            setState(() => _showReplyField = false);
            _resumeStory();
          },
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(Story story) {
    if (_isVideoInitialized && _videoController != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    // Show thumbnail or loading indicator while video loads
    return Stack(
      fit: StackFit.expand,
      children: [
        if (story.videoMetadata?.thumbnail != null)
          CachedImageWidget(
            imageUrl: story.videoMetadata!.thumbnail!,
            fit: BoxFit.contain,
          )
        else
          Container(color: Colors.black),
        const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}


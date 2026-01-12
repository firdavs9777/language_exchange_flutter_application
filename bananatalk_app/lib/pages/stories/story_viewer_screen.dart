import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/blocked_content_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/pages/stories/create_story_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
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
      debugPrint('Error initializing video: $e');
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
      Navigator.pop(context);
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
    final shareText = 'Check out $userName\'s story on BananaTalk!$storyText\n\nhttps://bananatalk.com/story/${story.id}';

    Share.share(shareText);
  }

  void _addMoreToStory() async {
    _pauseStory();

    await Navigator.push(
      context,
      MaterialPageRoute(
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
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: PageView.builder(
          controller: _userPageController,
          onPageChanged: _onUserPageChanged,
          itemCount: widget.userStories.length,
          itemBuilder: (context, userIndex) {
            return _buildStoryView();
          },
        ),
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

        // Progress bars
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          child: Row(
            children: List.generate(_currentStories.length, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 2,
                  child: index == _currentStoryIndex
                      ? AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            );
                          },
                        )
                      : Container(
                          color: index < _currentStoryIndex
                              ? Colors.white
                              : Colors.white30,
                        ),
                ),
              );
            }),
          ),
        ),

        // User info header
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 8,
          right: 8,
          child: Row(
            children: [
              CachedCircleAvatar(
                imageUrl: (_currentUser.user.images.isNotEmpty || _currentUser.user.imageUrls.isNotEmpty)
                    ? (_currentUser.user.images.isNotEmpty
                        ? _currentUser.user.images.first
                        : _currentUser.user.imageUrls.first)
                    : null,
                radius: 16,
                errorWidget: (_currentUser.user.images.isEmpty && _currentUser.user.imageUrls.isEmpty)
                    ? Text(
                        _currentUser.user.name?.isNotEmpty == true
                            ? _currentUser.user.name![0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.user.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTime(story.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
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
                      backgroundColor: Colors.grey[900],
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
                              leading: const Icon(Icons.visibility, color: Colors.white70),
                              title: Text(AppLocalizations.of(context)!.views('${story.viewCount}'), style: const TextStyle(color: Colors.white)),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.share, color: Colors.white70),
                              title: Text(AppLocalizations.of(context)!.share, style: const TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                _shareStory();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Colors.white70),
                              title: const Text('Add more to story', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                _addMoreToStory();
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
      ],
    );
  }

  Widget _buildReactionBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _pauseStory();
              setState(() => _showReplyField = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Reply to story...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildQuickReaction('❤️'),
        _buildQuickReaction('😂'),
        _buildQuickReaction('😮'),
        _buildQuickReaction('🔥'),
      ],
    );
  }

  Widget _buildQuickReaction(String emoji) {
    return GestureDetector(
      onTap: () => _sendReaction(emoji),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
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


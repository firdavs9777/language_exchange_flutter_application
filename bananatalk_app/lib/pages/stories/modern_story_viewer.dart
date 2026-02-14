import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Modern Instagram/TikTok-like story viewer with cube transitions and smooth animations
class ModernStoryViewer extends StatefulWidget {
  final List<UserStories> userStories;
  final int initialUserIndex;
  final int initialStoryIndex;
  final bool isOwnStory;
  final VoidCallback? onStoriesUpdated;

  const ModernStoryViewer({
    Key? key,
    required this.userStories,
    this.initialUserIndex = 0,
    this.initialStoryIndex = 0,
    this.isOwnStory = false,
    this.onStoriesUpdated,
  }) : super(key: key);

  @override
  State<ModernStoryViewer> createState() => _ModernStoryViewerState();
}

class _ModernStoryViewerState extends State<ModernStoryViewer>
    with TickerProviderStateMixin {
  late PageController _userPageController;
  late int _currentUserIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  late AnimationController _reactionController;

  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isVideoLoading = false;
  String? _showingReaction;
  double _dragOffset = 0;
  bool _isDragging = false;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _isReplying = false;

  // Gesture tracking
  Offset? _dragStart;
  double _swipeProgress = 0;

  static const Duration _imageDuration = Duration(seconds: 5);
  static const Duration _videoDuration = Duration(seconds: 30);

  List<UserStories> get _userStories => widget.userStories;
  UserStories get _currentUserStories => _userStories[_currentUserIndex];
  List<Story> get _stories => _currentUserStories.activeStories;
  Story get _currentStory => _stories[_currentStoryIndex];
  bool get _isOwnStory => widget.isOwnStory;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex.clamp(0, _userStories.length - 1);
    _currentStoryIndex = widget.initialStoryIndex.clamp(0, _stories.length - 1);

    _userPageController = PageController(
      initialPage: _currentUserIndex,
      viewportFraction: 1.0,
    );

    _progressController = AnimationController(vsync: this)
      ..addStatusListener(_onProgressComplete);

    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _replyFocusNode.addListener(_onReplyFocusChange);

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializeStory();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progressController.dispose();
    _reactionController.dispose();
    _userPageController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _onReplyFocusChange() {
    setState(() => _isReplying = _replyFocusNode.hasFocus);
    if (_replyFocusNode.hasFocus) {
      _pauseStory();
    } else {
      _resumeStory();
    }
  }

  void _initializeStory() {
    final story = _currentStory;
    _videoController?.dispose();
    _videoController = null;

    if (story.isVideo) {
      _loadVideo(story);
    } else {
      _progressController.duration = _imageDuration;
      _startProgress();
    }

    _markAsViewed();
  }

  Future<void> _loadVideo(Story story) async {
    setState(() => _isVideoLoading = true);

    final mediaUrl = story.mediaUrl.isNotEmpty
        ? story.mediaUrl
        : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : '');

    if (mediaUrl.isEmpty) {
      setState(() => _isVideoLoading = false);
      _progressController.duration = _imageDuration;
      _startProgress();
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            final duration = _videoController!.value.duration;
            _progressController.duration = duration.inSeconds > 0
                ? duration
                : _videoDuration;

            _videoController!.setLooping(false);
            _videoController!.play();
            setState(() => _isVideoLoading = false);
            _startProgress();
          }
        });
    } catch (e) {
      debugPrint('Error loading video: $e');
      setState(() => _isVideoLoading = false);
      _progressController.duration = _imageDuration;
      _startProgress();
    }
  }

  void _startProgress() {
    if (!_isPaused) {
      _progressController.forward(from: _progressController.value);
    }
  }

  void _pauseStory() {
    _progressController.stop();
    _videoController?.pause();
    setState(() => _isPaused = true);
  }

  void _resumeStory() {
    if (!_isReplying) {
      _progressController.forward();
      _videoController?.play();
      setState(() => _isPaused = false);
    }
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _progressController.reset();
      _initializeStory();
    } else if (_currentUserIndex < _userStories.length - 1) {
      _goToNextUser();
    } else {
      _close();
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _progressController.reset();
      _initializeStory();
    } else if (_currentUserIndex > 0) {
      _goToPreviousUser();
    }
  }

  void _goToNextUser() {
    _userPageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousUser() {
    _userPageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onUserPageChanged(int index) {
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });

    _progressController.reset();
    _initializeStory();
  }

  Future<void> _markAsViewed() async {
    if (!_isOwnStory) {
      await StoriesService.viewStory(storyId: _currentStory.id);
    }
  }

  void _close() {
    widget.onStoriesUpdated?.call();
    Navigator.of(context).pop();
  }

  void _onTapDown(TapDownDetails details) {
    _pauseStory();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isReplying) return;

    _resumeStory();
    final screenWidth = MediaQuery.of(context).size.width;
    final x = details.globalPosition.dx;

    if (x < screenWidth * 0.3) {
      _goToPreviousStory();
    } else if (x > screenWidth * 0.7) {
      _goToNextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _pauseStory();
    HapticFeedback.mediumImpact();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _resumeStory();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
    _pauseStory();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;

    final delta = details.globalPosition.dy - _dragStart!.dy;
    setState(() {
      _dragOffset = delta.clamp(-100, 300);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset > 100 || velocity > 800) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
      _resumeStory();
    }

    _dragStart = null;
  }

  Future<void> _react(String emoji) async {
    setState(() => _showingReaction = emoji);
    HapticFeedback.lightImpact();
    _reactionController.forward(from: 0);

    await StoriesService.reactToStory(storyId: _currentStory.id, emoji: emoji);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showingReaction = null);
    });
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final message = _replyController.text.trim();
    _replyController.clear();
    _replyFocusNode.unfocus();

    await StoriesService.replyToStory(
      storyId: _currentStory.id,
      message: message,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.replySent),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _dragOffset)
            ..scale(1 - (_dragOffset.abs() / 1000)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_dragOffset > 0 ? 24 : 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Story content with cube transition
                _buildCubePageView(),

                // Progress bars
                _buildProgressBars(),

                // Header
                _buildHeader(),

                // Interactive elements (polls, questions, etc.)
                _buildInteractiveElements(),

                // Reaction animation
                if (_showingReaction != null)
                  _buildReactionAnimation(),

                // Reply input or viewers button
                if (!_isOwnStory)
                  _buildReplySection()
                else
                  _buildViewersSection(),

                // Loading overlay for video
                if (_isVideoLoading)
                  _buildLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCubePageView() {
    return PageView.builder(
      controller: _userPageController,
      onPageChanged: _onUserPageChanged,
      itemCount: _userStories.length,
      itemBuilder: (context, userIndex) {
        return AnimatedBuilder(
          animation: _userPageController,
          builder: (context, child) {
            double value = 0;
            if (_userPageController.position.haveDimensions) {
              value = _userPageController.page! - userIndex;
              value = (value * 0.8).clamp(-1, 1);
            }

            return Transform(
              alignment: value > 0 ? Alignment.centerLeft : Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value * math.pi / 6),
              child: _buildStoryContent(userIndex),
            );
          },
        );
      },
    );
  }

  Widget _buildStoryContent(int userIndex) {
    if (userIndex != _currentUserIndex) {
      final userStories = _userStories[userIndex];
      final story = userStories.activeStories.isNotEmpty
          ? userStories.activeStories.first
          : null;

      if (story == null) return const SizedBox();

      final mediaUrl = story.mediaUrl.isNotEmpty
          ? story.mediaUrl
          : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : '');

      return CachedNetworkImage(
        imageUrl: story.isVideo ? (story.thumbnail ?? mediaUrl) : mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[900]),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
          ),
        ),
      );
    }

    final story = _currentStory;

    // Text story
    if (story.mediaType == 'text') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(story.backgroundColor.replaceFirst('#', '0xFF'))),
              Color(int.parse(story.backgroundColor.replaceFirst('#', '0xFF')))
                  .withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Text(
          story.text ?? '',
          style: TextStyle(
            color: Color(int.parse(story.textColor.replaceFirst('#', '0xFF'))),
            fontSize: 28,
            fontWeight: story.fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontStyle: story.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Video story
    if (story.isVideo && _videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Play/Pause indicator
          if (_isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
        ],
      );
    }

    // Image story
    final mediaUrl = story.mediaUrl.isNotEmpty
        ? story.mediaUrl
        : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : '');

    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      right: 12,
      child: Row(
        children: List.generate(_stories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  double progress;
                  if (index < _currentStoryIndex) {
                    progress = 1.0;
                  } else if (index > _currentStoryIndex) {
                    progress = 0.0;
                  } else {
                    progress = _progressController.value;
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final user = _currentUserStories.user;
    final story = _currentStory;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 24,
      left: 12,
      right: 12,
      child: Row(
        children: [
          // User avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[800],
                backgroundImage: (user.images.isNotEmpty || user.imageUrls.isNotEmpty)
                    ? CachedNetworkImageProvider(
                        user.images.isNotEmpty
                            ? user.images.first
                            : user.imageUrls.first,
                      )
                    : null,
                child: (user.images.isEmpty && user.imageUrls.isEmpty)
                    ? Text(
                        user.name?.isNotEmpty == true
                            ? user.name![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      user.name ?? 'User',
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
                          color: const Color(0xFF00A86B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              AppLocalizations.of(context)!.closeFriends,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(story.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (!_isOwnStory && story.allowSharing)
            IconButton(
              icon: const Icon(Icons.send_outlined),
              color: Colors.white,
              iconSize: 22,
              onPressed: () => _showShareSheet(),
            ),

          IconButton(
            icon: const Icon(Icons.more_horiz),
            color: Colors.white,
            iconSize: 24,
            onPressed: () => _showOptionsSheet(),
          ),

          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            iconSize: 26,
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveElements() {
    final story = _currentStory;

    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Poll
          if (story.poll != null)
            _buildPollWidget(story.poll!),

          // Question box
          if (story.questionBox != null)
            _buildQuestionWidget(story.questionBox!),

          // Location sticker
          if (story.location != null)
            _buildLocationSticker(story.location!),

          // Link sticker
          if (story.link != null)
            _buildLinkSticker(story.link!),

          // Music sticker
          if (story.music != null)
            _buildMusicSticker(story.music!),
        ],
      ),
    );
  }

  Widget _buildPollWidget(StoryPoll poll) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...poll.options.map((option) => _buildPollOption(option, poll)),
        ],
      ),
    );
  }

  Widget _buildPollOption(StoryPollOption option, StoryPoll poll) {
    final hasVoted = poll.hasUserVoted;
    final isSelected = poll.userVoteIndex == option.index;

    return GestureDetector(
      onTap: hasVoted ? null : () => _votePoll(option.index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            if (hasVoted)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 48,
                width: (MediaQuery.of(context).size.width - 88) * (option.percentage / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [Colors.grey[400]!, Colors.grey[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        color: hasVoted && isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasVoted)
                    Text(
                      '${option.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _votePoll(int optionIndex) async {
    HapticFeedback.lightImpact();
    await StoriesService.votePoll(
      storyId: _currentStory.id,
      optionIndex: optionIndex,
    );
    // Refresh would happen through state management
  }

  Widget _buildQuestionWidget(StoryQuestionBox questionBox) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            questionBox.prompt,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.sendMeAMessage,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (text) => _answerQuestion(text),
          ),
        ],
      ),
    );
  }

  Future<void> _answerQuestion(String text) async {
    if (text.trim().isEmpty) return;

    await StoriesService.answerQuestion(
      storyId: _currentStory.id,
      text: text.trim(),
      isAnonymous: false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.answerSent)),
      );
    }
  }

  Widget _buildLocationSticker(StoryLocation location) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 6),
          Text(
            location.name,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSticker(StoryLink link) {
    return GestureDetector(
      onTap: () => _openLink(link.url),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF405DE6), Color(0xFF5851DB), Color(0xFF833AB4)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5851DB).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              link.displayText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  void _openLink(String url) {
    // Use url_launcher to open the link
    debugPrint('Opening link: $url');
  }

  Widget _buildMusicSticker(StoryMusic music) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note, color: Colors.black, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                music.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                music.artist,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _reactionController,
        builder: (context, child) {
          final scale = Curves.elasticOut.transform(_reactionController.value);
          final opacity = 1 - Curves.easeOut.transform(
            (_reactionController.value - 0.5).clamp(0, 1) * 2,
          );

          return Transform.scale(
            scale: 0.5 + scale,
            child: Opacity(
              opacity: opacity.clamp(0, 1),
              child: Text(
                _showingReaction!,
                style: const TextStyle(fontSize: 120),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplySection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            if (!_isReplying && _currentStory.allowReplies)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: StoryReactionEmojis.all.take(6).map((emoji) {
                    return GestureDetector(
                      onTap: () => _react(emoji),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Reply input
            if (_currentStory.allowReplies)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _replyController,
                        focusNode: _replyFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.replyTo(_currentUserStories.user.name ?? ''),
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                  ),
                  if (_isReplying) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendReply,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersSection() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => _showViewersSheet(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  '${_currentStory.viewCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
              ],
            ),
            if (_currentStory.reactionCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...(_currentStory.reactions.take(5).map((r) => Text(r.emoji))),
                  if (_currentStory.reactionCount > 5)
                    Text(
                      ' +${_currentStory.reactionCount - 5}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  void _showShareSheet() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ShareSheet(storyId: _currentStory.id),
    ).then((_) => _resumeStory());
  }

  void _showOptionsSheet() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OptionsSheet(
        isOwnStory: _isOwnStory,
        onDelete: () async {
          Navigator.pop(context);
          await StoriesService.deleteStory(storyId: _currentStory.id);
          if (_stories.length == 1) {
            _close();
          } else {
            _goToNextStory();
          }
        },
      ),
    ).then((_) => _resumeStory());
  }

  void _showViewersSheet() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => _ViewersSheet(
          storyId: _currentStory.id,
          scrollController: scrollController,
        ),
      ),
    ).then((_) => _resumeStory());
  }
}

// Helper sheets
class _ShareSheet extends StatelessWidget {
  final String storyId;

  const _ShareSheet({required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.shareStory,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.blue),
          ),
          title: Text(AppLocalizations.of(context)!.sendAsMessage, style: const TextStyle(color: Colors.white)),
          subtitle: Text(AppLocalizations.of(context)!.shareWithFriends, style: TextStyle(color: Colors.grey[500])),
          onTap: () {
            StoriesService.shareStory(storyId: storyId, sharedTo: 'dm');
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link, color: Colors.purple),
          ),
          title: Text(AppLocalizations.of(context)!.copyLink, style: const TextStyle(color: Colors.white)),
          subtitle: Text(AppLocalizations.of(context)!.shareAnywhere, style: TextStyle(color: Colors.grey[500])),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final bool isOwnStory;
  final VoidCallback onDelete;

  const _OptionsSheet({required this.isOwnStory, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isOwnStory) ...[
          ListTile(
            leading: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
            title: Text(AppLocalizations.of(context)!.addToHighlight, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
            onTap: onDelete,
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.white),
            title: Text(AppLocalizations.of(context)!.report, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.white),
            title: Text(AppLocalizations.of(context)!.blockUser, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ViewersSheet extends StatefulWidget {
  final String storyId;
  final ScrollController scrollController;

  const _ViewersSheet({required this.storyId, required this.scrollController});

  @override
  State<_ViewersSheet> createState() => _ViewersSheetState();
}

class _ViewersSheetState extends State<_ViewersSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StoryView> _viewers = [];
  List<StoryReaction> _reactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final viewersResult = await StoriesService.getStoryViewers(storyId: widget.storyId);
    final reactionsResult = await StoriesService.getStoryReactions(storyId: widget.storyId);

    if (mounted) {
      setState(() {
        _viewers = (viewersResult['views'] as List<StoryView>?) ?? [];
        _reactions = (reactionsResult['reactions'] as List<StoryReaction>?) ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.viewsTab(_viewers.length.toString())),
            Tab(text: AppLocalizations.of(context)!.reactionsTab(_reactions.length.toString())),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildViewersList(),
                    _buildReactionsList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildViewersList() {
    if (_viewers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.noViewersYet, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _viewers.length,
      itemBuilder: (context, index) {
        final viewer = _viewers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: viewer.user?.imageUrls.isNotEmpty == true
                ? CachedNetworkImageProvider(viewer.user!.imageUrls.first)
                : null,
            backgroundColor: Colors.grey[800],
            child: viewer.user?.imageUrls.isEmpty == true
                ? Text(viewer.user?.name?.substring(0, 1) ?? '?')
                : null,
          ),
          title: Text(
            viewer.user?.name ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            timeago.format(viewer.viewedAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildReactionsList() {
    if (_reactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.noReactionsYet, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _reactions.length,
      itemBuilder: (context, index) {
        final reaction = _reactions[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: reaction.user?.imageUrls.isNotEmpty == true
                ? CachedNetworkImageProvider(reaction.user!.imageUrls.first)
                : null,
            backgroundColor: Colors.grey[800],
            child: reaction.user?.imageUrls.isEmpty == true
                ? Text(reaction.user?.name?.substring(0, 1) ?? '?')
                : null,
          ),
          title: Text(
            reaction.user?.name ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: Text(reaction.emoji, style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }
}

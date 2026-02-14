import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/story/story_poll_widget.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';
import 'package:bananatalk_app/widgets/story/story_reaction_bar.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Full-screen story viewer with all interactive features
class StoryViewerScreen extends StatefulWidget {
  final List<UserStories> userStories;
  final int initialUserIndex;
  final int initialStoryIndex;
  final String currentUserId;

  const StoryViewerScreen({
    Key? key,
    required this.userStories,
    this.initialUserIndex = 0,
    this.initialStoryIndex = 0,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late int _currentUserIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  late PageController _pageController;

  bool _isPaused = false;
  String? _showingReaction;
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isReplyOpen = false;

  List<UserStories> get _userStories => widget.userStories;
  UserStories get _currentUserStories => _userStories[_currentUserIndex];
  List<Story> get _currentStories => _currentUserStories.stories;
  Story get _currentStory => _currentStories[_currentStoryIndex];
  bool get _isOwnStory => _currentUserStories.user.id == widget.currentUserId;

  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _currentStoryIndex = widget.initialStoryIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressComplete);

    _pageController = PageController(initialPage: _currentUserIndex);

    _focusNode.addListener(() {
      setState(() => _isReplyOpen = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _pauseProgress();
      } else {
        _resumeProgress();
      }
    });

    _markAsViewed();
    _startProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.forward();
  }

  void _pauseProgress() {
    _progressController.stop();
    setState(() => _isPaused = true);
  }

  void _resumeProgress() {
    if (!_isReplyOpen) {
      _progressController.forward();
      setState(() => _isPaused = false);
    }
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _progressController.reset();
      _markAsViewed();
      _startProgress();
    } else if (_currentUserIndex < _userStories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _progressController.reset();
      _startProgress();
    } else if (_currentUserIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    _progressController.reset();
    _markAsViewed();
    _startProgress();
  }

  Future<void> _markAsViewed() async {
    if (!_isOwnStory) {
      await StoriesService.viewStory(storyId: _currentStory.id);
    }
  }

  void _onTapDown(TapDownDetails details) {
    _pauseProgress();
  }

  void _onTapUp(TapUpDetails details) {
    _resumeProgress();
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _goToPreviousStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      _goToNextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _pauseProgress();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _resumeProgress();
  }

  Future<void> _react(String emoji) async {
    setState(() => _showingReaction = emoji);
    HapticFeedback.lightImpact();

    await StoriesService.reactToStory(storyId: _currentStory.id, emoji: emoji);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showingReaction = null);
    });
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final message = _replyController.text.trim();
    _replyController.clear();
    _focusNode.unfocus();

    await StoriesService.replyToStory(storyId: _currentStory.id, message: message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.replySent),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _onPollVote(int optionIndex) async {
    await StoriesService.votePoll(
      storyId: _currentStory.id,
      optionIndex: optionIndex,
    );
  }

  void _onQuestionAnswer(String text, bool isAnonymous) async {
    await StoriesService.answerQuestion(
      storyId: _currentStory.id,
      text: text,
      isAnonymous: isAnonymous,
    );
  }

  Future<void> _shareStory() async {
    _pauseProgress();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _ShareBottomSheet(
        storyId: _currentStory.id,
        onShared: () {
          Navigator.pop(context);
          _resumeProgress();
        },
      ),
    );

    _resumeProgress();
  }

  void _showViewers() {
    _pauseProgress();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _ViewersBottomSheet(storyId: _currentStory.id),
    ).then((_) => _resumeProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _userStories.length,
          itemBuilder: (context, userIndex) {
            if (userIndex != _currentUserIndex) {
              // Preload neighbors
              return const SizedBox();
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                // Story content
                _buildStoryContent(),

                // Progress bars
                _buildProgressBars(),

                // Header
                _buildHeader(),

                // Interactive overlays
                _buildInteractiveOverlays(),

                // Reaction animation
                if (_showingReaction != null)
                  Center(
                    child: StoryReactionAnimation(
                      emoji: _showingReaction!,
                      onComplete: () {},
                    ),
                  ),

                // Reply input (only for others' stories)
                if (!_isOwnStory) _buildReplyInput(),

                // Viewers (only for own stories)
                if (_isOwnStory) _buildViewersButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryContent() {
    final story = _currentStory;

    if (story.mediaType == 'text') {
      return Container(
        color: Color(int.parse(story.backgroundColor.replaceFirst('#', '0xFF'))),
        alignment: Alignment.center,
        padding: AppSpacing.paddingXXL,
        child: Text(
          story.text ?? '',
          style: TextStyle(
            color: Color(int.parse(story.textColor.replaceFirst('#', '0xFF'))),
            fontSize: 28,
            fontWeight: story.fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontStyle: story.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
            fontFamily: story.fontStyle == 'handwriting' ? 'Caveat' : null,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final mediaUrl = story.mediaUrl.isNotEmpty
        ? story.mediaUrl
        : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : '');

    return CachedImageWidget(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholderColor: AppColors.gray900,
      errorWidget: Container(
        color: AppColors.gray900,
        child: Center(
          child: Icon(Icons.broken_image, color: AppColors.gray500, size: 48),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Row(
        children: List.generate(_currentStories.length, (index) {
          double progress;
          if (index < _currentStoryIndex) {
            progress = 1.0;
          } else if (index > _currentStoryIndex) {
            progress = 0.0;
          } else {
            progress = _progressController.value;
          }

          return Expanded(
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: LinearProgressIndicator(
                    value: index == _currentStoryIndex
                        ? _progressController.value
                        : progress,
                    backgroundColor: AppColors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(AppColors.white),
                  ),
                );
              },
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
      top: MediaQuery.of(context).padding.top + AppSpacing.xl,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: user.imageUrls.isNotEmpty
                ? NetworkImage(user.imageUrls.first)
                : null,
            backgroundColor: AppColors.gray800,
            child: user.imageUrls.isEmpty
                ? Text(user.name.isNotEmpty ? user.name[0] : '?')
                : null,
          ),
          Spacing.hGapSM,

          // Name & time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: context.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (story.privacy == StoryPrivacy.closeFriends) ...[
                      Spacing.hGapSM,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: AppRadius.borderXS,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.closeFriends,
                          style: context.captionSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  timeago.format(story.createdAt),
                  style: context.caption.copyWith(
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (_currentStory.allowSharing && !_isOwnStory)
            IconButton(
              icon: Icon(Icons.send, color: AppColors.white),
              onPressed: _shareStory,
            ),

          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () => _showMoreOptions(),
          ),

          IconButton(
            icon: Icon(Icons.close, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveOverlays() {
    final story = _currentStory;

    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Poll
          if (story.poll != null)
            StoryPollWidget(
              poll: story.poll!,
              isOwner: _isOwnStory,
              onVote: _onPollVote,
            ),

          // Question box
          if (story.questionBox != null)
            StoryQuestionBoxWidget(
              questionBox: story.questionBox!,
              isOwner: _isOwnStory,
              onSubmitAnswer: _onQuestionAnswer,
            ),

          // Location sticker
          if (story.location != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: _LocationSticker(location: story.location!),
            ),

          // Link sticker
          if (story.link != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: _LinkSticker(link: story.link!),
            ),

          // Music sticker
          if (story.music != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: _MusicSticker(music: story.music!),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
          top: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            // Reaction bar
            if (!_isReplyOpen && _currentStory.allowReplies)
              StoryReactionBar(
                currentReaction: _currentStory.userReaction,
                onReact: _react,
              ),

            Spacing.hGapSM,

            // Reply input
            if (_currentStory.allowReplies)
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _focusNode,
                  style: context.bodyMedium.copyWith(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.replyTo(_currentUserStories.user.name),
                    hintStyle: context.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: AppColors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderXXL,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    suffixIcon: _isReplyOpen
                        ? IconButton(
                            icon: Icon(Icons.send, color: AppColors.white),
                            onPressed: _sendReply,
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _showViewers,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, color: AppColors.white, size: 20),
                Spacing.hGapXS,
                Text(
                  '${_currentStory.viewCount}',
                  style: context.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_currentStory.reactionCount > 0) ...[
              Spacing.gapXS,
              StoryReactionsSummary(
                reactions: _currentStory.reactions,
                totalCount: _currentStory.reactionCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    _pauseProgress();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: AppSpacing.paddingMD,
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray600,
              borderRadius: AppRadius.borderXS,
            ),
          ),
          if (_isOwnStory) ...[
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: AppColors.white),
              title: Text(AppLocalizations.of(context)!.addToHighlight, style: context.bodyMedium.copyWith(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                // Add to highlight
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(AppLocalizations.of(context)!.delete, style: context.bodyMedium.copyWith(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await StoriesService.deleteStory(storyId: _currentStory.id);
                if (_currentStories.length == 1) {
                  Navigator.pop(context);
                } else {
                  _goToNextStory();
                }
              },
            ),
          ] else ...[
            ListTile(
              leading: Icon(Icons.report_outlined, color: AppColors.white),
              title: Text(AppLocalizations.of(context)!.report, style: context.bodyMedium.copyWith(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                // Report story
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.white),
              title: Text(AppLocalizations.of(context)!.blockUser, style: context.bodyMedium.copyWith(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                // Block user
              },
            ),
          ],
          Spacing.gapLG,
        ],
      ),
    ).then((_) => _resumeProgress());
  }
}

// Helper widgets
class _LocationSticker extends StatelessWidget {
  final StoryLocation location;

  const _LocationSticker({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.borderXL,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: AppColors.error, size: 18),
          Spacing.hGapXS,
          Text(
            location.name,
            style: context.labelMedium.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkSticker extends StatelessWidget {
  final StoryLink link;

  const _LinkSticker({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open link
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: AppRadius.borderXL,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, color: AppColors.white, size: 18),
            Spacing.hGapXS,
            Text(
              link.displayText,
              style: context.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacing.hGapXS,
            Icon(Icons.arrow_forward, color: AppColors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _MusicSticker extends StatelessWidget {
  final StoryMusic music;

  const _MusicSticker({required this.music});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.6),
        borderRadius: AppRadius.borderXL,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, color: AppColors.white, size: 18),
          Spacing.hGapSM,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                music.title,
                style: context.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                music.artist,
                style: context.captionSmall.copyWith(
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String storyId;
  final VoidCallback onShared;

  const _ShareBottomSheet({required this.storyId, required this.onShared});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Text(
            AppLocalizations.of(context)!.shareStory,
            style: context.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.send, color: AppColors.white),
          title: Text(AppLocalizations.of(context)!.sendAsMessage, style: context.bodyMedium.copyWith(color: AppColors.white)),
          onTap: () async {
            await StoriesService.shareStory(storyId: storyId, sharedTo: 'dm');
            onShared();
          },
        ),
        ListTile(
          leading: Icon(Icons.copy, color: AppColors.white),
          title: Text(AppLocalizations.of(context)!.copyLink, style: context.bodyMedium.copyWith(color: AppColors.white)),
          onTap: () async {
            await StoriesService.shareStory(storyId: storyId, sharedTo: 'external');
            // Copy to clipboard
            onShared();
          },
        ),
        ListTile(
          leading: Icon(Icons.share, color: AppColors.white),
          title: Text(AppLocalizations.of(context)!.shareExternally, style: context.bodyMedium.copyWith(color: AppColors.white)),
          onTap: () async {
            await StoriesService.shareStory(storyId: storyId, sharedTo: 'external');
            Share.share(AppLocalizations.of(context)!.checkOutStory);
            onShared();
          },
        ),
        Spacing.gapLG,
      ],
    );
  }
}

class _ViewersBottomSheet extends StatefulWidget {
  final String storyId;

  const _ViewersBottomSheet({required this.storyId});

  @override
  State<_ViewersBottomSheet> createState() => _ViewersBottomSheetState();
}

class _ViewersBottomSheetState extends State<_ViewersBottomSheet>
    with SingleTickerProviderStateMixin {
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
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.gray500,
          labelStyle: context.labelMedium,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.viewsTab(_viewers.length.toString())),
            Tab(text: AppLocalizations.of(context)!.reactionsTab(_reactions.length.toString())),
          ],
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
        child: Text(AppLocalizations.of(context)!.noViewersYet, style: context.bodyMedium.copyWith(color: AppColors.gray500)),
      );
    }

    return ListView.builder(
      itemCount: _viewers.length,
      itemBuilder: (context, index) {
        final viewer = _viewers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: viewer.user?.imageUrls.isNotEmpty == true
                ? NetworkImage(viewer.user!.imageUrls.first)
                : null,
            backgroundColor: AppColors.gray800,
            child: viewer.user?.imageUrls.isEmpty == true
                ? Text(viewer.user?.name.substring(0, 1) ?? '?')
                : null,
          ),
          title: Text(
            viewer.user?.name ?? 'Unknown',
            style: context.bodyMedium.copyWith(color: AppColors.white),
          ),
          subtitle: Text(
            timeago.format(viewer.viewedAt),
            style: context.caption.copyWith(color: AppColors.gray500),
          ),
        );
      },
    );
  }

  Widget _buildReactionsList() {
    if (_reactions.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noReactionsYet, style: context.bodyMedium.copyWith(color: AppColors.gray500)),
      );
    }

    return ListView.builder(
      itemCount: _reactions.length,
      itemBuilder: (context, index) {
        final reaction = _reactions[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: reaction.user?.imageUrls.isNotEmpty == true
                ? NetworkImage(reaction.user!.imageUrls.first)
                : null,
            backgroundColor: AppColors.gray800,
            child: reaction.user?.imageUrls.isEmpty == true
                ? Text(reaction.user?.name.substring(0, 1) ?? '?')
                : null,
          ),
          title: Text(
            reaction.user?.name ?? 'Unknown',
            style: context.bodyMedium.copyWith(color: AppColors.white),
          ),
          trailing: Text(
            reaction.emoji,
            style: context.displayMedium,
          ),
        );
      },
    );
  }
}

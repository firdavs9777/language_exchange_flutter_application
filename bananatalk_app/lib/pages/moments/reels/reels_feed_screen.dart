import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_controller_pool.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
import 'package:bananatalk_app/services/report_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Full-screen vertical swipe feed for Reels (Workstream G, Task 5).
///
/// Adapted from the orphaned `VideoFeedItem` in
/// `lib/pages/explore/explore_main.dart` (autoplay/loop/tap-pause/overlay
/// layout), but backed by [reelsFeedProvider] (the dedicated
/// `GET /moments/reels` endpoint) rather than `exploreMomentsProvider`, and
/// layered with a hard 3-controller [ReelControllerPool] instead of letting
/// every page item eagerly own its own controller.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key, required this.initialIndex});

  /// Grid index the swipe feed should open at.
  final int initialIndex;

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  final ReelControllerPool _pool = ReelControllerPool();
  late int _currentIndex;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllers());
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _currentUserId = prefs.getString('userId'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause on background/inactive; resume the current reel on return.
    if (state != AppLifecycleState.resumed) {
      _pool.pauseAll();
    } else if (mounted) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pool.disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  List<Moments> get _reels => ref.read(reelsFeedProvider).reels;

  void _syncControllers() {
    final reels = _reels;
    if (_currentIndex < 0 || _currentIndex >= reels.length) return;

    final currentUrl = reels[_currentIndex].video?.url;
    if (currentUrl != null && currentUrl.isNotEmpty) {
      _pool.activate(_currentIndex, currentUrl).then((_) {
        if (mounted) setState(() {});
      });
    }

    if (_currentIndex + 1 < reels.length) {
      final nextUrl = reels[_currentIndex + 1].video?.url;
      if (nextUrl != null && nextUrl.isNotEmpty) {
        _pool.preload(_currentIndex + 1, nextUrl);
      }
    }

    _pool.releaseOutside(_currentIndex);
  }

  void _onPageChanged(int index) {
    // Pause the outgoing controller explicitly — `releaseOutside` disposes
    // it shortly after anyway, but this avoids a beat of overlapping audio.
    _pool.controllerAt(_currentIndex)?.pause();
    setState(() => _currentIndex = index);
    _syncControllers();

    final reels = _reels;
    if (reels.length - index <= 3) {
      ref.read(reelsFeedProvider.notifier).loadMore();
    }
  }

  void _togglePlayPause(int index) {
    final controller = _pool.controllerAt(index);
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  bool _isLiked(Moments reel) {
    if (_currentUserId == null) return false;
    return reel.likedUsers?.contains(_currentUserId) ?? false;
  }

  List<String> _applyLikeToList(Moments reel, bool isLiked) {
    final current = List<String>.from(reel.likedUsers ?? const []);
    final userId = _currentUserId;
    if (userId == null) return current;
    if (isLiked && !current.contains(userId)) {
      current.add(userId);
    } else if (!isLiked) {
      current.remove(userId);
    }
    return current;
  }

  Future<void> _toggleLike(Moments reel) async {
    final wasLiked = _isLiked(reel);
    try {
      final result = wasLiked
          ? await ref.read(momentsServiceProvider).dislikeMoment(reel.id)
          : await ref.read(momentsServiceProvider).likeMoment(reel.id);
      if (!mounted) return;
      final isLikedNow = result['isLiked'] ?? !wasLiked;
      final updated = reel.copyWith(
        likeCount: result['likeCount'] ?? reel.likeCount,
        likedUsers: _applyLikeToList(reel, isLikedNow),
      );
      ref.read(reelsFeedProvider.notifier).updateReel(updated);
    } catch (_) {
      // Non-fatal — a like/dislike hiccup isn't worth interrupting playback.
    }
  }

  void _openComments(Moments reel) {
    _pool.controllerAt(_currentIndex)?.pause();
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => _ReelCommentsPage(reel: reel)),
    ).then((_) {
      if (mounted) _syncControllers();
    });
  }

  void _shareReel(Moments reel) {
    final l10n = AppLocalizations.of(context)!;
    final url = 'https://banatalk.com/moment/${reel.id}';
    Share.share('${l10n.checkOutMoment}\n\n$url');
  }

  Future<void> _openProfile(Moments reel) async {
    _pool.controllerAt(_currentIndex)?.pause();
    final community = await ref
        .read(communityServiceProvider)
        .getSingleCommunity(id: reel.user.id);
    if (!mounted || community == null) return;
    await Navigator.push(
      context,
      AppPageRoute(builder: (_) => SingleCommunity(community: community)),
    );
    if (mounted) _syncControllers();
  }

  void _showMoreOptions(Moments reel) {
    _pool.controllerAt(_currentIndex)?.pause();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text(l10n.report),
              onTap: () {
                Navigator.pop(sheetContext);
                _reportReel(reel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(l10n.blockUser),
              onTap: () async {
                Navigator.pop(sheetContext);
                final prefs = await SharedPreferences.getInstance();
                final currentUserId = prefs.getString('userId');
                if (currentUserId == null || !mounted) return;
                await BlockUserDialog.show(
                  context: context,
                  currentUserId: currentUserId,
                  targetUserId: reel.user.id,
                  targetUserName: reel.user.name,
                  targetUserAvatar: reel.user.imageUrls.isNotEmpty
                      ? reel.user.imageUrls.first
                      : null,
                  ref: ref,
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) _syncControllers();
    });
  }

  Future<void> _reportReel(Moments reel) async {
    const reasons = <String, String>{
      'spam': 'Spam',
      'harassment': 'Harassment',
      'hate_speech': 'Hate speech',
      'nudity': 'Nudity',
      'violence': 'Violence',
      'false_information': 'False information',
      'other': 'Other',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Why are you reporting this reel?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...reasons.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(sheetContext, e.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    // ⚠️ Reports via the Report collection (POST /api/v1/reports) — NOT the
    // legacy /moments/:id/report array endpoint, which never triggers the
    // backend's 2-report auto-hide. See report_service.dart doc comment.
    final result = await ReportService.createReportRecord(
      type: 'moment',
      reportId: reel.id,
      reportedUser: reel.user.id,
      reason: selected,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Report submitted'
              : (result['message']?.toString() ?? 'Failed to submit report'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelsFeedProvider);
    final reels = state.reels;

    if (reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final reel = reels[index];
              final controller = _pool.controllerAt(index);
              return _ReelFeedItem(
                reel: reel,
                controller: controller,
                isLiked: _isLiked(reel),
                onTogglePlayPause: () => _togglePlayPause(index),
                onLike: () => _toggleLike(reel),
                onComment: () => _openComments(reel),
                onShare: () => _shareReel(reel),
                onMore: () => _showMoreOptions(reel),
                onAvatarTap: () => _openProfile(reel),
              );
            },
          ),
          Positioned(
            top: 8,
            left: 4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelFeedItem extends StatelessWidget {
  const _ReelFeedItem({
    required this.reel,
    required this.controller,
    required this.isLiked,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
    required this.onAvatarTap,
  });

  final Moments reel;
  final VideoPlayerController? controller;
  final bool isLiked;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final isReady = controller != null && controller!.value.isInitialized;

    return GestureDetector(
      onTap: onTogglePlayPause,
      onDoubleTap: onLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          else if (reel.video?.thumbnail != null &&
              reel.video!.thumbnail!.isNotEmpty)
            CachedImageWidget(
              imageUrl: reel.video!.thumbnail!,
              fit: BoxFit.cover,
            )
          else
            Container(color: Colors.black),

          if (!isReady)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (isReady && !controller!.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 64),
            ),

          // Bottom-left: poster + caption + language/prompt overlay.
          Positioned(
            left: 16,
            right: 88,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: reel.user.imageUrls.isNotEmpty
                            ? NetworkImage(reel.user.imageUrls.first)
                            : null,
                        child: reel.user.imageUrls.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          reel.user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      if (reel.language.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reel.language.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (reel.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    reel.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right action rail.
          Positioned(
            right: 12,
            bottom: 32,
            child: Column(
              children: [
                _RailButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  label: reel.likeCount > 0 ? '${reel.likeCount}' : '',
                  onTap: onLike,
                ),
                const SizedBox(height: 20),
                _RailButton(
                  icon: Icons.chat_bubble_outline,
                  label: reel.commentCount > 0 ? '${reel.commentCount}' : '',
                  onTap: onComment,
                ),
                const SizedBox(height: 20),
                _RailButton(icon: Icons.share, label: '', onTap: onShare),
                const SizedBox(height: 20),
                _RailButton(icon: Icons.more_horiz, label: '', onTap: onMore),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.onTap,
    this.label = '',
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Comments as a pushed page (not a sheet — plan-review M4). The calling
/// video item is paused before this pushes (see `_openComments` above).
class _ReelCommentsPage extends ConsumerStatefulWidget {
  const _ReelCommentsPage({required this.reel});

  final Moments reel;

  @override
  ConsumerState<_ReelCommentsPage> createState() => _ReelCommentsPageState();
}

class _ReelCommentsPageState extends ConsumerState<_ReelCommentsPage> {
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyToCommentId;
  String? _replyToUserName;

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comments)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: CommentsMain(
                id: widget.reel.id,
                paginated: true,
                onReply: (commentId, userName) {
                  setState(() {
                    _replyToCommentId = commentId;
                    _replyToUserName = userName;
                  });
                  _commentFocusNode.requestFocus();
                },
              ),
            ),
          ),
          CreateComment(
            focusNode: _commentFocusNode,
            id: widget.reel.id,
            onCommentAdded: () {
              ref.read(paginatedCommentsProvider(widget.reel.id).notifier).refresh();
            },
            parentCommentId: _replyToCommentId,
            replyToUserName: _replyToUserName,
            onCancelReply: () {
              setState(() {
                _replyToCommentId = null;
                _replyToUserName = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

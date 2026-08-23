import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:bananatalk_app/pages/moments/reels/reel_fit.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_prefetch_policy.dart';
import 'package:bananatalk_app/pages/moments/reels/widgets/reel_overlays.dart';
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

  /// Sound state for the whole session, not per page — muting one reel and
  /// having the next blast audio would be worse than no control at all.
  /// Starts unmuted: opening a reel is deliberate, unlike an autoplaying feed.
  bool _muted = false;

  /// How many upcoming reels to prefetch, driven by connectivity type.
  int _prefetchDepth = 1;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _applyVolume();
  }

  /// Re-applied after every controller swap, since a freshly activated
  /// controller defaults to full volume.
  void _applyVolume() {
    _pool.controllerAt(_currentIndex)?.setVolume(_muted ? 0.0 : 1.0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadCurrentUserId();
    Connectivity().checkConnectivity().then((status) {
      if (mounted) setState(() => _prefetchDepth = reelPrefetchDepth(status));
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) setState(() => _prefetchDepth = reelPrefetchDepth(status));
    });
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
    _connectivitySub?.cancel();
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
        if (mounted) {
          _applyVolume();
          setState(() {});
        }
      });
    }

    if (_currentIndex + 1 < reels.length) {
      final nextUrl = reels[_currentIndex + 1].video?.url;
      if (nextUrl != null && nextUrl.isNotEmpty) {
        _pool.preload(_currentIndex + 1, nextUrl);
      }
    }

    _pool.releaseOutside(_currentIndex);

    // Bytes only: reaches further ahead than the controller window, creating
    // no decoders. releaseOutside() above stays at ±1 for that reason.
    final upcoming = <String>[];
    for (var i = _currentIndex + 1;
        i <= _currentIndex + _prefetchDepth && i < reels.length;
        i++) {
      final url = reels[i].video?.url;
      if (url != null && url.isNotEmpty) upcoming.add(url);
    }
    _pool.prefetchAhead(upcoming);
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

  /// Saved state comes from `savedBy` rather than the model's `isSaved` flag:
  /// the reels endpoint doesn't populate `isSaved`, and `savedBy` is the same
  /// shape `likedUsers` uses, so the optimistic update below matches
  /// `_applyLikeToList` exactly.
  bool _isSaved(Moments reel) {
    if (_currentUserId == null) return false;
    return reel.savedBy.contains(_currentUserId);
  }

  List<String> _applySaveToList(Moments reel, bool isSaved) {
    final current = List<String>.from(reel.savedBy);
    final userId = _currentUserId;
    if (userId == null) return current;
    if (isSaved && !current.contains(userId)) {
      current.add(userId);
    } else if (!isSaved) {
      current.remove(userId);
    }
    return current;
  }

  Future<void> _toggleSave(Moments reel) async {
    final wasSaved = _isSaved(reel);
    // Optimistic: the bookmark must respond instantly, and a failed round trip
    // is reverted below rather than left lying about the state.
    ref.read(reelsFeedProvider.notifier).updateReel(
          reel.copyWith(savedBy: _applySaveToList(reel, !wasSaved)),
        );
    try {
      await MomentsServiceAPI.toggleSave(
        momentId: reel.id,
        currentlySaved: wasSaved,
      );
      if (!mounted) return;
      if (!wasSaved) {
        _showSavedToast();
      }
    } catch (_) {
      if (!mounted) return;
      ref.read(reelsFeedProvider.notifier).updateReel(
            reel.copyWith(savedBy: _applySaveToList(reel, wasSaved)),
          );
    }
  }

  void _showSavedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved. Find it in Profile → Saved.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF00BFA5),
      ),
    );
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
                isSaved: _isSaved(reel),
                muted: _muted,
                onSave: () => _toggleSave(reel),
                onToggleMute: _toggleMute,
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

class _ReelFeedItem extends StatefulWidget {
  const _ReelFeedItem({
    required this.reel,
    required this.controller,
    required this.isLiked,
    required this.isSaved,
    required this.muted,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
    required this.onAvatarTap,
    required this.onSave,
    required this.onToggleMute,
  });

  final Moments reel;
  final VideoPlayerController? controller;
  final bool isLiked;
  final bool isSaved;
  final bool muted;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final VoidCallback onAvatarTap;
  final VoidCallback onSave;
  final VoidCallback onToggleMute;

  @override
  State<_ReelFeedItem> createState() => _ReelFeedItemState();
}

class _ReelFeedItemState extends State<_ReelFeedItem> {
  /// Live heart bursts, keyed so several rapid double-taps can overlap.
  final List<_HeartBurstEntry> _bursts = <_HeartBurstEntry>[];
  int _burstSeq = 0;

  /// Drives the brief play/pause glyph after a tap. While the video is paused
  /// the glyph is shown regardless (see build).
  bool _flashVisible = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    widget.onTogglePlayPause();
    setState(() => _flashVisible = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _flashVisible = false);
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    // Spawn the heart where the finger landed. Firing it from the centre is
    // what makes double-tap-to-like feel canned.
    final id = _burstSeq++;
    setState(() {
      _bursts.add(_HeartBurstEntry(id: id, at: details.localPosition));
    });
  }

  void _removeBurst(int id) {
    if (!mounted) return;
    setState(() => _bursts.removeWhere((b) => b.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final controller = widget.controller;
    final isReady = controller != null && controller.value.isInitialized;
    final isPaused = isReady && !controller.value.isPlaying;
    // Guard the empty STRING, not just the empty list: an author stored as
    // images: [''] produced NetworkImage("") and threw
    // "No host specified in URI file:///" on every painted frame.
    final avatarUrl = reel.user.imageUrls.isNotEmpty
        ? reel.user.imageUrls.first.trim()
        : '';

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: widget.onLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            // Fill the screen for portrait footage, letterbox only when
            // cropping would gut the frame — see reelVideoFit.
            LayoutBuilder(
              builder: (context, constraints) {
                final size = controller.value.size;
                return FittedBox(
                  fit: reelVideoFit(
                    videoAspect: controller.value.aspectRatio,
                    screenAspect: constraints.maxWidth / constraints.maxHeight,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: VideoPlayer(controller),
                  ),
                );
              },
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

          const ReelScrim(alignment: Alignment.topCenter),
          const ReelScrim(alignment: Alignment.bottomCenter),

          if (isReady)
            ReelPlayPauseFlash(
              isPaused: isPaused,
              showPersistent: isPaused || _flashVisible,
            ),

          for (final burst in _bursts)
            ReelHeartBurst(
              key: ValueKey(burst.id),
              at: burst.at,
              onDone: () => _removeBurst(burst.id),
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
                  onTap: widget.onAvatarTap,
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: avatarUrl.isEmpty
                              ? Container(
                                  color: Colors.white24,
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 20),
                                )
                              : CachedImageWidget(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.white24,
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                        ),
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
                  icon:
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: widget.isLiked ? Colors.redAccent : Colors.white,
                  label: reel.likeCount > 0 ? '${reel.likeCount}' : '',
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 20),
                _RailButton(
                  icon: Icons.chat_bubble_outline,
                  label: reel.commentCount > 0 ? '${reel.commentCount}' : '',
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 20),
                _RailButton(
                  icon: widget.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: widget.isSaved
                      ? const Color(0xFF00BFA5)
                      : Colors.white,
                  label: '',
                  onTap: widget.onSave,
                ),
                const SizedBox(height: 20),
                _RailButton(
                    icon: Icons.share, label: '', onTap: widget.onShare),
                const SizedBox(height: 20),
                _RailButton(
                    icon: Icons.more_horiz, label: '', onTap: widget.onMore),
                const SizedBox(height: 20),
                ReelCircleButton(
                  icon: widget.muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  tooltip: widget.muted ? 'Unmute' : 'Mute',
                  onTap: widget.onToggleMute,
                ),
              ],
            ),
          ),

          // Scrub bar owns the very bottom edge, below the caption and rail.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ReelProgressBar(controller: controller),
          ),
        ],
      ),
    );
  }
}

/// One in-flight heart animation.
class _HeartBurstEntry {
  const _HeartBurstEntry({required this.id, required this.at});

  final int id;
  final Offset at;
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

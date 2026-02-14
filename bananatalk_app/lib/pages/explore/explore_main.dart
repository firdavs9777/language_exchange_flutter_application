import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// Instagram-style Explore/Search screen with video feed
class ExploreMain extends ConsumerStatefulWidget {
  const ExploreMain({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreMain> createState() => _ExploreMainState();
}

class _ExploreMainState extends ConsumerState<ExploreMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: context.bodyLarge,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.search ?? 'Search',
                  border: InputBorder.none,
                  hintStyle: context.bodyMedium.copyWith(
                    color: context.textHint,
                  ),
                ),
                onSubmitted: (value) {
                  // Handle search
                },
              )
            : Text(
                'Explore',
                style: context.displaySmall,
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: context.iconColor,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view)),
            Tab(icon: Icon(Icons.play_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGridView(),
          _buildVideoFeed(),
        ],
      ),
    );
  }

  /// Grid view of moments (like Instagram explore grid)
  Widget _buildGridView() {
    final momentsAsync = ref.watch(momentsFeedProvider);

    return momentsAsync.when(
      data: (moments) {
        if (moments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_outlined, size: 64, color: context.textHint),
                Spacing.gapLG,
                Text(
                  'No moments to explore',
                  style: context.bodyLarge.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: moments.length,
          itemBuilder: (context, index) {
            final moment = moments[index];
            return _buildGridItem(moment);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textHint),
            Spacing.gapLG,
            Text(
              'Failed to load',
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(momentsFeedProvider),
              child: Text(
                'Retry',
                style: context.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(Moments moment) {
    final hasVideo = moment.hasVideo;
    final thumbnailUrl = hasVideo
        ? moment.video?.thumbnail
        : (moment.imageUrls.isNotEmpty ? moment.imageUrls.first : null);

    return GestureDetector(
      onTap: () {
        // Navigate to moment detail or video player
        if (hasVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(moment: moment),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            CachedImageWidget(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: context.containerColor,
              child: Icon(Icons.image, color: context.textMuted),
            ),
          // Video indicator
          if (hasVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.54),
                  borderRadius: AppRadius.borderXS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: AppColors.white, size: 14),
                    if (moment.video?.duration != null) ...[
                      Spacing.hGapXXS,
                      Text(
                        moment.video!.formattedDuration,
                        style: context.captionSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Multiple images indicator
          if (!hasVideo && moment.imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: Spacing.paddingXS,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.54),
                  borderRadius: AppRadius.borderXS,
                ),
                child: const Icon(Icons.collections, color: AppColors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// Instagram Reels-style video feed
  Widget _buildVideoFeed() {
    final momentsAsync = ref.watch(momentsFeedProvider);

    return momentsAsync.when(
      data: (moments) {
        // Filter only video moments
        final videoMoments = moments.where((m) => m.hasVideo).toList();

        if (videoMoments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_outlined, size: 64, color: context.textHint),
                Spacing.gapLG,
                Text(
                  'No videos yet',
                  style: context.bodyLarge.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Spacing.gapSM,
                Text(
                  'Be the first to share a video!',
                  style: context.bodySmall.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: videoMoments.length,
          itemBuilder: (context, index) {
            return VideoFeedItem(moment: videoMoments[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Failed to load videos',
          style: context.bodyMedium,
        ),
      ),
    );
  }
}

/// Full-screen video player for Reels-style feed
class VideoFeedItem extends StatefulWidget {
  final Moments moment;

  const VideoFeedItem({Key? key, required this.moment}) : super(key: key);

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.moment.video?.url == null) return;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.moment.video!.url),
    );

    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or thumbnail
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (widget.moment.video?.thumbnail != null)
            CachedImageWidget(
              imageUrl: widget.moment.video!.thumbnail!,
              fit: BoxFit.cover,
            )
          else
            Container(color: AppColors.black),

          // Loading indicator
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            ),

          // Play/Pause indicator
          if (_isInitialized && !_isPlaying)
            Center(
              child: Container(
                padding: Spacing.paddingLG,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
            ),

          // User info overlay (bottom)
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: widget.moment.user.imageUrls.isNotEmpty
                          ? NetworkImage(widget.moment.user.imageUrls.first)
                          : null,
                      child: widget.moment.user.imageUrls.isEmpty
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    Spacing.hGapSM,
                    Text(
                      widget.moment.user.name,
                      style: context.titleSmall.copyWith(
                        color: AppColors.white,
                        shadows: [
                          Shadow(color: AppColors.black.withOpacity(0.54), blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacing.gapSM,
                // Description
                Text(
                  widget.moment.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: AppColors.white,
                    shadows: [
                      Shadow(color: AppColors.black.withOpacity(0.54), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons (right side)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: '${widget.moment.likeCount}',
                  onTap: () {},
                ),
                Spacing.gapLG,
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${widget.moment.commentCount}',
                  onTap: () {},
                ),
                Spacing.gapLG,
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 28),
          Spacing.gapXS,
          Text(
            label,
            style: context.caption.copyWith(
              color: AppColors.white,
              shadows: [Shadow(color: AppColors.black.withOpacity(0.54), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen video player screen
class VideoPlayerScreen extends StatefulWidget {
  final Moments moment;

  const VideoPlayerScreen({Key? key, required this.moment}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.moment.video?.url == null) return;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.moment.video!.url),
    );

    await _controller!.initialize();
    await _controller!.setLooping(true);
    await _controller!.play();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          if (_controller != null) {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
            setState(() {});
          }
        },
        child: Center(
          child: _isInitialized && _controller != null
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
              : const CircularProgressIndicator(color: AppColors.white),
        ),
      ),
    );
  }
}

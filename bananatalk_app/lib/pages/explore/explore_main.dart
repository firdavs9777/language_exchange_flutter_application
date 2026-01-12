import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.search ?? 'Search',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                onSubmitted: (value) {
                  // Handle search
                },
              )
            : const Text(
                'Explore',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black87,
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
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black87,
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
                Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No moments to explore',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Failed to load', style: TextStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: () => ref.refresh(momentsFeedProvider),
              child: const Text('Retry'),
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
              color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          // Video indicator
          if (hasVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                    if (moment.video?.duration != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        moment.video!.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.collections, color: Colors.white, size: 16),
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
                Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No videos yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share a video!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
        child: Text('Failed to load videos'),
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
            Container(color: Colors.black),

          // Loading indicator
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Play/Pause indicator
          if (_isInitialized && !_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
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
                    const SizedBox(width: 8),
                    Text(
                      widget.moment.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  widget.moment.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4),
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
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${widget.moment.commentCount}',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
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
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

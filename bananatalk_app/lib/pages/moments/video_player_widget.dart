import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// Video player widget for moment cards
class MomentVideoPlayer extends StatefulWidget {
  final MomentVideo video;
  final double? height;
  final BorderRadius? borderRadius;
  final bool autoPlay;
  final bool showControls;

  const MomentVideoPlayer({
    Key? key,
    required this.video,
    this.height = 280,
    this.borderRadius,
    this.autoPlay = false,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<MomentVideoPlayer> createState() => _MomentVideoPlayerState();
}

class _MomentVideoPlayerState extends State<MomentVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPlayButton = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (_controller != null) return;

    try {
      final videoUrl = ImageUtils.normalizeImageUrl(widget.video.url);
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay) {
          _controller!.play();
          setState(() {
            _isPlaying = true;
            _showPlayButton = false;
          });
        }

        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    final isPlaying = _controller!.value.isPlaying;
    if (isPlaying != _isPlaying && mounted) {
      setState(() {
        _isPlaying = isPlaying;
        _showPlayButton = !isPlaying;
      });
    }

    // Loop video
    if (_controller!.value.position >= _controller!.value.duration) {
      _controller!.seekTo(Duration.zero);
      _controller!.play();
    }
  }

  void _togglePlay() async {
    if (!_isInitialized) {
      await _initializeVideo();
      if (_controller != null && _isInitialized) {
        _controller!.play();
        setState(() {
          _isPlaying = true;
          _showPlayButton = false;
        });
      }
      return;
    }

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
        _showPlayButton = true;
      });
    } else {
      _controller!.play();
      setState(() {
        _isPlaying = true;
        _showPlayButton = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or video
              if (_isInitialized && _controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (widget.video.thumbnail != null)
                CachedImageWidget(
                  imageUrl: widget.video.thumbnail!,
                  fit: BoxFit.cover,
                  height: widget.height,
                )
              else
                Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white38, size: 48),
                  ),
                ),

              // Loading indicator
              if (!_isInitialized && !_hasError && _controller != null)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Play button overlay
              if (_showPlayButton && !_hasError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isInitialized ? Icons.play_arrow : Icons.play_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

              // Error state
              if (_hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Failed to load video',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _controller?.dispose();
                            _controller = null;
                          });
                          _initializeVideo();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Duration badge
              if (widget.video.duration != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.video.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Video indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress bar (if controls enabled)
              if (widget.showControls && _isInitialized && _controller != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF00BFA5),
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen video player
class FullScreenVideoPlayer extends StatefulWidget {
  final MomentVideo video;

  const FullScreenVideoPlayer({Key? key, required this.video}) : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = ImageUtils.normalizeImageUrl(widget.video.url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.play();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
          setState(() {});
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Play/pause indicator
            if (_isInitialized && !_controller.value.isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                ),
              ),

            // Progress bar at bottom
            if (_isInitialized)
              Positioned(
                left: 16,
                right: 16,
                bottom: 48,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF00BFA5),
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

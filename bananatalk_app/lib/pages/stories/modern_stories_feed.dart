import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/modern_story_viewer.dart';
import 'package:bananatalk_app/pages/stories/create_story_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';

/// Modern Instagram/TikTok-like stories feed with animated rings and smooth transitions
class ModernStoriesFeed extends ConsumerStatefulWidget {
  final VoidCallback? onCreateStory;
  final double height;
  final double avatarSize;
  final bool showLabels;

  const ModernStoriesFeed({
    Key? key,
    this.onCreateStory,
    this.height = 110,
    this.avatarSize = 72,
    this.showLabels = true,
  }) : super(key: key);

  @override
  ConsumerState<ModernStoriesFeed> createState() => _ModernStoriesFeedState();
}

class _ModernStoriesFeedState extends ConsumerState<ModernStoriesFeed>
    with TickerProviderStateMixin {
  List<UserStories> _stories = [];
  UserStories? _myStories;
  bool _isLoading = true;
  bool _hasError = false;
  String? _error;

  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _loadStories();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Load my stories
      final myStoriesResponse = await StoriesService.getMyStories();
      if (myStoriesResponse.success && myStoriesResponse.data.isNotEmpty) {
        _myStories = myStoriesResponse.data.first;
      }

      // Load feed stories
      final feedResponse = await StoriesService.getStoriesFeed();
      if (feedResponse.success) {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('userId');

        // Get blocked users
        final blockedUserIds = ref.read(blockedUserIdsProvider).value ?? <String>{};

        // Filter stories
        final filteredStories = feedResponse.data.where((userStories) {
          if (blockedUserIds.contains(userStories.user.id)) return false;
          if (currentUserId != null && userStories.user.id == currentUserId) return false;
          return true;
        }).toList();

        setState(() {
          _stories = filteredStories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _error = feedResponse.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openStoryViewer(int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ModernStoryViewer(
            userStories: _stories,
            initialUserIndex: index,
            onStoriesUpdated: _loadStories,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openMyStories() {
    if (_myStories != null && _myStories!.activeStories.isNotEmpty) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return ModernStoryViewer(
              userStories: [_myStories!],
              initialUserIndex: 0,
              isOwnStory: true,
              onStoriesUpdated: _loadStories,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _createStory() {
    HapticFeedback.lightImpact();
    if (widget.onCreateStory != null) {
      widget.onCreateStory!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateStoryScreen(
            onStoryCreated: _loadStories,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_hasError) {
      return _buildError();
    }

    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryItem();
          }
          return _buildStoryItem(_stories[index - 1], index - 1);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: widget.avatarSize,
                      height: widget.avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[100]!,
                            Colors.grey[300]!,
                          ],
                          stops: [
                            (_shimmerController.value - 0.3).clamp(0, 1),
                            _shimmerController.value,
                            (_shimmerController.value + 0.3).clamp(0, 1),
                          ],
                          begin: const Alignment(-1, -1),
                          end: const Alignment(1, 1),
                        ),
                      ),
                    );
                  },
                ),
                if (widget.showLabels) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 28),
            const SizedBox(height: 8),
            Text(
              'Stories unavailable',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            TextButton(
              onPressed: _loadStories,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStoryItem() {
    final hasActiveStories = _myStories?.activeStories.isNotEmpty == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: hasActiveStories ? _openMyStories : _createStory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Avatar with ring
                _StoryAvatar(
                  size: widget.avatarSize,
                  imageUrl: (_myStories?.user.images.isNotEmpty == true ||
                          _myStories?.user.imageUrls.isNotEmpty == true)
                      ? (_myStories!.user.images.isNotEmpty
                          ? _myStories!.user.images.first
                          : _myStories!.user.imageUrls.first)
                      : null,
                  hasUnseenStories: hasActiveStories,
                  isOwnStory: true,
                  pulseController: hasActiveStories ? null : _pulseController,
                ),

                // Add button
                if (!hasActiveStories)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.gray900 : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 6),
              Text(
                'Your Story',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(UserStories userStories, int index) {
    final hasUnseen = userStories.hasUnviewed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openStoryViewer(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StoryAvatar(
              size: widget.avatarSize,
              imageUrl: (userStories.user.images.isNotEmpty ||
                      userStories.user.imageUrls.isNotEmpty)
                  ? (userStories.user.images.isNotEmpty
                      ? userStories.user.images.first
                      : userStories.user.imageUrls.first)
                  : null,
              fallbackText: userStories.user.name?.isNotEmpty == true
                  ? userStories.user.name![0].toUpperCase()
                  : '?',
              hasUnseenStories: hasUnseen,
              storyCount: userStories.activeStories.length,
              viewedCount: userStories.activeStories.length - userStories.unviewedCount,
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: widget.avatarSize + 8,
                child: Text(
                  userStories.user.name ?? 'User',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                    fontWeight: hasUnseen ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated story avatar with gradient ring
class _StoryAvatar extends StatefulWidget {
  final double size;
  final String? imageUrl;
  final String? fallbackText;
  final bool hasUnseenStories;
  final bool isOwnStory;
  final int storyCount;
  final int viewedCount;
  final AnimationController? pulseController;

  const _StoryAvatar({
    required this.size,
    this.imageUrl,
    this.fallbackText,
    this.hasUnseenStories = false,
    this.isOwnStory = false,
    this.storyCount = 1,
    this.viewedCount = 0,
    this.pulseController,
  });

  @override
  State<_StoryAvatar> createState() => _StoryAvatarState();
}

class _StoryAvatarState extends State<_StoryAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.hasUnseenStories) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StoryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUnseenStories != oldWidget.hasUnseenStories) {
      if (widget.hasUnseenStories) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated gradient ring
          if (widget.hasUnseenStories)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _GradientRingPainter(
                    rotation: _rotationController.value * 2 * math.pi,
                    storyCount: widget.storyCount,
                    viewedCount: widget.viewedCount,
                    hasUnseen: widget.hasUnseenStories,
                  ),
                );
              },
            )
          else
            // Static gray ring
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.gray700 : AppColors.gray300,
                  width: 2,
                ),
              ),
            ),

          // Avatar
          Container(
            width: widget.size - 8,
            height: widget.size - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.gray800 : AppColors.gray100,
              border: Border.all(
                color: isDark ? AppColors.gray900 : Colors.white,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: widget.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? AppColors.gray700 : AppColors.gray200,
                      ),
                      errorWidget: (context, url, error) => _buildFallback(),
                    )
                  : _buildFallback(),
            ),
          ),

          // Live indicator (optional for live stories)
          if (widget.hasUnseenStories && widget.storyCount > 3)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.gray700 : AppColors.gray200,
      alignment: Alignment.center,
      child: Text(
        widget.fallbackText ?? '?',
        style: TextStyle(
          color: isDark ? AppColors.gray300 : AppColors.gray500,
          fontSize: widget.size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Custom painter for animated gradient ring with story segments
class _GradientRingPainter extends CustomPainter {
  final double rotation;
  final int storyCount;
  final int viewedCount;
  final bool hasUnseen;

  _GradientRingPainter({
    required this.rotation,
    required this.storyCount,
    required this.viewedCount,
    required this.hasUnseen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const strokeWidth = 3.0;
    const gapAngle = 0.08; // Gap between segments

    if (storyCount <= 1) {
      // Single story - full ring
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: rotation,
        colors: hasUnseen
            ? const [
                Color(0xFFF58529),
                Color(0xFFDD2A7B),
                Color(0xFF8134AF),
                Color(0xFF515BD4),
                Color(0xFFF58529),
              ]
            : [Colors.grey[400]!, Colors.grey[400]!],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paint);
    } else {
      // Multiple stories - segmented ring
      final segmentAngle = (2 * math.pi - (storyCount * gapAngle)) / storyCount;

      for (int i = 0; i < storyCount; i++) {
        final startAngle = rotation + (i * (segmentAngle + gapAngle)) - (math.pi / 2);
        final isViewed = i < viewedCount;

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        if (isViewed) {
          paint.color = Colors.grey[400]!;
        } else {
          // Gradient for unseen segments
          final rect = Rect.fromCircle(center: center, radius: radius);
          paint.shader = const LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          ).createShader(rect);
        }

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.storyCount != storyCount ||
        oldDelegate.viewedCount != viewedCount;
  }
}

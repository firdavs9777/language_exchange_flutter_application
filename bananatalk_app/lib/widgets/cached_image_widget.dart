import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// A reusable widget for displaying cached network images
/// Provides automatic caching, loading states, and error handling
/// Instagram-like quality with smooth shimmer loading effect
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;
  final bool useNormalization;
  final bool highQuality;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.useNormalization = true,
    this.highQuality = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    final normalizedUrl = useNormalization
        ? ImageUtils.normalizeImageUrl(imageUrl!)
        : imageUrl!;

    // Calculate cache dimensions for high quality
    // Use 2x for retina displays, capped at reasonable max
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheMultiplier = highQuality ? devicePixelRatio.clamp(1.0, 3.0) : 1.0;

    int? cacheWidth;
    int? cacheHeight;

    if (width != null && width!.isFinite) {
      cacheWidth = (width! * cacheMultiplier).toInt().clamp(0, 1200);
    }
    if (height != null && height!.isFinite) {
      cacheHeight = (height! * cacheMultiplier).toInt().clamp(0, 1200);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 150),
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Instagram-like shimmer placeholder effect
  Widget _buildShimmerPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: _ShimmerEffect(
        width: width,
        height: height,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 48,
      ),
    );
  }
}

/// Cached network image for CircleAvatar
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useNormalization;

  const CachedCircleAvatar({
    Key? key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.useNormalization = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: errorWidget ??
            Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            ),
      );
    }

    final normalizedUrl = useNormalization
        ? ImageUtils.normalizeImageUrl(imageUrl!)
        : imageUrl!;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      backgroundImage: CachedNetworkImageProvider(normalizedUrl),
      onBackgroundImageError: (exception, stackTrace) {
        // Error handled by errorWidget
      },
      child: placeholder,
    );
  }
}

/// Cached network image with automatic aspect ratio
class CachedAspectRatioImage extends StatelessWidget {
  final String? imageUrl;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useNormalization;

  const CachedAspectRatioImage({
    Key? key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.useNormalization = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CachedImageWidget(
        imageUrl: imageUrl,
        fit: fit,
        borderRadius: borderRadius,
        placeholder: placeholder,
        errorWidget: errorWidget,
        useNormalization: useNormalization,
      ),
    );
  }
}

/// Instagram-like shimmer loading effect
class _ShimmerEffect extends StatefulWidget {
  final double? width;
  final double? height;

  const _ShimmerEffect({
    this.width,
    this.height,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

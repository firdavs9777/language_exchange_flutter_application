import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// A reusable widget for displaying cached network images
/// Provides automatic caching, loading states, and error handling
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    final normalizedUrl = useNormalization
        ? ImageUtils.normalizeImageUrl(imageUrl!)
        : imageUrl!;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: width != null ? width!.toInt() : null,
      memCacheHeight: height != null ? height!.toInt() : null,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
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


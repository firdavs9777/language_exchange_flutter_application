import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:bananatalk_app/providers/provider_models/image_variant.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// One image of a moment or story.
///
/// With no [variant] this is exactly the [CachedImageWidget] call it replaces
/// (same URL, fit, size and error widget), so a server that sends no variants
/// draws what the app always drew. With a [variant] it shows the tiny blurred
/// placeholder instantly and the feed-size rendition over it; [fullSize]
/// (full-screen viewers) keeps the original; [progressiveFull] (the story
/// viewer, full screen without zoom) shows the placeholder, then the
/// feed-size rendition, then the original on top once it has loaded.
class MomentImage extends StatefulWidget {
  const MomentImage({
    super.key,
    required this.imageUrl,
    this.variant,
    this.fit = BoxFit.cover,
    this.fullSize = false,
    this.progressiveFull = false,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String imageUrl;
  final ImageVariant? variant;
  final BoxFit fit;
  final bool fullSize;
  final bool progressiveFull;
  final double? width;
  final double? height;

  /// Passed through to the network image unchanged (both branches).
  final Widget? errorWidget;

  /// The bytes of a `data:image/…;base64,…` URI, or `null` for anything else
  /// (including undecodable base64).
  static Uint8List? decodePlaceholder(String? dataUri) {
    if (dataUri == null || !dataUri.startsWith('data:image/')) return null;
    final comma = dataUri.indexOf(',');
    if (comma < 0) return null;
    final header = dataUri.substring(0, comma);
    if (!header.endsWith(';base64')) return null;
    try {
      final bytes = base64Decode(dataUri.substring(comma + 1));
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  State<MomentImage> createState() => _MomentImageState();
}

class _MomentImageState extends State<MomentImage> {
  Uint8List? _placeholderBytes;

  @override
  void initState() {
    super.initState();
    _placeholderBytes = MomentImage.decodePlaceholder(
      widget.variant?.placeholder,
    );
  }

  @override
  void didUpdateWidget(MomentImage old) {
    super.didUpdateWidget(old);
    if (old.variant?.placeholder != widget.variant?.placeholder) {
      _placeholderBytes = MomentImage.decodePlaceholder(
        widget.variant?.placeholder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;
    if (variant == null || widget.fullSize) {
      return CachedImageWidget(
        imageUrl: widget.imageUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorWidget: widget.errorWidget,
      );
    }

    final bytes = _placeholderBytes;
    final hasPlaceholder = bytes != null;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (hasPlaceholder)
          Positioned.fill(
            child: Image.memory(
              bytes,
              gaplessPlayback: true,
              // Same fit as the image above, or a letterboxed (contain)
              // photo would keep the blur visible around it.
              fit: widget.fit,
            ),
          ),
        CachedImageWidget(
          imageUrl: variant.feedUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          // The blur is the placeholder; without one the shimmer stays.
          placeholder: hasPlaceholder ? const SizedBox.shrink() : null,
          // A feed-size file that fails to load falls back to the original
          // once; if that fails too, the caller's error widget shows. In
          // progressive mode the original is already the layer above.
          errorWidget: widget.progressiveFull
              ? widget.errorWidget
              : CachedImageWidget(
                  imageUrl: widget.imageUrl,
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                  errorWidget: widget.errorWidget,
                ),
        ),
        if (widget.progressiveFull)
          // Draws nothing until loaded and nothing if it fails, so the
          // feed-size image below stays visible meanwhile.
          CachedImageWidget(
            imageUrl: widget.imageUrl,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            placeholder: const SizedBox.shrink(),
            errorWidget: const SizedBox.shrink(),
          ),
      ],
    );
  }
}

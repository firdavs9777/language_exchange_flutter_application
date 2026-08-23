import 'package:bananatalk_app/services/image_rotation_store.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a network image at its own aspect ratio instead of squeezing it
/// into a fixed-height box.
///
/// The previous fixed `height: 280` + [BoxFit.cover] meant a portrait photo
/// lost most of its top and bottom to a centre crop. This resolves the
/// image's real dimensions first (from the same cache the image itself is
/// rendered from, so there is no extra download) and sizes the box to match.
///
/// The ratio is clamped to [minAspectRatio]..[maxAspectRatio] so a freak
/// panorama or a full-length screenshot can't take over the whole feed. The
/// portrait floor of 0.75 is 3:4 — the shape a phone camera actually
/// produces — so ordinary photos are shown complete, with no crop at all.
class NaturalAspectImage extends StatefulWidget {
  final String imageUrl;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  /// Tallest allowed (width / height). 0.75 == 3:4 portrait.
  final double minAspectRatio;

  /// Widest allowed (width / height). 1.91 == wide landscape.
  final double maxAspectRatio;

  /// Used until the real dimensions are known, to limit layout shift.
  final double fallbackAspectRatio;

  const NaturalAspectImage({
    super.key,
    required this.imageUrl,
    this.borderRadius,
    this.errorWidget,
    this.minAspectRatio = 0.75,
    this.maxAspectRatio = 1.91,
    this.fallbackAspectRatio = 4 / 3,
  });

  @override
  State<NaturalAspectImage> createState() => _NaturalAspectImageState();
}

class _NaturalAspectImageState extends State<NaturalAspectImage> {
  double? _aspectRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
    ImageRotationStore.instance.ensureLoaded();
  }

  @override
  void didUpdateWidget(NaturalAspectImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _detach();
      _aspectRatio = null;
      _resolve();
    }
  }

  void _resolve() {
    final String url = ImageUtils.normalizeImageUrl(widget.imageUrl);
    if (url.isEmpty) return;

    // Same provider + cache manager as CachedImageWidget, so this reads the
    // already-fetched bytes rather than issuing a second request.
    _stream = CachedNetworkImageProvider(
      url,
      cacheManager: AppImageCacheManager.instance,
    ).resolve(ImageConfiguration.empty);

    _listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final double ratio = info.image.width / info.image.height;
        if (!mounted) return;
        setState(() {
          _aspectRatio =
              ratio.clamp(widget.minAspectRatio, widget.maxAspectRatio);
        });
      },
      // Leave the fallback ratio in place; CachedImageWidget renders its own
      // error state inside the box.
      onError: (Object error, StackTrace? stackTrace) {},
    );
    _stream!.addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ImageRotationStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final int turns = store.turnsFor(widget.imageUrl);
        final double natural = _aspectRatio ?? widget.fallbackAspectRatio;

        // A quarter turn transposes the box, so invert the ratio before
        // clamping — otherwise a rotated portrait gets clamped as if it were
        // still landscape.
        final double effective = (turns.isOdd ? 1 / natural : natural)
            .clamp(widget.minAspectRatio, widget.maxAspectRatio);

        Widget image = CachedImageWidget(
          imageUrl: widget.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: widget.errorWidget,
        );

        if (turns != 0) {
          image = RotatedBox(quarterTurns: turns, child: image);
        }

        if (widget.borderRadius != null) {
          image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
        }

        return AspectRatio(aspectRatio: effective, child: image);
      },
    );
  }
}

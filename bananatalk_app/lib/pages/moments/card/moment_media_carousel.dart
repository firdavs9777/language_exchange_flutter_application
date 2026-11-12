import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/image_variant.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/moment_image.dart';

/// Ten is where a carousel stops being browsable and becomes a scroll trap.
///
/// The cap is SHOWN. The grid this replaces rendered
/// `imageCount > 6 ? 6 : imageCount` — everything past the sixth image simply
/// did not exist, with no indication to the reader or the poster.
const int kMomentImageCap = 10;

/// A moment's images, one at a time, swipeable.
///
/// Fixed 4:5 so every card in the feed is the same height and a reader knows
/// where the next post begins without looking. The cost is accepted and real:
/// a panorama loses its edges. Detail uses this same widget, so swiping does
/// not stop working at the moment someone taps through — a carousel in the
/// feed and a grid in detail is worse than either used consistently.
class MomentMediaCarousel extends StatefulWidget {
  const MomentMediaCarousel({
    super.key,
    required this.imageUrls,
    this.onPageChanged,
    this.heroPrefix,
    this.variantFor,
  });

  final List<String> imageUrls;
  final ValueChanged<int>? onPageChanged;

  /// When set, each page is wrapped in a Hero tagged `<prefix>-<index>`, so
  /// opening from the third image expands THAT image rather than the first.
  final String? heroPrefix;

  /// The server's smaller rendition of an image, when it sent one. `null`
  /// (or a `null` result) draws the original at 4:5, as before.
  final ImageVariant? Function(String imageUrl)? variantFor;

  @override
  State<MomentMediaCarousel> createState() => _MomentMediaCarouselState();
}

class _MomentMediaCarouselState extends State<MomentMediaCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  List<String> get _shown =>
      widget.imageUrls.take(kMomentImageCap).toList(growable: false);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _shown;
    if (images.isEmpty) return const SizedBox.shrink();

    final hidden = widget.imageUrls.length - images.length;
    final ratio = widget.variantFor?.call(images.first)?.aspectRatio;
    final frameRatio = ratio == null ? 4 / 5 : ratio.clamp(4 / 5, 1.91);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: frameRatio,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (context, index) {
                    final image = MomentImage(
                      imageUrl: images[index],
                      variant: widget.variantFor?.call(images[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                    if (widget.heroPrefix == null) return image;
                    return Hero(
                      tag: '${widget.heroPrefix}-$index',
                      child: image,
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _counter(context, '${_page + 1}/${images.length}'),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            key: const Key('carousel-dots'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                Container(
                  key: Key('carousel-dot-$i'),
                  width: i == _page ? 7 : 6,
                  height: i == _page ? 7 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? context.primaryColor
                        : context.textMuted.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
        if (hidden > 0)
          Padding(
            key: const Key('carousel-cap-notice'),
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppLocalizations.of(context)!.momentsMore(hidden),
              style: context.captionSmall.copyWith(color: context.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _counter(BuildContext context, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

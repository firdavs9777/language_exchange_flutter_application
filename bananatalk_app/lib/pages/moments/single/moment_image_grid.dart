import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/moments/card/moment_media_carousel.dart';

class MomentImageGrid extends StatelessWidget {
  final List<String> imageUrls;

  /// Hero tags matching the feed card, so opening image three expands THAT
  /// image rather than the first.
  final String? heroPrefix;

  const MomentImageGrid({super.key, required this.imageUrls, this.heroPrefix});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    // The same carousel the feed uses. A carousel in the feed and a grid here
    // would mean swiping works, then stops working, at exactly the point the
    // reader has shown more interest. The grid this replaced also rendered at
    // most six images, so a nine-image moment lost three of them here too.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MomentMediaCarousel(imageUrls: imageUrls, heroPrefix: heroPrefix),
    );
  }
}

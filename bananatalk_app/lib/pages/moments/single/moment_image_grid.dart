import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays one or more moment images in a responsive grid layout.
///
/// - 1 image → full-width with fixed height.
/// - 2 images → side-by-side square tiles.
/// - 3-6 images → 3-column grid; the 6th slot shows "+N" overlay if more exist.
///
/// Tapping any image opens [ImageGallery] at the corresponding index.
class MomentImageGrid extends StatelessWidget {
  final List<String> imageUrls;

  const MomentImageGrid({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGrid(context),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final imageCount = imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CachedImageWidget(
            imageUrl: imageUrls[0],
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            errorWidget: Container(
              width: double.infinity,
              height: 280,
              color: context.containerColor,
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: context.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    if (imageCount == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(context, imageUrls[0], 0),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(context, imageUrls[1], 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 1,
        ),
        itemCount: imageCount > 6 ? 6 : imageCount,
        itemBuilder: (context, index) {
          final isLastItem = index == 5 && imageCount > 6;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImageItem(
              context,
              imageUrls[index],
              index,
              isLastItem: isLastItem,
              remainingCount: isLastItem ? imageCount - 6 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    String url,
    int index, {
    bool isLastItem = false,
    int remainingCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          AppPageRoute(
            builder: (context) => ImageGallery(
              imageUrls: imageUrls,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedImageWidget(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: context.containerColor,
              child: Icon(
                Icons.broken_image,
                size: 30,
                color: context.textMuted,
              ),
            ),
          ),
          if (isLastItem)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

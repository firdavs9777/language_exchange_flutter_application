import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGallery(
      {super.key, required this.imageUrls, this.initialIndex = 0});

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the initial index
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;

    // Add a listener to track page changes
    _pageController.addListener(() {
      int nextIndex = _pageController.page?.round() ?? 0;
      if (nextIndex != currentIndex) {
        setState(() {
          currentIndex = nextIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        itemCount: widget.imageUrls.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final normalizedUrl = ImageUtils.normalizeImageUrl(widget.imageUrls[index]);

          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: normalizedUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                  fadeInDuration: const Duration(milliseconds: 150),
                  fadeOutDuration: const Duration(milliseconds: 100),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

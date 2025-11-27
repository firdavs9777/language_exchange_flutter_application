import 'package:flutter/material.dart';

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
    print(widget.imageUrls);
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
    _pageController.dispose(); // Clean up the controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${currentIndex + 1} of ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        itemCount: widget.imageUrls.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

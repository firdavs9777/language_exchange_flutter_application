import 'package:bananatalk_app/pages/moments/viewer/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/voice_message_player.dart';
import 'package:flutter/material.dart';

/// Image grid layout for a moment with 1-N images. Pure render — no state.
/// Navigation to [ImageGallery] is handled internally.
///
/// When [audio] is provided (moment's `mediaType == 'audio'`), renders a
/// full-width [VoiceMessagePlayer] instead of the image grid.
class MomentCardMedia extends StatelessWidget {
  final List<String> imageUrls;
  final MomentAudio? audio;

  const MomentCardMedia({super.key, required this.imageUrls, this.audio});

  @override
  Widget build(BuildContext context) {
    if (audio != null && audio!.url.isNotEmpty) {
      return _buildAudioPlayer(context, audio!);
    }
    return _buildImageGrid(context);
  }

  Widget _buildAudioPlayer(BuildContext context, MomentAudio audio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: VoiceMessagePlayer(
          audioUrl: audio.url,
          durationSeconds: audio.duration,
          waveform: audio.waveform.isNotEmpty ? audio.waveform : null,
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
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

    // HelloTalk style: 2 images side-by-side with gap
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

    // For 3+ images, use grid
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

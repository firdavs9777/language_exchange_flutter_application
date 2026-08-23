import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// One tile in the reels grid: a thumbnail that comes alive when it is one of
/// the few tiles chosen to play.
///
/// [shouldPlay] is decided by the parent from `reelTilesToPlay`, so the tile
/// itself owns no policy — it only owns its controller's lifecycle.
///
/// [mayDownload] carries the metered-connection rule: on cellular a tile
/// animates only if the bytes are already cached, so browsing the grid cannot
/// quietly spend a data allowance.
class ReelGridTile extends StatefulWidget {
  const ReelGridTile({
    required Key key,
    required this.reel,
    required this.shouldPlay,
    required this.mayDownload,
    required this.onTap,
  }) : super(key: key);

  final Moments reel;
  final bool shouldPlay;
  final bool mayDownload;
  final VoidCallback onTap;

  @override
  State<ReelGridTile> createState() => _ReelGridTileState();
}

class _ReelGridTileState extends State<ReelGridTile> {
  VideoPlayerController? _controller;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldPlay) _start();
  }

  @override
  void didUpdateWidget(ReelGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reelChanged = oldWidget.reel.video?.url != widget.reel.video?.url;
    if (reelChanged) {
      // The tile was recycled onto a different reel (GridView reuses
      // elements): tear down whatever was playing before deciding whether
      // to start again, so we never keep the old clip's controller alive
      // under the new reel's tile.
      _stop();
      if (widget.shouldPlay) _start();
    } else if (widget.shouldPlay && !oldWidget.shouldPlay) {
      _start();
    } else if (!widget.shouldPlay && oldWidget.shouldPlay) {
      _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    final url = widget.reel.video?.url ?? '';
    if (url.isEmpty || _starting || _controller != null) return;
    _starting = true;

    File? file = await ReelVideoCache.instance.cachedFileFor(url);
    if (!mounted) {
      _starting = false;
      return;
    }
    if (file == null && widget.mayDownload) {
      file = await ReelVideoCache.instance.prefetch(url);
    }
    // On a metered connection with nothing cached we simply stay a
    // thumbnail — never stream just to animate a grid preview.
    if (file == null || !mounted || !widget.shouldPlay) {
      _starting = false;
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted || !widget.shouldPlay) {
        await controller.dispose();
        _starting = false;
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // grid previews are always silent
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        _starting = false;
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    } finally {
      _starting = false;
    }
  }

  void _stop() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.pause().whenComplete(controller.dispose);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = widget.reel.video?.thumbnail ?? '';
    final controller = _controller;
    final playing = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail.isNotEmpty)
            CachedImageWidget(imageUrl: thumbnail, fit: BoxFit.cover)
          else
            Container(color: context.containerColor),
          if (playing)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          if (!playing)
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
            ),
          Positioned(
            bottom: 6,
            left: 6,
            child: _LanguageChip(language: widget.reel.language),
          ),
        ],
      ),
    );
  }
}

/// Small pill showing a reel's language, e.g. "EN".
///
/// Moved here from the grid screen's now-deleted `_ReelTile` (Task 6) so the
/// badge keeps rendering on every grid tile. Visual treatment is unchanged.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    if (language.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        language.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

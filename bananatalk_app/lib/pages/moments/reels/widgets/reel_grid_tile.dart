import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_video_cache.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/compact_count.dart';
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
  bool _disposed = false;

  // Bumped every time the tile is stopped or recycled onto a different reel.
  // `_start()` captures the value at entry (`epoch`) and re-checks it after
  // every await via `_bail`; a mismatch means this run is stale (the tile
  // moved on to another reel, or was stopped/disposed) and it must tear down
  // without touching `_controller` or calling `setState`. A plain
  // `_starting` bool cannot tell "still the same reel" apart from "recycled
  // onto a new one", which is exactly the bug this token closes.
  int _epoch = 0;

  // The epoch of the `_start()` call currently in flight, if any. Scoping
  // the reentry guard to the epoch (rather than a single shared bool) means
  // a stale run from an old epoch never blocks a fresh run for the new one:
  // when a reel change bumps `_epoch` and immediately calls `_start()`
  // again, the new call reads a different epoch than whatever the old,
  // still-awaiting call recorded, so it is free to proceed.
  int? _startingEpoch;

  bool _bail(int epoch) => epoch != _epoch || _disposed;

  @override
  void initState() {
    super.initState();
    if (widget.shouldPlay) _start();
  }

  @override
  void didUpdateWidget(ReelGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reelChanged = oldWidget.reel.id != widget.reel.id;
    if (reelChanged) {
      // The tile was recycled onto a different reel (GridView reuses
      // elements): tear down whatever was playing/in-flight before deciding
      // whether to start again, so we never keep the old clip's controller
      // alive under the new reel's tile.
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
    _disposed = true;
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    final url = widget.reel.video?.url ?? '';
    if (url.isEmpty || _controller != null) return;
    final epoch = _epoch;
    // A start for this exact generation is already in flight; do not
    // double-launch it. A start for a DIFFERENT (older) generation being in
    // flight does not block this one — see `_startingEpoch` doc above.
    if (_startingEpoch == epoch) return;
    _startingEpoch = epoch;

    try {
      File? file = await ReelVideoCache.instance.cachedFileFor(url);
      if (_bail(epoch)) return;
      if (file == null && widget.mayDownload) {
        file = await ReelVideoCache.instance.prefetch(url);
      }
      // On a metered connection with nothing cached we simply stay a
      // thumbnail — never stream just to animate a grid preview.
      if (file == null || _bail(epoch) || !widget.shouldPlay) return;

      final controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
        if (_bail(epoch) || !widget.shouldPlay) {
          await controller.dispose();
          return;
        }
        await controller.setLooping(true);
        await controller.setVolume(0); // grid previews are always silent
        await controller.play();
        if (_bail(epoch) || !widget.shouldPlay) {
          await controller.dispose();
          return;
        }
        setState(() => _controller = controller);
      } catch (_) {
        await controller.dispose();
      }
    } finally {
      if (_startingEpoch == epoch) _startingEpoch = null;
    }
  }

  void _stop() {
    _epoch++;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.pause().whenComplete(controller.dispose);
    if (!_disposed) setState(() {});
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
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A play glyph over already-playing video is meaningless,
                  // so it hides once the tile is animating. The count is a
                  // stat, not a playback affordance, so it stays visible
                  // (and stable, not flickering) whether or not the tile is
                  // currently playing.
                  if (!playing) ...[
                    const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    if (widget.reel.likeCount > 0) const SizedBox(width: 2),
                  ],
                  if (widget.reel.likeCount > 0)
                    Text(
                      formatCompactCount(widget.reel.likeCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
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

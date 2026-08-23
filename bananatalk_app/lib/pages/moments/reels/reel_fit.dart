import 'package:flutter/rendering.dart';

/// Smallest share of the source frame that may remain visible before we stop
/// cropping. At 0.5 a portrait clip fills the screen, while a landscape clip —
/// which would be sliced down to a narrow band — is letterboxed instead.
const double kReelMinVisibleFraction = 0.5;

/// How a reel's video should be fitted to the full-screen viewer.
///
/// Reels are portrait-first, so the default is to fill the screen: letterboxing
/// a 9:16 clip with black bars is what makes a viewer feel unfinished. Blind
/// cropping is worse though — a 16:9 clip cropped to a phone screen keeps only
/// about a quarter of the frame. So we cover while enough of the frame
/// survives, and fall back to contain when it wouldn't.
///
/// Both aspects are width / height. Degenerate values (zero, negative, NaN,
/// infinite — a controller can report these before it is initialised) resolve
/// to [BoxFit.contain], which is always safe to render.
BoxFit reelVideoFit({
  required double videoAspect,
  required double screenAspect,
  double minVisibleFraction = kReelMinVisibleFraction,
}) {
  if (!videoAspect.isFinite ||
      !screenAspect.isFinite ||
      videoAspect <= 0 ||
      screenAspect <= 0) {
    return BoxFit.contain;
  }

  // Under cover, the frame is cropped on one axis only. The surviving share of
  // that axis is the ratio of the narrower aspect to the wider one.
  final visibleFraction = videoAspect < screenAspect
      ? videoAspect / screenAspect
      : screenAspect / videoAspect;

  return visibleFraction >= minVisibleFraction ? BoxFit.cover : BoxFit.contain;
}

import 'package:flutter/painting.dart';

/// Share of the width, on the reading-start side, that goes to the previous
/// story; the rest goes forward.
const double kStoryBackZoneFraction = 0.3;

/// Whether a tap at [dx] (from the left edge) in a viewer [width] wide goes
/// back. The back zone sits at the reading start: the left in LTR, the right
/// in RTL (Arabic), where it used to stay on the left.
bool storyTapGoesBack({
  required double dx,
  required double width,
  required TextDirection direction,
}) {
  final fromStart = direction == TextDirection.rtl ? width - dx : dx;
  return fromStart < width * kStoryBackZoneFraction;
}

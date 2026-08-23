import 'dart:math' as math;

/// Most grid tiles allowed to play at once.
///
/// The full-screen viewer caps live controllers at 3 to avoid exhausting
/// native decoders; the grid honours the same ceiling.
const int kReelGridMaxPlaying = 3;

/// Which grid tiles should be playing, nearest the viewport centre first.
///
/// Pure arithmetic rather than a visibility-detector package: the grid already
/// knows its scroll offset, tile extent, column count and viewport height, so
/// the answer is derivable — and unit-testable — without a new dependency.
List<int> reelTilesToPlay({
  required double scrollOffset,
  required double viewportHeight,
  required double tileHeight,
  required int crossAxisCount,
  required int itemCount,
  int maxPlaying = kReelGridMaxPlaying,
}) {
  if (itemCount <= 0 ||
      crossAxisCount <= 0 ||
      tileHeight <= 0 ||
      viewportHeight <= 0 ||
      maxPlaying <= 0) {
    return const [];
  }

  final offset = math.max(0.0, scrollOffset);
  final rowCount = (itemCount / crossAxisCount).ceil();

  final firstVisibleRow =
      ((offset / tileHeight).floor() as int).clamp(0, rowCount - 1);
  final lastVisibleRow = (((offset + viewportHeight) / tileHeight)
          .ceil() as int)
      .clamp(0, rowCount);

  // Rows ordered by how close their centre is to the viewport centre, so the
  // tiles that draw the eye are the ones that move.
  final viewportCentre = offset + viewportHeight / 2;
  final rows = <int>[
    for (int r = firstVisibleRow; r < lastVisibleRow; r++) r,
  ]..sort((a, b) {
      final da = ((a + 0.5) * tileHeight - viewportCentre).abs();
      final db = ((b + 0.5) * tileHeight - viewportCentre).abs();
      return da.compareTo(db);
    });

  final picks = <int>[];
  for (final row in rows) {
    for (var column = 0; column < crossAxisCount; column++) {
      final index = row * crossAxisCount + column;
      if (index >= itemCount) break;
      picks.add(index);
      if (picks.length == maxPlaying) return picks;
    }
  }
  return picks;
}

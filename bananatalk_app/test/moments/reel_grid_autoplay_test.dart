// test/moments/reel_grid_autoplay_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/moments/reels/reel_grid_autoplay.dart';

void main() {
  // A 3-column grid of 200px-tall tiles in an 800px viewport: four rows fit.
  List<int> play({
    required double offset,
    int itemCount = 30,
    int maxPlaying = 3,
  }) =>
      reelTilesToPlay(
        scrollOffset: offset,
        viewportHeight: 800,
        tileHeight: 200,
        crossAxisCount: 3,
        itemCount: itemCount,
        maxPlaying: maxPlaying,
      );

  group('reelTilesToPlay', () {
    test('never returns more than the cap', () {
      expect(play(offset: 0), hasLength(kReelGridMaxPlaying));
    });

    test('honours a lower explicit cap', () {
      expect(play(offset: 0, maxPlaying: 1), hasLength(1));
    });

    test('at the top, plays tiles from the vertically centred rows', () {
      // Viewport covers rows 0-3; its centre is at 400px, inside row 1.
      final indices = play(offset: 0);
      expect(indices.every((i) => i >= 0 && i < 12), isTrue);
      expect(indices.first, inInclusiveRange(3, 5),
          reason: 'the first pick should sit in the centre row, row 1');
    });

    test('after scrolling, the picks follow the viewport', () {
      final indices = play(offset: 2000); // rows 10-13 visible
      expect(indices.every((i) => i >= 27), isTrue);
    });

    test('clamps to itemCount near the end of the list', () {
      final indices = play(offset: 2000, itemCount: 30);
      expect(indices.every((i) => i < 30), isTrue);
    });

    test('an empty list plays nothing', () {
      expect(play(offset: 0, itemCount: 0), isEmpty);
    });

    test('fewer items than the cap plays only what exists', () {
      expect(play(offset: 0, itemCount: 2), hasLength(2));
    });

    test('returns no duplicate indices', () {
      final indices = play(offset: 350);
      expect(indices.toSet(), hasLength(indices.length));
    });

    test('degenerate geometry plays nothing rather than dividing by zero', () {
      expect(
        reelTilesToPlay(
          scrollOffset: 0,
          viewportHeight: 0,
          tileHeight: 0,
          crossAxisCount: 0,
          itemCount: 10,
        ),
        isEmpty,
      );
    });

    test('a negative scroll offset (overscroll bounce) is safe', () {
      final indices = play(offset: -120);
      expect(indices.every((i) => i >= 0 && i < 30), isTrue);
    });
  });
}

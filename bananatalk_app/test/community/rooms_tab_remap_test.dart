import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';

/// Unit tests for the pure tab-index remap helper used by
/// `_syncTabCountWithRoomsFlag` in `community_main.dart`.
///
/// Context: the conditional "Rooms" tab now sits at index 3 (right after
/// Gender), not at the end of the tab list. When the `roomsEnabled` flag
/// flips, `TabController` is rebuilt with one more (or fewer) tab, and the
/// currently-selected tab's index must be remapped by identity — not
/// reused verbatim — or the user's visible tab silently swaps out from
/// under them (see rooms-audit-report.md §5).
void main() {
  const roomsInsertionIndex = 3;

  group('remapTabIndexForRoomsFlag — enabling (7 -> 8 tabs)', () {
    const newCount = 8;

    test('index before insertion point is unchanged', () {
      for (final previousIndex in [0, 1, 2]) {
        final result = remapTabIndexForRoomsFlag(
          previousIndex: previousIndex,
          enabling: true,
          roomsInsertionIndex: roomsInsertionIndex,
          newCount: newCount,
        );
        expect(result, previousIndex, reason: 'previousIndex=$previousIndex');
      }
    });

    test('index at or after insertion point shifts right by one', () {
      // previousIndex=3 was "Nearby" in the 7-tab layout; after Rooms is
      // inserted at 3, Nearby moves to 4 — the user must land on 4, not 3
      // (which is now Rooms).
      for (final previousIndex in [3, 4, 5, 6]) {
        final result = remapTabIndexForRoomsFlag(
          previousIndex: previousIndex,
          enabling: true,
          roomsInsertionIndex: roomsInsertionIndex,
          newCount: newCount,
        );
        expect(
          result,
          previousIndex + 1,
          reason: 'previousIndex=$previousIndex',
        );
      }
    });

    test('clamps into [0, newCount - 1]', () {
      final result = remapTabIndexForRoomsFlag(
        previousIndex: 6, // last valid index in the 7-tab layout
        enabling: true,
        roomsInsertionIndex: roomsInsertionIndex,
        newCount: newCount,
      );
      expect(result, 7);
      expect(result, lessThanOrEqualTo(newCount - 1));
    });
  });

  group('remapTabIndexForRoomsFlag — disabling (8 -> 7 tabs)', () {
    const newCount = 7;

    test('index before insertion point is unchanged', () {
      for (final previousIndex in [0, 1, 2]) {
        final result = remapTabIndexForRoomsFlag(
          previousIndex: previousIndex,
          enabling: false,
          roomsInsertionIndex: roomsInsertionIndex,
          newCount: newCount,
        );
        expect(result, previousIndex, reason: 'previousIndex=$previousIndex');
      }
    });

    test(
      'boundary: index exactly at insertion point (the Rooms tab itself) '
      'falls back to the insertion point, now occupied by the next tab',
      () {
        final result = remapTabIndexForRoomsFlag(
          previousIndex: roomsInsertionIndex, // 3 == Rooms itself
          enabling: false,
          roomsInsertionIndex: roomsInsertionIndex,
          newCount: newCount,
        );
        expect(result, roomsInsertionIndex);
      },
    );

    test('index after insertion point shifts left by one', () {
      // previousIndex=4 was "Nearby" in the 8-tab layout; after Rooms is
      // removed from index 3, Nearby moves back to 3.
      for (final previousIndex in [4, 5, 6, 7]) {
        final result = remapTabIndexForRoomsFlag(
          previousIndex: previousIndex,
          enabling: false,
          roomsInsertionIndex: roomsInsertionIndex,
          newCount: newCount,
        );
        expect(
          result,
          previousIndex - 1,
          reason: 'previousIndex=$previousIndex',
        );
      }
    });

    test('clamps into [0, newCount - 1]', () {
      final result = remapTabIndexForRoomsFlag(
        previousIndex: 7, // last valid index in the 8-tab layout
        enabling: false,
        roomsInsertionIndex: roomsInsertionIndex,
        newCount: newCount,
      );
      expect(result, 6);
      expect(result, lessThanOrEqualTo(newCount - 1));
    });
  });
}

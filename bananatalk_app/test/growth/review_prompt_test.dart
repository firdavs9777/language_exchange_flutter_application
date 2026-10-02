import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/review_prompt_service.dart';

void main() {
  final now = DateTime(2026, 10, 2);
  final cases = <(int, int, DateTime?, bool)>[
    (3, 3, null, true),
    (2, 3, null, false),
    (3, 2, null, false),
    (5, 5, now.subtract(const Duration(days: 59)), false),
    // Exact boundary: the cooldown check is `>=`, so 60 days is due.
    (5, 5, now.subtract(const Duration(days: 60)), true),
    (5, 5, now.subtract(const Duration(days: 61)), true),
  ];
  for (final c in cases) {
    test('mine=${c.$1} theirs=${c.$2} last=${c.$3} -> ${c.$4}', () {
      expect(
        shouldPromptForReview(
          myMessages: c.$1,
          theirMessages: c.$2,
          lastPromptedAt: c.$3,
          now: now,
        ),
        c.$4,
      );
    });
  }
}

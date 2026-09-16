import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/learning/main/sections/practice_entries.dart';

void main() {
  group('Practice entry order', () {
    test('every entry appears exactly once', () {
      // The duplicate-entry defect, caught at the list level: AI Conversation
      // and Pronunciation each had two separate entry points into two separate
      // screens.
      final seen = <PracticeEntry>{};
      for (final entry in practiceEntryOrder) {
        expect(seen.add(entry), isTrue, reason: '$entry appears twice in the order');
      }
    });

    test('every declared entry is placed in the order', () {
      // A new enum value that nobody added to the order is a feature that
      // silently does not exist.
      expect(practiceEntryOrder.toSet(), equals(PracticeEntry.values.toSet()));
    });

    test('the order is the rendered order', () {
      expect(practiceEntryOrder.length, PracticeEntry.values.length);
    });
  });
}

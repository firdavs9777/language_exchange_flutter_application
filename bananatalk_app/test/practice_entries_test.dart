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

    test('the tab holds five entries: the tutor hero plus four cards', () {
      // The whole point of the change. The tab had 12 entry points -- a tutor
      // hero with 5 chips plus a 7-card grid -- and nothing was visible.
      expect(practiceEntryOrder.length, 4,
          reason: 'four grid cards, ordered by measured demand');
    });

    test('translation has left the Study Hub', () {
      // It moved into the chat options menu, where its 74 users already are.
      // Used 2.6x more than anything else here, and it sat fifth of seven on
      // the second tab.
      expect(
        PracticeEntry.values.map((e) => e.name),
        isNot(contains('translation')),
      );
    });

    test('the duplicated entries are gone', () {
      // AI Conversation duplicated the tutor's roleplay chat on a second
      // backend; Pronunciation had two entry points into two screens. The tab
      // was competing with itself, which is what made it feel packed.
      final names = PracticeEntry.values.map((e) => e.name).toList();
      expect(names, isNot(contains('aiConversation')));
      expect(names.where((n) => n.toLowerCase().contains('pronunciation')).length, 1,
          reason: 'exactly one pronunciation entry');
    });

    test('writing check is last, because one person used it', () {
      // 3 calls from 1 user in 30 days. Kept rather than removed on one month
      // of data, but not given a prominent slot.
      expect(practiceEntryOrder.last, PracticeEntry.writingCheck);
    });

    test('lessons leads, because it is the most used thing left', () {
      // 28 lesson calls + 28 builder calls in 30 days, the builder now folded
      // inside rather than sitting beside it.
      expect(practiceEntryOrder.first, PracticeEntry.lessons);
    });
  });
}

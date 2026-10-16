import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/review_prompt_service.dart';
import 'package:bananatalk_app/services/session_prefs.dart';

class _FakeReviewer implements AppReviewer {
  bool available = true;
  int requests = 0;
  int availabilityChecks = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  final now = DateTime(2026, 10, 16, 12);
  final oldAccount = now.subtract(const Duration(days: 30));

  group('isEligibleForRatePrompt', () {
    bool elig({
      DateTime? joinedAt,
      DateTime? last,
      int count = 0,
      bool joinedUnknown = false,
    }) =>
        isEligibleForRatePrompt(
          now: now,
          joinedAt: joinedUnknown ? null : (joinedAt ?? oldAccount),
          lastPromptedAt: last,
          promptCount: count,
        );

    test('fresh install of an established account is eligible', () {
      expect(elig(), isTrue);
    });

    test('never in the first 3 days after signup', () {
      expect(elig(joinedAt: now.subtract(const Duration(days: 2, hours: 23))),
          isFalse);
      expect(elig(joinedAt: now.subtract(const Duration(days: 3))), isTrue);
    });

    test('unknown signup date fails closed', () {
      expect(elig(joinedUnknown: true), isFalse);
    });

    test('at most once per 120 days', () {
      expect(elig(last: now.subtract(const Duration(days: 119)), count: 1),
          isFalse);
      expect(elig(last: now.subtract(const Duration(days: 120)), count: 1),
          isTrue);
    });

    test('never more than 3 times ever', () {
      final longAgo = now.subtract(const Duration(days: 400));
      expect(elig(last: longAgo, count: 2), isTrue);
      expect(elig(last: longAgo, count: 3), isFalse);
      expect(elig(last: longAgo, count: 7), isFalse);
    });
  });

  group('helpers', () {
    test('real conversation needs 3 messages from each side', () {
      expect(isRealConversation(myMessages: 3, theirMessages: 3), isTrue);
      expect(isRealConversation(myMessages: 2, theirMessages: 3), isFalse);
      expect(isRealConversation(myMessages: 3, theirMessages: 2), isFalse);
    });

    test('daily pack trigger reports a 7-day streak', () {
      expect(dailyPackTrigger(null), RatePromptTrigger.dailyPack);
      expect(dailyPackTrigger(3), RatePromptTrigger.dailyPack);
      expect(dailyPackTrigger(7), RatePromptTrigger.streak7);
      expect(dailyPackTrigger(14), RatePromptTrigger.streak7);
      expect(dailyPackTrigger(0), RatePromptTrigger.dailyPack);
    });

    test('rate-prompt prefs are per install (survive logout)', () {
      expect(isDeviceLevelPrefsKey(reviewPromptPrefsKey), isTrue);
      expect(isDeviceLevelPrefsKey(reviewPromptCountPrefsKey), isTrue);
      expect(isDeviceLevelPrefsKey(reviewPromptFirstSeenPrefsKey), isTrue);
    });
  });

  group('ReviewPromptService', () {
    late _FakeReviewer reviewer;
    late DateTime clock;
    late bool inCall;
    late bool budget;
    late List<String> shown;

    ReviewPromptService service() => ReviewPromptService(
          clock: () => clock,
          reviewer: reviewer,
          isInCall: () => inCall,
          tryConsumeBudget: () {
            if (!budget) return false;
            budget = false;
            return true;
          },
          onShown: shown.add,
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ReviewPromptService.debugReset();
      reviewer = _FakeReviewer();
      clock = now;
      inCall = false;
      budget = true;
      shown = [];
    });

    test('an eligible moment requests the review exactly once', () async {
      final asked = await service()
          .maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount);
      expect(asked, isTrue);
      expect(reviewer.requests, 1);
      expect(shown, ['daily_pack']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(reviewPromptCountPrefsKey), 1);
      expect(prefs.getInt(reviewPromptPrefsKey), now.millisecondsSinceEpoch);

      // Same day, budget re-armed: the cooldown still blocks a second ask.
      budget = true;
      await service()
          .maybePrompt(RatePromptTrigger.firstReply, joinedAt: oldAccount);
      expect(reviewer.requests, 1);
      expect(shown, ['daily_pack']);
    });

    test('two moments landing together ask once', () async {
      budget = true;
      final results = await Future.wait([
        service().maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount),
        service().maybePrompt(RatePromptTrigger.streak7, joinedAt: oldAccount),
      ]);
      expect(results.where((r) => r), hasLength(1));
      expect(reviewer.requests, 1);
    });

    test('asks again after 120 days, at most 3 times ever', () async {
      for (var i = 0; i < 5; i++) {
        budget = true;
        await service()
            .maybePrompt(RatePromptTrigger.lesson, joinedAt: oldAccount);
        clock = clock.add(const Duration(days: 121));
      }
      expect(reviewer.requests, 3);
      expect(shown, ['lesson', 'lesson', 'lesson']);
    });

    test('new account: nothing in the first 3 days', () async {
      await service().maybePrompt(RatePromptTrigger.dailyPack,
          joinedAt: now.subtract(const Duration(days: 1)));
      expect(reviewer.requests, 0);
      expect(reviewer.availabilityChecks, 0);
      expect(budget, isTrue, reason: 'an ineligible moment spends no budget');
    });

    test('unknown signup date falls back to the install first-seen stamp',
        () async {
      await service().maybePrompt(RatePromptTrigger.dailyPack);
      expect(reviewer.requests, 0, reason: 'first evaluation stamps today');
      clock = now.add(const Duration(days: 3));
      await service().maybePrompt(RatePromptTrigger.dailyPack);
      expect(reviewer.requests, 1);
    });

    test('never during a call', () async {
      inCall = true;
      await service()
          .maybePrompt(RatePromptTrigger.firstReply, joinedAt: oldAccount);
      expect(reviewer.requests, 0);
      expect(budget, isTrue);
    });

    test('never stacks: a spent pop-up budget skips the ask', () async {
      budget = false;
      await service()
          .maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount);
      expect(reviewer.requests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(reviewPromptCountPrefsKey), isNull,
          reason: 'a skipped moment is not counted');
    });

    test('unavailable platform does nothing and spends no budget', () async {
      reviewer.available = false;
      await service()
          .maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount);
      expect(reviewer.requests, 0);
      expect(budget, isTrue);
      expect(shown, isEmpty);
    });

    test('legacy review_prompt_at counts as one prompt and keeps cooldown',
        () async {
      SharedPreferences.setMockInitialValues({
        reviewPromptPrefsKey:
            now.subtract(const Duration(days: 61)).millisecondsSinceEpoch,
      });
      await service()
          .maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount);
      expect(reviewer.requests, 0, reason: '61 days < 120-day cooldown');
      clock = now.add(const Duration(days: 60));
      await service()
          .maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount);
      expect(reviewer.requests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(reviewPromptCountPrefsKey), 2);
    });

    test('a throwing reviewer never escapes', () async {
      final s = ReviewPromptService(
        clock: () => clock,
        reviewer: _ThrowingReviewer(),
        isInCall: () => false,
        tryConsumeBudget: () => true,
        onShown: (_) {},
      );
      expect(
          await s.maybePrompt(RatePromptTrigger.dailyPack, joinedAt: oldAccount),
          isFalse);
    });
  });
}

class _ThrowingReviewer implements AppReviewer {
  @override
  Future<bool> isAvailable() async => throw StateError('boom');
  @override
  Future<void> requestReview() async => throw StateError('boom');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/services/guide_store.dart';

/// The rule that decides whether a first-timer sees the panel. Pure, because
/// a rule living inline in a widget drifts from the UI silently -- the
/// registration photo step and its submit gate disagreed for months and
/// locked OAuth users out of signup entirely.
void main() {
  group('shouldShowFirstSessionGuidance', () {
    test('someone inside the window who has not messaged sees it', () {
      expect(
        shouldShowFirstSessionGuidance(withinWindow: true, hasMessaged: false),
        isTrue,
      );
    });

    test('a user who has already messaged never sees it', () {
      expect(
        shouldShowFirstSessionGuidance(withinWindow: true, hasMessaged: true),
        isFalse,
      );
    });

    test('an account past the window never sees it', () {
      expect(
        shouldShowFirstSessionGuidance(withinWindow: false, hasMessaged: false),
        isFalse,
      );
    });

    test('it retires on the same day as the four generic guides', () {
      // Matches nagging a day longer than every other tab would read as a
      // bug in Matches, so the two share one rule rather than two numbers.
      for (final within in [true, false]) {
        for (final acted in [true, false]) {
          expect(
            shouldShowFirstSessionGuidance(
                withinWindow: within, hasMessaged: acted),
            shouldShowGuide(withinWindow: within, acted: acted),
          );
        }
      }
    });
  });

  // Review Focus 1: storage unavailable must hide the panel, never break
  // Matches. FirstSessionState.unknown encodes that, so the predicate must
  // read it as "nothing to show".
  group('the unknown-storage state hides the panel', () {
    test('unknown reads as already-messaged, so nothing is shown', () {
      const unknown = FirstSessionState.unknown;
      expect(
        shouldShowFirstSessionGuidance(
          withinWindow: true,
          hasMessaged: unknown.hasMessaged,
        ),
        isFalse,
      );
    });
  });

  // Review Focus 2: a missing or malformed createdAt must mean "not new",
  // not an exception. Community.isNewUser is the only account-age rule in the
  // app and had no test of its own.
  group('Community.isNewUser tolerates a bad createdAt', () {
    Community withCreatedAt(String v) => Community(
          id: 'u',
          appleId: '',
          googleId: '',
          name: 'n',
          email: '',
          mbti: '',
          bloodType: '',
          bio: '',
          images: const [],
          birth_day: '',
          birth_month: '',
          gender: '',
          birth_year: '',
          native_language: '',
          language_to_learn: '',
          imageUrls: const [],
          createdAt: v,
          version: 0,
          followers: const [],
          followings: const [],
          location: Location.defaultLocation(),
        );

    test('an empty createdAt is not new', () {
      expect(withCreatedAt('').isNewUser, isFalse);
    });

    test('an unparseable createdAt is not new, and does not throw', () {
      expect(withCreatedAt('not-a-date').isNewUser, isFalse);
    });

    test('a recent createdAt is new', () {
      final recent =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      expect(withCreatedAt(recent).isNewUser, isTrue);
    });

    test('an old createdAt is not new', () {
      final old =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      expect(withCreatedAt(old).isNewUser, isFalse);
    });
  });
}

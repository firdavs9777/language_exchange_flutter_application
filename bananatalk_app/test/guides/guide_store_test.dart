import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/services/guide_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldShowGuide', () {
    test('someone inside the window who has not acted sees it', () {
      expect(shouldShowGuide(withinWindow: true, acted: false), isTrue);
    });

    test('past the window, nobody sees it', () {
      expect(shouldShowGuide(withinWindow: false, acted: false), isFalse);
    });

    test('someone who already acted does not, even inside the window', () {
      expect(shouldShowGuide(withinWindow: true, acted: true), isFalse);
    });

    test('how many times it has been seen is not part of the rule', () {
      // Deliberate: the window ends the guide, not a view count. A count
      // could not say how long a guide would live -- two launches is three
      // minutes for one user and most of a week for another.
      expect(shouldShowGuide(withinWindow: true, acted: false), isTrue);
    });
  });

  group('the window', () {
    Community joinedDaysAgo(int days) => Community(
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
          createdAt:
              DateTime.now().subtract(Duration(days: days)).toIso8601String(),
          version: 0,
          followers: const [],
          followings: const [],
          location: Location.defaultLocation(),
        );

    test('is three days, counted from signup', () {
      expect(kGuideWindowDays, 3);
    });

    test('covers the whole of day 0, 1 and 2', () {
      for (var d = 0; d < kGuideWindowDays; d++) {
        expect(joinedDaysAgo(d).joinedWithinDays(kGuideWindowDays), isTrue,
            reason: 'day $d is inside a $kGuideWindowDays-day window');
      }
    });

    test('is over on day 3', () {
      expect(
        joinedDaysAgo(kGuideWindowDays).joinedWithinDays(kGuideWindowDays),
        isFalse,
      );
    });

    test('is shorter than the isNewUser cohort it sits inside', () {
      // isNewUser also decides matching and the analytics cohort, where a
      // wider window is correct. A guide outliving its own tab's card would
      // be the giveaway that these got merged.
      final midway = joinedDaysAgo(kGuideWindowDays + 1);
      expect(midway.isNewUser, isTrue);
      expect(midway.joinedWithinDays(kGuideWindowDays), isFalse);
    });

    test('an unparseable createdAt shows nothing, rather than everything', () {
      expect(joinedDaysAgo(0).joinedWithinDays(kGuideWindowDays), isTrue);
      final broken = Community(
        id: 'u', appleId: '', googleId: '', name: 'n', email: '', mbti: '',
        bloodType: '', bio: '', images: const [], birth_day: '',
        birth_month: '', gender: '', birth_year: '', native_language: '',
        language_to_learn: '', imageUrls: const [], createdAt: 'not-a-date',
        version: 0, followers: const [], followings: const [],
        location: Location.defaultLocation(),
      );
      expect(broken.joinedWithinDays(kGuideWindowDays), isFalse);
    });
  });

  group('GuideStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install has not acted and has seen nothing', () async {
      final state = await GuideStore.read(GuideSurface.moments);
      expect(state.acted, isFalse);
      expect(state.timesShown, 0);
    });

    test('recordShown increments, markActed sticks', () async {
      await GuideStore.recordShown(GuideSurface.moments);
      await GuideStore.recordShown(GuideSurface.moments);
      await GuideStore.markActed(GuideSurface.moments);

      final state = await GuideStore.read(GuideSurface.moments);
      expect(state.timesShown, 2);
      expect(state.acted, isTrue);
    });

    test('surfaces do not share a counter', () async {
      await GuideStore.recordShown(GuideSurface.moments);
      await GuideStore.markActed(GuideSurface.moments);

      final other = await GuideStore.read(GuideSurface.profile);
      expect(other.timesShown, 0,
          reason: 'seeing the Moments guide must not burn the Profile cap');
      expect(other.acted, isFalse);
    });

    test('a value of the wrong type reads as its default, not a throw',
        () async {
      // An older build could have written a String under one of these keys.
      // getInt/getBool throw on a type mismatch, and a throw here would take
      // the whole page down with it.
      SharedPreferences.setMockInitialValues({
        GuideSurface.moments.shownKey: 'two',
        GuideSurface.moments.actedKey: 7,
      });

      final state = await GuideStore.read(GuideSurface.moments);
      expect(state.timesShown, 0);
      expect(state.acted, isFalse);
    });

    test('unknown hides the guide rather than showing it', () {
      expect(GuideState.unknown.acted, isTrue,
          reason: 'unreadable storage must fail closed');
      expect(
        shouldShowGuide(
          withinWindow: true,
          acted: GuideState.unknown.acted,
        ),
        isFalse,
      );
    });
  });

  group('pref keys', () {
    test('Matches keeps the pre-existing keys', () {
      // Renaming these would reset the counter for every install mid-rollout
      // and show the panel three more times to people already finished with
      // it -- and lose "has sent a first message" entirely, which is the
      // flag first_message_sent is deduplicated on.
      expect(GuideSurface.matches.shownKey,
          'first_session_guidance_shown_count');
      expect(GuideSurface.matches.actedKey, 'first_conversation_done');
    });

    test('every surface has a distinct pair of keys', () {
      final keys = <String>[];
      for (final s in GuideSurface.values) {
        keys..add(s.shownKey)..add(s.actedKey);
      }
      expect(keys.toSet().length, keys.length);
    });

    test('every surface has a distinct analytics slug', () {
      final slugs = GuideSurface.values.map((s) => s.slug).toList();
      expect(slugs.toSet().length, slugs.length,
          reason: 'two tabs sharing a slug makes guide_shown unreadable');
    });
  });
}

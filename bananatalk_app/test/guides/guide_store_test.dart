import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/guide_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldShowGuide', () {
    test('an eligible new user sees it', () {
      expect(
        shouldShowGuide(isNewUser: true, acted: false, timesShown: 0),
        isTrue,
      );
    });

    test('an established account does not', () {
      expect(
        shouldShowGuide(isNewUser: false, acted: false, timesShown: 0),
        isFalse,
      );
    });

    test('someone who already acted does not', () {
      expect(
        shouldShowGuide(isNewUser: true, acted: true, timesShown: 0),
        isFalse,
      );
    });

    test('the cap is exclusive, so the third view is the last', () {
      expect(
        shouldShowGuide(
            isNewUser: true, acted: false, timesShown: kMaxGuideViews - 1),
        isTrue,
      );
      expect(
        shouldShowGuide(
            isNewUser: true, acted: false, timesShown: kMaxGuideViews),
        isFalse,
      );
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
          isNewUser: true,
          acted: GuideState.unknown.acted,
          timesShown: GuideState.unknown.timesShown,
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

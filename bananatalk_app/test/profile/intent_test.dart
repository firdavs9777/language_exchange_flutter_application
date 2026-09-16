import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/profile/edit/intent_edit.dart';
import 'package:bananatalk_app/pages/profile/edit_main/completion_calculator.dart';

ProfileCompletion _completion({List<String> intents = const []}) =>
    calculateProfileCompletion(
      name: 'Ana',
      gender: 'female',
      bio: 'hi',
      nativeLanguage: 'Korean',
      languageToLearn: 'English',
      languageLevel: 'B1',
      mbti: 'INTJ',
      address: 'Seoul',
      topics: const ['music'],
      intents: intents,
    );

void main() {
  test('intents count toward profile completion', () {
    expect(_completion().totalFields, 10);
    expect(_completion().completedFields, 9);
    expect(_completion(intents: const ['learn']).completedFields, 10);
  });

  test('a fully filled profile with an intent reads 100%', () {
    expect(_completion(intents: const ['learn', 'meet']).percent, 100);
  });

  _publicIntentsGroup();

  test('an empty intent list leaves the profile incomplete', () {
    // The completion card is the surface that reaches the existing 1,813
    // users, so an unset intent has to register as missing.
    expect(_completion().percent, lessThan(100));
  });
}

// ---------------------------------------------------------------------------
// The dating intent must never be rendered. spec 2026-09-17 §2.3.
// ---------------------------------------------------------------------------

void _publicIntentsGroup() {
  group('publicIntents', () {
    test('drops the dating intent', () {
      expect(publicIntents(const ['learn', 'date']), const ['learn']);
    });

    test('drops it even when it is the only value', () {
      expect(publicIntents(const ['date']), isEmpty);
    });

    test('keeps learn and meet in order', () {
      expect(publicIntents(const ['learn', 'meet']), const ['learn', 'meet']);
    });

    test('an empty list stays empty', () {
      expect(publicIntents(const []), isEmpty);
    });

    test('unknown values are not passed through', () {
      expect(publicIntents(const ['learn', 'nonsense']), const ['learn']);
    });
  });
}

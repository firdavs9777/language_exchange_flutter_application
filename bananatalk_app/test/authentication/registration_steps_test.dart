import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/register/registration_steps.dart';

/// The profile wizard is where Apple/Google signups are lost.
///
/// Measured on prod 2026-09-14: 301 social accounts sit with an empty profile,
/// and 282 of 298 never came back after day one -- roughly 19% of signups,
/// growing at ~70/month. Both login screens correctly route them here; they
/// just don't finish.
///
/// The server requires only gender, birth year and two distinct languages
/// (controllers/auth.js: "Bio, images, location are optional -- don't block
/// login for them"). The wizard nevertheless made the photo step mandatory,
/// even though 163 of 165 incomplete Google accounts arrive with a provider
/// photo already attached.
void main() {
  // The plan skipping the photo step is only half the funnel fix. Submit had
  // its own, independent `_pickedPhoto == null` guard, so an account whose
  // photo came from the provider was shown no photo step AND then refused at
  // submit -- unable to finish registration at all. The gate must be derived
  // from the plan, not from a second rule that can drift from it.
  // Funnel events are useless if the step NAME can drift from the step the
  // user is actually looking at -- that is the same drift that let the photo
  // step and the submit gate disagree. Both now come from the plan.
  group('stepNameAt names the step actually shown', () {
    test('a full wizard names all four in order', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: false,
      );
      expect(plan.totalSteps, 4);
      expect(
        [for (var i = 0; i < plan.totalSteps; i++) plan.stepNameAt(i)],
        ['personal_info', 'photo', 'languages', 'finish'],
      );
    });

    test('a provider photo shifts the later names down', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: true,
      );
      expect(plan.totalSteps, 3);
      expect(
        [for (var i = 0; i < plan.totalSteps; i++) plan.stepNameAt(i)],
        ['personal_info', 'languages', 'finish'],
      );
    });

    test('an account needing only languages is two steps', () {
      final plan = planRegistrationSteps(
        gender: 'female', birthDate: '1995.07.04',
        nativeLanguage: '', learningLanguage: '', hasPhoto: true,
      );
      expect([for (var i = 0; i < plan.totalSteps; i++) plan.stepNameAt(i)],
          ['languages', 'finish']);
    });

    test('every label has a matching name, so the funnel cannot drift', () {
      for (final hasPhoto in [true, false]) {
        for (final gender in ['', 'male']) {
          final plan = planRegistrationSteps(
            gender: gender, birthDate: gender.isEmpty ? '' : '1995.07.04',
            nativeLanguage: '', learningLanguage: '', hasPhoto: hasPhoto,
          );
          expect(plan.labels.length, plan.totalSteps);
          for (var i = 0; i < plan.totalSteps; i++) {
            expect(plan.stepNameAt(i), isNotEmpty);
          }
        }
      }
    });

    test('an out-of-range index is named rather than crashing analytics', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: false,
      );
      expect(plan.stepNameAt(-1), 'unknown');
      expect(plan.stepNameAt(99), 'unknown');
    });
  });

  group('submit demands a photo only when the plan asked for one', () {
    RegistrationSteps planWith({required bool hasPhoto}) => planRegistrationSteps(
      gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
      hasPhoto: hasPhoto,
    );

    test('provider photo, none picked locally -> submit is NOT blocked', () {
      final plan = planWith(hasPhoto: true);
      expect(plan.needsPhoto, isFalse);
      expect(photoStillRequired(plan: plan, pickedLocally: false), isFalse);
    });

    test('no photo anywhere -> submit IS blocked', () {
      final plan = planWith(hasPhoto: false);
      expect(photoStillRequired(plan: plan, pickedLocally: false), isTrue);
    });

    test('no provider photo but one picked locally -> submit is NOT blocked', () {
      final plan = planWith(hasPhoto: false);
      expect(photoStillRequired(plan: plan, pickedLocally: true), isFalse);
    });

    test('provider photo AND a local pick -> still not blocked', () {
      final plan = planWith(hasPhoto: true);
      expect(photoStillRequired(plan: plan, pickedLocally: true), isFalse);
    });
  });

  group('a social signup is not asked for what it already has', () {
    test('a provider photo removes the photo step', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: true,
      );
      expect(plan.needsPhoto, false);
      expect(plan.labels, ['About you', 'Languages', 'Finish']);
    });

    test('no photo anywhere still asks for one', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: false,
      );
      expect(plan.needsPhoto, true);
      // About you -> Photo -> Languages -> Finish. The two language pages were
      // merged into one; see LanguagesStep.
      expect(plan.totalSteps, 4);
    });

    test('a fully prefilled account goes straight to Finish', () {
      final plan = planRegistrationSteps(
        gender: 'female', birthDate: '1998.04.02',
        nativeLanguage: 'Korean', learningLanguage: 'English',
        hasPhoto: true,
      );
      expect(plan.totalSteps, 1);
      expect(plan.labels, ['Finish']);
    });
  });

  group('the server contract is respected', () {
    test('identical languages are not treated as a filled pair', () {
      // The server refuses native == learning, so the wizard must still ask.
      final plan = planRegistrationSteps(
        gender: 'male', birthDate: '1990.01.01',
        nativeLanguage: 'English', learningLanguage: 'English',
        hasPhoto: true,
      );
      expect(plan.needsLanguages, true);
    });

    test('a missing birth date still asks, even with a gender', () {
      final plan = planRegistrationSteps(
        gender: 'male', birthDate: '',
        nativeLanguage: 'Korean', learningLanguage: 'English',
        hasPhoto: true,
      );
      expect(plan.needsPersonalInfo, true);
    });
  });

  group('step indexes stay in lockstep with the labels', () {
    test('indexes shift when the photo step is dropped', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: true,
      );
      expect(plan.personalInfoStepIndex, 0);
      expect(plan.photoStepIndex, null);
      expect(plan.languageStepIndex, 1);
    });

    test('indexes account for the photo step when it is present', () {
      final plan = planRegistrationSteps(
        gender: '', birthDate: '', nativeLanguage: '', learningLanguage: '',
        hasPhoto: false,
      );
      expect(plan.personalInfoStepIndex, 0);
      expect(plan.photoStepIndex, 1);
      expect(plan.languageStepIndex, 2);
    });

    test('labels and totalSteps never disagree', () {
      for (final hasPhoto in [true, false]) {
        for (final gender in ['', 'male']) {
          for (final native in ['', 'Korean']) {
            final plan = planRegistrationSteps(
              gender: gender,
              birthDate: gender.isEmpty ? '' : '1990.01.01',
              nativeLanguage: native,
              learningLanguage: native.isEmpty ? '' : 'English',
              hasPhoto: hasPhoto,
            );
            expect(plan.labels.length, plan.totalSteps,
                reason: 'hasPhoto=$hasPhoto gender=$gender native=$native');
          }
        }
      }
    });
  });
}

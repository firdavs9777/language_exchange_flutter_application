import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/profile_completion.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_highlights_tab.dart';

import '../helpers/community_fixture.dart';

void main() {
  test('completion is keyed by field, not by a localized label', () {
    // name + native + learning language filled: 3 of 12.
    final c = calculateProfileCompletion(
        profileCompletionFieldsOf(communityFixture()));
    expect(c.completedFields, 3);
    expect(c.totalFields, 12);
    expect(c.percent, 25);
    expect(c.missing.take(3), [
      ProfileCompletionField.picture,
      ProfileCompletionField.gender,
      ProfileCompletionField.bio,
    ]);
    // Every field has a label in every locale; equal labels can no longer
    // merge two fields (the percentage does not depend on the locale).
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final f in ProfileCompletionField.values) {
        expect(f.label(l10n), isNotEmpty, reason: '$locale $f');
      }
    }
  });

  test('counts the union both screens used to count separately', () {
    // The edit screen used to ignore picture and birth year; the profile
    // card used to ignore gender and level.
    final c = calculateProfileCompletion(
        profileCompletionFieldsOf(communityFixture(imageUrls: const ['a.jpg'])));
    expect(c.missing, isNot(contains(ProfileCompletionField.picture)));
    expect(c.missing, contains(ProfileCompletionField.gender));
    expect(c.missing, contains(ProfileCompletionField.languageLevel));
    expect(c.missing, contains(ProfileCompletionField.birthYear));
  });

  test('an unsaved override changes only that field', () {
    final base = profileCompletionFieldsOf(communityFixture());
    final edited = calculateProfileCompletion(
        {...base, ProfileCompletionField.bio: true});
    expect(edited.completedFields,
        calculateProfileCompletion(base).completedFields + 1);
  });

  test('the status line is localized', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(profileCompletionStatus(en, 30), 'Just getting started');
    expect(profileCompletionStatus(en, 60), 'Looking good!');
    expect(profileCompletionStatus(en, 90), 'Almost there!');
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(profileCompletionStatus(ko, 30), ko.justGettingStarted);
    expect(profileCompletionStatus(ko, 30), isNot('Just getting started'));
  });
}

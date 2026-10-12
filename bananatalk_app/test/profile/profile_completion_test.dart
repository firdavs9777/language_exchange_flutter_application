import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_highlights_tab.dart';

import '../helpers/community_fixture.dart';

void main() {
  test('completion is keyed by field, not by a localized label', () {
    // name + native + learning language filled: 3 of 10.
    final c = calculateProfileCompletion(communityFixture());
    expect(c.percentage, 30);
    expect(c.missing, [
      ProfileCompletionField.picture,
      ProfileCompletionField.bio,
      ProfileCompletionField.location,
    ]);
    // Every field has a label in every locale; equal labels can no longer
    // merge two fields (the percentage does not depend on the locale).
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final f in ProfileCompletionField.values) {
        expect(f.label(l10n), isNotEmpty, reason: '$locale $f');
      }
    }
    expect(ProfileCompletionField.values, hasLength(10));
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

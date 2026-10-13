import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_strings.dart';

/// CLDR `one` is not "exactly 1" everywhere: Tagalog `one` covers 2, 3, 5,
/// 7, 8..., Russian 21, 31..., French/Portuguese/Hindi 0. A `one{...}` branch
/// that hardcodes "1" or "only you" shows the wrong number there. Every
/// count other than 1 must render its own number.
void main() {
  const counts = [2, 3, 5, 7, 8, 21, 31, 101];

  for (final locale in AppLocalizations.supportedLocales) {
    test('$locale: gathering and club counts show the number', () {
      final l = lookupAppLocalizations(locale);
      for (final n in counts) {
        // Arabic `two` is the dual ("عضوان", two members): correct without a digit.
        if (locale.languageCode == 'ar' && n == 2) continue;
        final label = '$n';
        for (final (key, text) in [
          ('clubMembers', l.clubMembers(n, label)),
          ('gatheringQuorumNeeded', l.gatheringQuorumNeeded(n, label)),
          ('gatheringHostDecision', gatheringHostDecisionText(l, n, label)),
          ('gatheringCancelConfirm', l.gatheringCancelConfirm(n, label)),
        ]) {
          expect(text, contains(label), reason: '$locale $key($n) -> $text');
        }
      }
    });
  }

  test('exactly one still reads as one', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(gatheringHostDecisionText(en, 1, '1'), startsWith('Only you'));
    final tl = lookupAppLocalizations(const Locale('tl'));
    expect(gatheringHostDecisionText(tl, 1, '1'), startsWith('Ikaw pa lang'));
    expect(gatheringHostDecisionText(tl, 2, '2'), startsWith('2 pa lang kayo'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(gatheringHostDecisionText(ru, 1, '1'), contains('только вы'));
    expect(gatheringHostDecisionText(ru, 21, '21'), contains('идёт только 21 человек'));
  });

  test("'gatheringHostDecisionAlone' is in all 19 locales and translated", () {
    final en = lookupAppLocalizations(const Locale('en')).gatheringHostDecisionAlone;
    expect(AppLocalizations.supportedLocales, hasLength(19));
    for (final locale in AppLocalizations.supportedLocales) {
      final text = lookupAppLocalizations(locale).gatheringHostDecisionAlone;
      expect(text, isNotEmpty, reason: '$locale');
      if (locale.languageCode != 'en') expect(text, isNot(en), reason: '$locale');
    }
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/number_format_locale.dart';

/// 'communityMembersCount' / 'communityPeopleCount' take the raw count (picks
/// the plural form) plus a compact label (what is shown). The plural count
/// is rounded the way the label is, so "1 тыс." from 1001 reads
/// "1 тыс. участников", not "1 тыс. участник".
void main() {
  // intl puts a no-break space between number and unit ("1\u00a0тыс.").
  String plain(String s) => s.replaceAll('\u00a0', ' ');
  String members(String locale, int n) =>
      plain(lookupAppLocalizations(Locale(locale)).communityMembersCount(
        compactPluralCount(n),
        formatCompactNumberForLocaleName(locale, n),
      ));
  String people(String locale, int n) =>
      plain(lookupAppLocalizations(Locale(locale)).communityPeopleCount(
        compactPluralCount(n),
        formatCompactNumberForLocaleName(locale, n),
      ));

  test('ru members agree with the number, compact included', () {
    expect(members('ru', 1), '1 участник');
    expect(members('ru', 3), '3 участника');
    expect(members('ru', 5), '5 участников');
    expect(members('ru', 21), '21 участник');
    expect(members('ru', 1000), '1 тыс. участников');
    expect(members('ru', 1001), '1 тыс. участников');
    expect(members('ru', 1200), '1,2 тыс. участников');
    expect(members('ru', 1203), '1,2 тыс. участников');
    expect(members('ru', 21001), '21 тыс. участников');
    expect(members('ru', 1234567), '1,23 млн участников');
  });

  test('ru people agree with the number, compact included', () {
    expect(people('ru', 1), '1 человек');
    expect(people('ru', 3), '3 человека');
    expect(people('ru', 5), '5 человек');
    expect(people('ru', 21), '21 человек');
    expect(people('ru', 1200), '1,2 тыс. человек');
    expect(people('ru', 1202), '1,2 тыс. человек');
  });

  test('English singular, compact label kept', () {
    expect(members('en', 1), '1 member');
    expect(members('en', 7), '7 members');
    expect(members('en', 1200), '1.2K members');
    expect(people('en', 1), '1 person');
    expect(people('en', 1200), '1.2K people');
  });

  test('other locales show the label and never throw (tg has no intl symbols)', () {
    expect(members('de', 1200), '1200 Mitglieder');
    expect(people('ja', 12345), '1.23万人');
    expect(members('tg', 1200), '1.2K аъзо');
  });

  test('compactPluralCount keeps small counts and rounds like the label', () {
    expect(compactPluralCount(0), 0);
    expect(compactPluralCount(999), 999);
    expect(compactPluralCount(1001), 1000);
    expect(compactPluralCount(1249), 1250);
    expect(compactPluralCount(1299), 1300);
    expect(compactPluralCount(12345), 12300);
    expect(compactPluralCount(1234567), 1230000);
  });
}

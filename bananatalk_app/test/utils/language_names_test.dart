import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_ar.dart';
import 'package:bananatalk_app/l10n/app_localizations_ko.dart';
import 'package:bananatalk_app/utils/language_names.dart';

import '../support/community_fixture.dart';

/// Partners in a non-English UI showed "Speaks Korean" / "Active 2h ago" in
/// English (2026-10-17).
void main() {
  group('LanguageNames', () {
    test('English UI shows the stored name', () {
      expect(LanguageNames.display('Korean', const Locale('en')), 'Korean');
      expect(LanguageNames.display('korean', const Locale('en')), 'Korean');
    });

    test('other UIs show the name in their language', () {
      expect(LanguageNames.display('Korean', const Locale('ar')), 'الكورية');
      expect(LanguageNames.display('English', const Locale('ko')), '영어');
      expect(LanguageNames.display('Chinese (Traditional)', const Locale('ja')), isNot('Chinese (Traditional)'));
      expect(LanguageNames.display('Japanese', const Locale('zh', 'TW')), '日文');
    });

    test('unknown values fall back to the stored text, never a wrong language', () {
      expect(LanguageNames.display('Klingon', const Locale('ar')), 'Klingon');
      expect(LanguageNames.display('', const Locale('ar')), '');
    });
  });

  group('lastActiveLabel', () {
    AppLocalizations ko() => AppLocalizationsKo();
    AppLocalizations ar() => AppLocalizationsAr();

    test('uses the app language, not English', () {
      final twoHours = buildCommunity(
          lastActive: DateTime.now().subtract(const Duration(hours: 2)));
      expect(twoHours.lastActiveLabel(ko()), ko().chatActiveHoursAgo(2));
      expect(twoHours.lastActiveLabel(ar()), ar().chatActiveHoursAgo(2));
      expect(twoHours.lastActiveLabel(ko()), isNot(contains('Active')));
    });

    test('online and unknown', () {
      expect(buildCommunity(isOnline: true).lastActiveLabel(ko()), ko().partnerTagActiveNow);
      expect(buildCommunity().lastActiveLabel(ko()), '');
    });
  });
}

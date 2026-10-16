import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/filter/filter_country_section.dart';
import 'package:bananatalk_app/utils/country_names.dart';
import 'package:bananatalk_app/utils/country_names.g.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import '../helpers/community_fixture.dart';

Widget _wrap(Locale locale, Widget child) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('CountryNames — generated CLDR table', () {
    test('resolves codes in ko / ru / ar / de', () {
      expect(CountryNames.forCode('DE', const Locale('ko')), '독일');
      expect(CountryNames.forCode('KR', const Locale('ko')), '대한민국');
      expect(CountryNames.forCode('US', const Locale('ru')), 'Соединенные Штаты');
      expect(CountryNames.forCode('JP', const Locale('ru')), 'Япония');
      expect(CountryNames.forCode('EG', const Locale('ar')), 'مصر');
      expect(CountryNames.forCode('FR', const Locale('ar')), 'فرنسا');
      expect(CountryNames.forCode('KR', const Locale('de')), 'Südkorea');
      expect(CountryNames.forCode('GB', const Locale('de')), 'Vereinigtes Königreich');
    });

    test('Chinese picks the script; Filipino maps to the tl table', () {
      expect(CountryNames.forCode('DE', const Locale('zh')), '德国');
      expect(CountryNames.forCode('DE', const Locale('zh', 'TW')), '德國');
      expect(
        CountryNames.forCode(
          'DE',
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        '德國',
      );
      expect(
        CountryNames.forCode('KR', const Locale('fil')),
        CountryNames.forCode('KR', const Locale('tl')),
      );
    });

    test('English and unknown values fall back to the stored name', () {
      expect(CountryNames.display('South Korea', const Locale('en')), 'South Korea');
      expect(CountryNames.display('Atlantis', const Locale('ko')), 'Atlantis');
      expect(CountryNames.display('South Korea', const Locale('ko')), '대한민국');
      // Stored ISO codes resolve too.
      expect(CountryNames.display('JP', const Locale('ko')), '일본');
    });

    test('every non-English app locale has a table covering every picker country', () {
      final arbLocales = Directory('lib/l10n')
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('app_') && n.endsWith('.arb'))
          .map((n) => n.substring(4, n.length - 4))
          .where((l) => l != 'en')
          .toSet();
      expect(kCountryNamesByLocale.keys.toSet(), arbLocales);

      final missing = <String>[];
      for (final entry in kCountryNamesByLocale.entries) {
        for (final c in kAllCountries) {
          if (entry.value[c['code']] == null) {
            missing.add('${entry.key}:${c['code']}');
          }
        }
      }
      expect(missing, isEmpty);
    });
  });

  group('PrivacyUtils.getLocationText — localized country', () {
    final user = communityFixture(
      location: Location.fromJson({'city': 'Seoul', 'country': 'South Korea'}),
    );

    test('localizes only the country, and only when a locale is given', () {
      expect(
        PrivacyUtils.getLocationText(user, locale: const Locale('ru')),
        'Seoul, Республика Корея',
      );
      expect(PrivacyUtils.getLocationText(user), 'Seoul, South Korea');
      // The stored value is untouched.
      expect(user.location.country, 'South Korea');
    });
  });

  group('CountryPickerSheet — localized labels', () {
    testWidgets('shows localized names and still selects the English value', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          const Locale('ko'),
          CountryPickerSheet(onSelect: (c) => selected = c),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '독일');
      await tester.pumpAndSettle();
      expect(find.text('독일'), findsWidgets);
      expect(find.text('Germany'), findsNothing);

      await tester.tap(find.widgetWithText(ListTile, '독일'));
      expect(selected, 'Germany');
    });

    testWidgets('search also matches the English name', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          const Locale('ru'),
          CountryPickerSheet(onSelect: (c) => selected = c),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'japan');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Япония'));
      expect(selected, 'Japan');
    });

    testWidgets('selector card shows the stored country localized', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Locale('de'),
          FilterCountrySelector(
            selectedCountry: 'South Korea',
            isDetectingLocation: false,
            onDetectLocation: () {},
            onOpenPicker: () {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Südkorea'), findsOneWidget);
      expect(find.text('South Korea'), findsNothing);
    });
  });
}

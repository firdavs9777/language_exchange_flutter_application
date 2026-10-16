import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/main/community_filter_chips.dart';
import 'package:bananatalk_app/pages/community/tabs/city_tab.dart';

Widget _chips(Locale locale, Map<String, dynamic> filters) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CommunityFilterChips(
          filters: filters,
          onRemove: (_) {},
          onClearAll: () {},
        ),
      ),
    );

void main() {
  testWidgets('gender / online / new chips follow the app language',
      (tester) async {
    await tester.pumpWidget(_chips(const Locale('ru'), {
      'gender': 'male',
      'onlineOnly': true,
      'newUsersOnly': true,
    }));
    await tester.pumpAndSettle();

    expect(find.text('♂ Мужской'), findsOneWidget);
    expect(find.text('🟢 Онлайн'), findsOneWidget);
    expect(find.text('✨ Новые'), findsOneWidget);
    expect(find.textContaining('Male'), findsNothing);
    expect(find.textContaining('Online'), findsNothing);
    expect(find.textContaining('New'), findsNothing);

    await tester.pumpWidget(_chips(const Locale('ru'), {'gender': 'female'}));
    await tester.pumpAndSettle();
    expect(find.text('♀ Женский'), findsOneWidget);
  });

  testWidgets('English chips read as before', (tester) async {
    await tester.pumpWidget(_chips(const Locale('en'), {
      'gender': 'female',
      'onlineOnly': true,
      'newUsersOnly': true,
    }));
    await tester.pumpAndSettle();

    expect(find.text('♀ Female'), findsOneWidget);
    expect(find.text('🟢 Online'), findsOneWidget);
    expect(find.text('✨ New'), findsOneWidget);
  });

  test('City tab list titles are localized', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(
      cityListTitle(ru, worldwide: true, country: null, citySearch: ''),
      '🌍 Весь мир',
    );
    expect(
      cityListTitle(ru, worldwide: false, country: null, citySearch: 'Сеул'),
      'Поиск: Сеул',
    );
    expect(
      cityListTitle(ru, worldwide: false, country: 'Корея', citySearch: 'x'),
      'Корея',
    );

    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      cityListTitle(en, worldwide: true, country: null, citySearch: ''),
      '🌍 Worldwide',
    );
    expect(
      cityListTitle(en, worldwide: false, country: null, citySearch: 'Seoul'),
      'Search: Seoul',
    );
  });
}

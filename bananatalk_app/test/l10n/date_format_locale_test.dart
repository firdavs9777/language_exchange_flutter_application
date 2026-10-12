import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/date_format_locale.dart';

void main() {
  setUpAll(initializeDateFormatting);
  final dt = DateTime(2026, 10, 12, 15, 5);

  test('tg has no intl date symbols and must not throw', () {
    expect(formatDateTimeForLocaleName('tg', dt), isNotEmpty);
  });

  test('every app locale formats without throwing', () {
    for (final l in [
      'ar',
      'de',
      'en',
      'es',
      'fr',
      'hi',
      'id',
      'it',
      'ja',
      'ko',
      'pt',
      'ru',
      'tg',
      'th',
      'tl',
      'tr',
      'vi',
      'zh',
      'zh_TW',
    ]) {
      expect(formatDateTimeForLocaleName(l, dt), isNotEmpty, reason: l);
    }
  });

  group('formatDateForLocale', () {
    const locales = [
      Locale('ar'), Locale('de'), Locale('en'), Locale('es'), Locale('fr'),
      Locale('hi'), Locale('id'), Locale('it'), Locale('ja'), Locale('ko'),
      Locale('pt'), Locale('ru'), Locale('tg'), Locale('th'), Locale('tl'),
      Locale('tr'), Locale('vi'), Locale('zh'), Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];

    Future<String> format(WidgetTester tester, Locale locale) async {
      late String out;
      await tester.pumpWidget(Localizations(
        locale: locale,
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(builder: (context) {
          out = formatDateForLocale(context, dt);
          return const SizedBox();
        }),
      ));
      return out;
    }

    testWidgets('tg has no intl date symbols: falls back to English, no throw', (tester) async {
      expect(await format(tester, const Locale('tg')), 'Oct 12, 2026');
    });

    testWidgets('English renders a medium date', (tester) async {
      expect(await format(tester, const Locale('en')), 'Oct 12, 2026');
    });

    testWidgets('all 19 app locales format a non-empty date containing the year', (tester) async {
      expect(locales, hasLength(19));
      for (final l in locales) {
        final s = await format(tester, l);
        expect(s, isNotEmpty, reason: '$l');
        expect(s, contains(RegExp(r'2026|2569|٢٠٢٦|२०२६')), reason: '$l -> $s');
      }
    });

    testWidgets('a different language is actually localized, not always English', (tester) async {
      expect(await format(tester, const Locale('de')), isNot('Oct 12, 2026'));
    });
  });
}

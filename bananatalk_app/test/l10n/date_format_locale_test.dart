import 'package:intl/date_symbol_data_local.dart';
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
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/time_ago.dart';

void main() {
  final now = DateTime(2026, 10, 12, 12);
  final fiveMinAgo = now.subtract(const Duration(minutes: 5));
  String fmt(Locale l, {bool short = false}) =>
      formatTimeAgo(l, fiveMinAgo, short: short, now: now);

  test('English keeps the long and the compact style', () {
    expect(fmt(const Locale('en')), '5 minutes ago');
    expect(fmt(const Locale('en'), short: true), '5m');
  });

  test('locales timeago has no messages for fall back to English', () {
    expect(fmt(const Locale('tg')), '5 minutes ago');
    expect(fmt(const Locale('tl')), '5 minutes ago');
    expect(timeAgoLocaleKey(const Locale('tg')), 'en');
  });

  test('every other app locale is localized, not English', () {
    const locales = [
      Locale('ar'), Locale('de'), Locale('es'), Locale('fr'), Locale('hi'),
      Locale('id'), Locale('it'), Locale('ja'), Locale('ko'), Locale('pt', 'BR'),
      Locale('ru'), Locale('th'), Locale('tr'), Locale('vi'), Locale('zh', 'CN'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
    ];
    for (final l in locales) {
      final text = fmt(l);
      expect(text, isNotEmpty, reason: '$l');
      expect(text, isNot('5 minutes ago'), reason: '$l renders English');
    }
  });

  test('Simplified and Traditional Chinese map to their own timeago messages', () {
    expect(timeAgoLocaleKey(const Locale('zh', 'CN')), 'zh_cn');
    expect(timeAgoLocaleKey(const Locale('zh', 'TW')), 'zh');
    expect(
      timeAgoLocaleKey(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
      'zh',
    );
    expect(timeAgoLocaleKey(const Locale('pt', 'BR')), 'pt_br');
  });

  test('compact style exists for Spanish; other locales use the long phrase', () {
    expect(fmt(const Locale('es'), short: true), isNot(fmt(const Locale('es'))));
    expect(fmt(const Locale('ja'), short: true), fmt(const Locale('ja')));
  });
}

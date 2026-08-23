import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_drop_providers.dart';

void main() {
  test('Arabic maps to the ar explanations', () {
    expect(dailyDropLocaleTag(const Locale('ar', 'SA')), 'ar');
  });

  test('Simplified Chinese maps to zh-Hans', () {
    expect(dailyDropLocaleTag(const Locale('zh', 'CN')), 'zh-Hans');
  });

  test('Traditional Chinese also maps to zh-Hans, not English', () {
    expect(
      dailyDropLocaleTag(const Locale.fromSubtags(
          languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW')),
      'zh-Hans',
    );
  });

  test('English maps to en', () {
    expect(dailyDropLocaleTag(const Locale('en', 'US')), 'en');
  });

  test('a locale with no authored explanations degrades to en', () {
    for (final code in ['ko', 'ja', 'tg', 'vi', 'tl', 'th']) {
      expect(dailyDropLocaleTag(Locale(code)), 'en');
    }
  });
}

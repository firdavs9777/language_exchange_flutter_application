import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/caption_language.dart';

/// A new moment whose author never touched the language dropdown is filed by
/// its caption's script, else the author's native language — not English
/// (152 of 157 posts were `en`). Mirrors backend lib/captionLanguage.js.
void main() {
  test('the script names the language when it dominates', () {
    expect(CaptionLanguage.fromScript('오늘 날씨 정말 좋네요'), 'ko');
    expect(CaptionLanguage.fromScript('今日はとても暑いです'), 'ja');
    expect(CaptionLanguage.fromScript('今天天气很好'), 'zh');
    expect(CaptionLanguage.fromScript('Привет, как дела?'), 'ru');
    expect(CaptionLanguage.fromScript('مرحبا بالجميع'), 'ar');
    expect(CaptionLanguage.fromScript('สวัสดีครับ'), 'th');
  });

  test('Latin, mostly-Latin and emoji captions decide nothing', () {
    expect(CaptionLanguage.fromScript('Hola a todos'), isNull);
    expect(CaptionLanguage.fromScript('Learning Korean today: 안녕'), isNull);
    expect(CaptionLanguage.fromScript('🔥🔥 123'), isNull);
    expect(CaptionLanguage.fromScript(''), isNull);
  });

  test('falls back to the native language, then English', () {
    expect(CaptionLanguage.defaultFor('Hola a todos', 'Spanish'), 'es');
    expect(CaptionLanguage.defaultFor('Bonjour', 'fr'), 'fr');
    expect(CaptionLanguage.defaultFor('Olá', 'Portuguese (Brazil)'), 'pt');
    expect(CaptionLanguage.defaultFor('Hello', null), 'en');
    expect(CaptionLanguage.defaultFor('Hello', 'Klingon'), 'en');
    expect(CaptionLanguage.defaultFor('오늘', 'English'), 'ko',
        reason: 'the caption wins over the native language');
  });
}

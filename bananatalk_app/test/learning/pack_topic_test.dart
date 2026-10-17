import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/pack_topic.dart';

/// Pack topics are stored "<target-language name> (<English gloss>)"; an
/// Arabic UI showed "규칙과 예절 (Rules and manners)" (2026-10-17).
void main() {
  const ko = '규칙과 예절 (Rules and manners)';

  test('English UI keeps the English gloss', () {
    expect(packTopicForLocale(ko, const Locale('en')), ko);
  });

  test('any other UI shows the topic in the language being learned', () {
    expect(packTopicForLocale(ko, const Locale('ar')), '규칙과 예절');
    expect(packTopicForLocale(ko, const Locale('ko')), '규칙과 예절');
    expect(packTopicForLocale('Números y hora (Numbers and time)', const Locale('ru')),
        'Números y hora');
    expect(packTopicForLocale('الأرقام والوقت (Numbers and time)', const Locale('zh', 'TW')),
        'الأرقام والوقت');
  });

  test('topics without a gloss are untouched', () {
    expect(packTopicForLocale('Work & careers', const Locale('ar')), 'Work & careers');
    expect(packTopicForLocale('数字与时间', const Locale('ar')), '数字与时间');
    // A bracket that is not a trailing Latin gloss stays.
    expect(packTopicForLocale('Travel (旅行) basics', const Locale('ar')), 'Travel (旅行) basics');
  });
}

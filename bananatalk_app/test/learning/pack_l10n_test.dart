import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Every pack string must exist in every locale. A missing key silently falls
/// back to English at runtime, which is invisible in review and obvious to the
/// learner.
void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final packKeys = en.keys
      .where((k) => !k.startsWith('@'))
      // Every prefix the daily pack owns. A key outside this list is silently
      // unguarded, which is how the weeklyReport strings were nearly shipped
      // untranslated.
      .where((k) =>
          k.startsWith('pack') ||
          k.startsWith('mastery') ||
          k.startsWith('placement') ||
          k.startsWith('weeklyReport'))
      .toList();

  test('the pack keys exist in app_en.arb', () {
    expect(packKeys.length, greaterThanOrEqualTo(50));
  });

  test('every pack and mastery key is present in all locales', () {
    final missing = <String, List<String>>{};
    for (final file in Directory('lib/l10n').listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb') || file.path.endsWith('app_en.arb')) continue;
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final gaps = packKeys.where((k) => !arb.containsKey(k)).toList();
      if (gaps.isNotEmpty) {
        missing[file.path.split('/').last] = gaps;
      }
    }
    expect(missing, isEmpty, reason: 'missing translations: $missing');
  });

  test('no translation drops or renames a placeholder', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    final problems = <String>[];
    for (final file in Directory('lib/l10n').listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb') || file.path.endsWith('app_en.arb')) continue;
      final locale = file.path.split('/').last;
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final k in packKeys) {
        final source = en[k] as String;
        final translated = arb[k];
        if (translated is! String) continue;
        final want = placeholder.allMatches(source).map((m) => m.group(1)!).toSet();
        final got = placeholder.allMatches(translated).map((m) => m.group(1)!).toSet();
        if (want.difference(got).isNotEmpty || got.difference(want).isNotEmpty) {
          problems.add('$locale/$k: expected $want, got $got');
        }
      }
    }
    // A renamed or dropped placeholder is a runtime crash, not a fallback.
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('station names are translated, not left in English', () {
    // These are UI labels a learner reads; leaving them as-is would look broken
    // in a fully localized screen. Latin-script locales legitimately share some
    // words, so only the non-Latin ones are asserted.
    const nonLatin = ['app_ar.arb', 'app_ja.arb', 'app_ko.arb', 'app_ru.arb',
      'app_th.arb', 'app_zh.arb', 'app_zh_TW.arb', 'app_hi.arb'];
    for (final name in nonLatin) {
      final arb = jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;
      expect(arb['packStationGrammar'], isNot('Grammar'), reason: '$name left it in English');
      expect(arb['masteryTitle'], isNot('Your progress'), reason: '$name left it in English');
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every guide string must exist in every locale.
///
/// Flutter falls back to the template for a missing key rather than failing,
/// so an untranslated guide ships as silent English inside an otherwise
/// translated app -- and `flutter gen-l10n` only prints a count, which is
/// easy to scroll past. Same shape and the same reason as
/// `call_strings_test.dart`.
///
/// Keys are discovered from the template rather than listed by hand: a
/// hand-written list cannot fail for a key added after it was written, which
/// is exactly the case this test exists to catch.
void main() {
  late List<File> arbs;
  late List<String> guideKeys;

  setUpAll(() {
    arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    final template =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    guideKeys = template.keys
        .where((k) =>
            !k.startsWith('@') &&
            (k.startsWith('guide') || k.startsWith('firstSession')))
        .toList();
  });

  test('the template actually has guide strings to check', () {
    // Guards the discovery above: a renamed prefix would leave guideKeys
    // empty and every assertion below would pass over nothing.
    expect(arbs.length, 19);
    expect(guideKeys.length, greaterThanOrEqualTo(14));
  });

  test('every locale defines every guide string', () {
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in guideKeys) {
        final value = map[key];
        expect(value is String && value.trim().isNotEmpty, isTrue,
            reason: '${file.path} is missing $key — it would silently fall '
                'back to English for every user in that locale');
      }
    }
  });

  test('no locale left the English text in place', () {
    // A copy-paste of the template is worse than a missing key: the missing
    // key is at least countable by gen-l10n.
    final template =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    for (final file in arbs) {
      if (file.path.endsWith('app_en.arb')) continue;
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in guideKeys) {
        // `guideAiStudyCta` and friends are short enough that a genuine
        // translation could coincide, so only the sentences are checked.
        if ((template[key] as String).length < 30) continue;
        expect(map[key], isNot(template[key]),
            reason: '${file.path} $key is still the English string');
      }
    }
  });

  test('plural strings keep their ICU shape in every locale', () {
    // A plural that loses its `=1{} other{}` arms renders as the raw source
    // text on a device -- and only in that locale, which is how it survives
    // to release.
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final value = map['firstSessionMatchesTitle'] as String;
      expect(value.contains('{count, plural,'), isTrue,
          reason: '${file.path} lost the plural wrapper');
      expect(value.contains('=1{'), isTrue,
          reason: '${file.path} lost the singular arm');
      expect(value.contains('other{'), isTrue,
          reason: '${file.path} lost the other arm');
      expect(value.contains('{count}'), isTrue,
          reason: '${file.path} drops the count, so every batch reads the '
              'same regardless of size');
    }
  });

  test('placeholder metadata travels with the plural', () {
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final meta = map['@firstSessionMatchesTitle'];
      expect(meta, isNotNull, reason: '${file.path} has no placeholder block');
      expect((meta as Map)['placeholders'], contains('count'),
          reason: '${file.path} does not declare count');
    }
  });
}

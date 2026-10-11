import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural checks across the generated localizations.
///
/// `flutter gen-l10n` does not fail on these, and it prints nothing.
///
/// A locale that uses a placeholder gen-l10n did not generate a parameter for
/// is emitted as the literal text `null`. That is how Tagalog and Turkish
/// users came to be asked to "Select up to null images" (found 2026-10-11).
///
/// Asserted against the GENERATED Dart rather than against the .arb files.
/// gen-l10n's rules for inferring a placeholder from a locale, from the
/// template value, and from an `@key` metadata block interact in ways that a
/// re-implementation here would get subtly wrong -- and a check that is
/// subtly wrong about this is worse than none, because it produces a list of
/// false positives long enough that the real entry is never read. The
/// generated output is the thing users actually see.
void main() {
  late List<File> generated;

  setUpAll(() {
    generated = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.contains('app_localizations_') && f.path.endsWith('.dart'))
        .toList();
  });

  test('the generated localizations are present to check', () {
    // Without this, a renamed output file makes every assertion below pass
    // over an empty list. 18, not 19: zh_TW is a subclass inside
    // app_localizations_zh.dart rather than a file of its own.
    expect(generated.length, 18);
  });

  test('no generated string renders the literal text "null"', () {
    // Matches a single-quoted Dart string literal containing `null` as a
    // whole word -- `nullable` or `annulla` (Italian "cancel") must not trip.
    final literal = RegExp(r"'[^'\n]*\bnull\b[^'\n]*'");
    final failures = <String>[];
    for (final file in generated) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('=>') && !line.contains('return')) continue;
        final match = literal.firstMatch(line);
        if (match != null) {
          failures.add('${file.path}:${i + 1}  ${match.group(0)}');
        }
      }
    }
    expect(failures, isEmpty,
        reason: 'A locale uses a placeholder with no generated parameter, so '
            'users in that language read the word "null":\n'
            '${failures.join('\n')}');
  });

  test('no locale contains characters from a script it does not use', () {
    // Two slips of mine on 2026-10-11: a Japanese string came out as
    // "새しく始めてください" (Korean 새 for 新), and a Russian one began with a
    // stray "材". Nothing else catches a wrong-script character -- it is
    // valid JSON, valid ICU, and it renders.
    //
    // Checks only for scripts a locale should never contain, so Latin inside
    // any locale (brand names, "EULA", "VIP") is always fine.
    const blocks = <String, String>{
      'CJK': r'[぀-ヿ一-鿿]',
      'Hangul': r'[가-힯]',
      'Thai': r'[฀-๿]',
      'Devanagari': r'[ऀ-ॿ]',
      'Arabic': r'[؀-ۿ]',
      'Cyrillic': r'[Ѐ-ӿ]',
    };
    const allowed = <String, List<String>>{
      'ja': ['CJK'],
      'zh': ['CJK'],
      'zh_TW': ['CJK'],
      'ko': ['Hangul', 'CJK'],
      'th': ['Thai'],
      'hi': ['Devanagari'],
      'ar': ['Arabic'],
      'ru': ['Cyrillic'],
      'tg': ['Cyrillic'],
    };

    final failures = <String>[];
    for (final file in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))) {
      final loc = RegExp(r'app_(.+)\.arb$').firstMatch(file.path)!.group(1)!;
      final ok = allowed[loc] ?? const <String>[];
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      map.forEach((key, value) {
        if (key.startsWith('@') || value is! String) return;
        blocks.forEach((name, pattern) {
          if (ok.contains(name)) return;
          final hit = RegExp(pattern).firstMatch(value);
          if (hit != null) {
            failures.add('app_$loc.arb $key has $name "${hit.group(0)}" in '
                '"${value.length > 48 ? '${value.substring(0, 48)}…' : value}"');
          }
        });
      });
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('every .arb is valid JSON and non-empty', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'));
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(map.isNotEmpty, isTrue, reason: '${file.path} is empty');
    }
  });
}

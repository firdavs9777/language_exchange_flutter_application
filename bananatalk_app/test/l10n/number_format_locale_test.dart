import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/number_format_locale.dart';

void main() {
  const appLocales = [
    'ar', 'de', 'en', 'es', 'fr', 'hi', 'id', 'it', 'ja', 'ko',
    'pt', 'ru', 'tg', 'th', 'tl', 'tr', 'vi', 'zh', 'zh_TW',
  ];

  test('intl still has no number symbols for tg (why the fallback exists)', () {
    expect(() => NumberFormat.compact(locale: 'tg'), throwsArgumentError);
  });

  test('tg compact numbers fall back to English, no throw', () {
    expect(formatCompactNumberForLocaleName('tg', 1200), '1.2K');
    expect(formatCompactNumberForLocaleName('tg', 7), '7');
  });

  test('every app locale formats a compact number without throwing', () {
    expect(appLocales, hasLength(19));
    for (final l in appLocales) {
      expect(formatCompactNumberForLocaleName(l, 1200), isNotEmpty, reason: l);
    }
  });

  test('the four count strings render for tg (they crashed before)', () {
    final tg = lookupAppLocalizations(const Locale('tg'));
    final label = formatCompactNumberForLocaleName('tg', 3);
    expect(tg.clubMembers(3, label), contains('3'));
    expect(tg.gatheringQuorumNeeded(3, label), contains('3'));
    expect(tg.gatheringHostDecision(3, label), contains('3'));
    expect(tg.gatheringCancelConfirm(3, label), contains('3'));
  });

  test('no generated localization formats numbers itself (tg has no symbols)', () {
    // A `"format"` on a num placeholder makes gen-l10n emit
    // NumberFormat.x(locale: localeName), which throws for tg. Pass a
    // String label from lib/utils/number_format_locale.dart instead.
    final offenders = <String>[];
    for (final f in Directory('lib/l10n').listSync()) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (src.contains('NumberFormat')) offenders.add(f.path);
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no NumberFormat in lib/ takes a runtime locale outside the safe helper', () {
    final call = RegExp(r'NumberFormat(?:\.\w+)?\(([^)]*)\)');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('number_format_locale.dart') || f.path.contains('/l10n/')) continue;
      final src = f.readAsStringSync();
      for (final m in call.allMatches(src)) {
        final args = m.group(1)!;
        if (!args.contains('locale')) continue;
        if (RegExp(r"""locale:\s*'[^']*'""").hasMatch(args)) continue; // literal locale
        offenders.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

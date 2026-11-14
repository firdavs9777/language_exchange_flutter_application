import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// The "my words and mistakes" key set, listed explicitly so the keys-covered
/// guard in hardcoded_strings_test.dart sees them and a dropped key fails here.
const _keys = [
  'myWordsTitle',
  'myWordsCountWords',
  'myWordsCountMistakes',
  'myWordsCardBoth',
  'myWordsCardOne',
  'myWordsCardEmpty',
  'myWordsFromChats',
  'myWordsMistakes',
  'myWordsToReview',
  'myWordsDueCount',
  'myWordsKeep',
  'myWordsDismiss',
  'myWordsGotIt',
  'myWordsGotItProgress',
  'myWordsSayIt',
  'myWordsReview',
  'myWordsEmpty',
  'myWordsActionFailed',
  'myWordsYouWrote',
  'myWordsCorrection',
  'studyDoorTalk',
  'studyDoorTalkSubtitle',
  'studyDoorRoleplay',
  'studyDoorMore',
];

/// Same word as English in that language (cognates and loanwords).
const _sameAsEnglish = {
  'app_fr.arb': {'myWordsCorrection'},
  'app_tl.arb': {'studyDoorRoleplay'},
};

void main() {
  final arbs = <String, Map<String, dynamic>>{
    for (final f in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb')))
      f.uri.pathSegments.last:
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  };

  test('every key is in all 19 locales and translated', () {
    expect(arbs, hasLength(19));
    final en = arbs['app_en.arb']!;
    final problems = <String>[];
    for (final key in _keys) {
      arbs.forEach((file, map) {
        final v = map[key];
        if (v is! String || v.trim().isEmpty) {
          problems.add('$file: $key missing');
        } else if (file != 'app_en.arb' &&
            v == en[key] &&
            !(_sameAsEnglish[file]?.contains(key) ?? false)) {
          problems.add('$file: $key left in English');
        }
      });
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('counts show their own number in every locale', () {
    // Arabic `two` and the dual are correct without a digit.
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final n in [2, 3, 5, 21, 101]) {
        if (locale.languageCode == 'ar' && n == 2) continue;
        for (final (key, text) in [
          ('myWordsCountWords', l.myWordsCountWords(n)),
          ('myWordsCountMistakes', l.myWordsCountMistakes(n)),
          ('myWordsDueCount', l.myWordsDueCount(n)),
        ]) {
          expect(text, contains('$n'), reason: '$locale $key($n) -> $text');
        }
      }
    }
  });

  test('English and Russian read right', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.myWordsCountWords(1), '1 word');
    expect(en.myWordsCountWords(4), '4 words');
    expect(en.myWordsDueCount(1), '1 word is ready');
    expect(en.myWordsCardBoth('3 words', '1 mistake'),
        '3 words, 1 mistake to look at');
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.myWordsCountWords(1), '1 слово');
    expect(ru.myWordsCountWords(2), '2 слова');
    expect(ru.myWordsCountWords(5), '5 слов');
    expect(ru.myWordsCountWords(21), '21 слово');
  });
}

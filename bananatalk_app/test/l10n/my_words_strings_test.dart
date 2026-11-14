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

  test('Arabic counts use their own plural forms', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.myWordsCountWords(1), 'كلمة واحدة');
    expect(ar.myWordsCountWords(2), 'كلمتان');
    expect(ar.myWordsCountWords(3), '3 كلمات');
    expect(ar.myWordsCountWords(11), '11 كلمة');
    expect(ar.myWordsCountWords(100), '100 كلمة');
    expect(ar.myWordsCountMistakes(2), 'خطآن');
    expect(ar.myWordsCountMistakes(5), '5 أخطاء');
    expect(ar.myWordsCountMistakes(11), '11 خطأً');
    expect(ar.myWordsDueCount(2), 'كلمتان جاهزتان');
    expect(ar.myWordsDueCount(11), '11 كلمة جاهزة');
  });

  test('wording fixes: Dismiss means hide, Thai joins the two parts, and the '
      'failure line fits Dismiss and Got it too', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.myWordsActionFailed, "That didn't work. Try again.");
    expect(lookupAppLocalizations(const Locale('ja')).myWordsDismiss, '非表示');
    final th = lookupAppLocalizations(const Locale('th'));
    expect(th.myWordsDismiss, 'ซ่อน');
    expect(th.myWordsCardBoth('A', 'B'), 'A และ B ที่ต้องดู');
    // No locale keeps the old "didn't save" meaning in its own words.
    for (final f in arbs.keys) {
      final v = arbs[f]!['myWordsActionFailed'] as String;
      for (final old in ['save', 'сохран', 'guard', 'enregistr', 'speicher',
          'salv', 'simpan', 'kayded', 'lưu', '保存', '儲存', '저장', 'บันทึก',
          'सहेज', 'حفظ', 'захира', 'nai-save']) {
        expect(v.toLowerCase(), isNot(contains(old)), reason: '$f: $v');
      }
    }
  });
}

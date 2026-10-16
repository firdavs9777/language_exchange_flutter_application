import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Russian nouns agree with the number: "1 просмотр / 2 просмотра /
/// 5 просмотров / 21 просмотр". Counts 1, 2, 5, 21 hit one / few / many /
/// one-again (21 is CLDR `one`, not `many`).
void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));

  void forms(String Function(int) f, List<String> expected) {
    const counts = [1, 2, 5, 21];
    for (var i = 0; i < counts.length; i++) {
      expect(f(counts[i]), expected[i], reason: 'n=${counts[i]}');
    }
  }

  test('nominative counts', () {
    forms(ru.views, ['1 просмотр', '2 просмотра', '5 просмотров', '21 просмотр']);
    forms(ru.xComments, [
      '1 комментарий',
      '2 комментария',
      '5 комментариев',
      '21 комментарий',
    ]);
    forms(ru.nPeople, ['1 человек', '2 человека', '5 человек', '21 человек']);
    forms(ru.gatheringDuration, ['1 минута', '2 минуты', '5 минут', '21 минута']);
  });

  test('accusative and dative counts', () {
    forms(ru.minutesAgo, [
      '1 минуту назад',
      '2 минуты назад',
      '5 минут назад',
      '21 минуту назад',
    ]);
    forms(ru.hoursAgo, ['1 час назад', '2 часа назад', '5 часов назад', '21 час назад']);
    forms(ru.likedByXPeople, [
      'Понравилось 1 человеку',
      'Понравилось 2 людям',
      'Понравилось 5 людям',
      'Понравилось 21 человеку',
    ]);
  });

  test('genitive after "до" / "не более"', () {
    forms(ru.storyMaxHashtags, [
      'Можно добавить до 1 хештега',
      'Можно добавить до 2 хештегов',
      'Можно добавить до 5 хештегов',
      'Можно добавить до 21 хештега',
    ]);
    forms(ru.birthdateMinAgeError, [
      'Вам должно быть не менее 1 года.',
      'Вам должно быть не менее 2 лет.',
      'Вам должно быть не менее 5 лет.',
      'Вам должно быть не менее 21 года.',
    ]);
  });

  test('verb agrees too', () {
    forms(ru.boostSeenBy, [
      'Пока вас увидел 1 человек',
      'Пока вас увидели 2 человека',
      'Пока вас увидели 5 человек',
      'Пока вас увидел 21 человек',
    ]);
  });

  test('two counts in one message', () {
    expect(ru.learnWordsExercises(21, 2), '21 слово · 2 упражнения');
    expect(ru.learnWordsExercises(5, 1), '5 слов · 1 упражнение');
    expect(ru.masteryAccuracyCaption(80, 3), '80% за 3 занятия');
  });

  test('every locale still renders the number for retyped keys', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final n in [1, 2, 5, 21]) {
        for (final text in [
          l.views(n),
          l.minutesAgo(n),
          l.hoursAgo(n),
          l.usersCount(n),
          l.usersWorldwide(n),
          l.chatDailyLimitBody(n),
        ]) {
          expect(text, contains('$n'), reason: '$locale $n -> $text');
        }
      }
    }
  });
}

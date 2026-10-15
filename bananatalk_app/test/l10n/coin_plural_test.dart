import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Coin amounts agree with the number: Russian "1 монету / 3 монеты /
/// 5 монет / 21 монету", English "1 coin / 2 coins".
void main() {
  test('Russian coin amounts use one / few / many forms', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.referralClaimed(1), 'Вы получили 1 монету!');
    expect(ru.referralClaimed(3), 'Вы получили 3 монеты!');
    expect(ru.referralClaimed(5), 'Вы получили 5 монет!');
    expect(ru.referralClaimed(21), 'Вы получили 21 монету!');
    expect(ru.boostCostLine(1), 'Стоимость: 1 монета');
    expect(ru.boostBalanceLine(12), 'Ваш баланс: 12 монет');
    expect(ru.wavesMaskedBody(2), contains('2 монеты'));
  });

  test('English and every locale keep the number in coin strings', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.referralClaimed(1), 'You earned 1 coin!');
    expect(en.referralClaimed(50), 'You earned 50 coins!');
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final n in [1, 2, 5, 21]) {
        for (final text in [
          l.referralClaimed(n),
          l.extraMatchesCta(n),
          l.boostCostLine(n),
          l.boostBalanceLine(n),
          l.wavesMaskedBody(n),
          l.visitorsMaskedBody(n),
          l.chatUnlockPremiumWallpapers(n),
        ]) {
          expect(text, contains('$n'), reason: '$locale $n -> $text');
        }
      }
    }
  });
}

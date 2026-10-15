import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/message/inline_translate_error.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('a translation means no error', () {
    expect(
      inlineTranslateErrorText(l10n, hasTranslation: true, limitReached: false),
      isNull,
    );
  });

  test('the cap shows the limit message when no unlock was offered', () {
    expect(
      inlineTranslateErrorText(l10n, hasTranslation: false, limitReached: true),
      l10n.chatTranslationLimitReached,
    );
  });

  test('declining the coin unlock sheet adds no second message', () {
    expect(
      inlineTranslateErrorText(
        l10n,
        hasTranslation: false,
        limitReached: true,
        unlockDeclined: true,
      ),
      isNull,
    );
  });

  test('any other failure or an empty translation says translation failed', () {
    expect(
      inlineTranslateErrorText(l10n, hasTranslation: false, limitReached: false),
      l10n.translationFailed,
    );
  });
}

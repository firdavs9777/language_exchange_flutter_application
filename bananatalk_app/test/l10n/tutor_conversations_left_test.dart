import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/widgets/tutor/tutor_quota_indicator.dart';

/// 'tutorConversationsLeft': the chat allowance counts conversations, so the
/// tutor's pill says so, with each language's plural forms.
void main() {
  test('English: one conversation, many conversations', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.tutorConversationsLeft(1), '1 conversation left today');
    expect(en.tutorConversationsLeft(0), '0 conversations left today');
    expect(en.tutorConversationsLeft(3), '3 conversations left today');
  });

  test('Russian picks one / few / many', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.tutorConversationsLeft(1), 'Сегодня остался 1 разговор');
    expect(ru.tutorConversationsLeft(21), 'Сегодня остался 21 разговор');
    expect(ru.tutorConversationsLeft(3), 'Сегодня осталось 3 разговора');
    expect(ru.tutorConversationsLeft(5), 'Сегодня осталось 5 разговоров');
  });

  test('every locale shows the number and is translated', () {
    final en = lookupAppLocalizations(const Locale('en'));
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final n in [0, 1, 2, 3, 5, 11, 21, 101]) {
        final text = l.tutorConversationsLeft(n);
        if (locale.languageCode != 'en') {
          expect(text, isNot(en.tutorConversationsLeft(n)), reason: '$locale');
        }
        // Arabic says zero, one and two in words (dual).
        if (locale.languageCode == 'ar' && n <= 2) continue;
        expect(text, contains('$n'), reason: '$locale($n) -> $text');
      }
    }
  });

  group('TutorQuotaIndicator', () {
    Future<void> pump(WidgetTester tester, String key) async {
      const info = TutorQuotaInfo(
        used: 4,
        cap: 5,
        remaining: 1,
        resetAt: null,
        unlimited: false,
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          tutorQuotaProvider.overrideWithValue(
            const TutorQuotaState(chat: info, roleplay: info),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TutorQuotaIndicator(featureKey: key)),
        ),
      ));
    }

    testWidgets('the chat pill counts conversations', (tester) async {
      await pump(tester, 'chat');
      expect(find.text('1 conversation left today'), findsOneWidget);
      expect(find.text('1 left today'), findsNothing);
    });

    testWidgets('other chips keep their wording', (tester) async {
      await pump(tester, 'roleplay');
      expect(find.text('1 left today'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

void main() {
  group('dotsForLevel', () {
    test('maps each CEFR band to a dot count', () {
      expect(dotsForLevel('A1'), 1);
      expect(dotsForLevel('A2'), 1);
      expect(dotsForLevel('B1'), 2);
      expect(dotsForLevel('B2'), 2);
      expect(dotsForLevel('C1'), 3);
      expect(dotsForLevel('C2'), 3);
    });

    test('is case insensitive', () {
      expect(dotsForLevel('b1'), 2);
    });

    // A missing level must read as ABSENT, never as "beginner" -- one filled
    // dot would be a claim the data does not make.
    test('returns null for a missing or unrecognised level', () {
      expect(dotsForLevel(null), isNull);
      expect(dotsForLevel(''), isNull);
      expect(dotsForLevel('fluent'), isNull);
    });
  });

  testWidgets('renders both language codes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LanguageExchangePill(
          nativeLanguage: 'Korean',
          learningLanguage: 'English',
          languageLevel: 'B1',
        ),
      ),
    ));

    expect(find.text('KO'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });
}

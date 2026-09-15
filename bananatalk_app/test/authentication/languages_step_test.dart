import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/languages_step.dart';

/// The two language steps are the last two screens of the signup wizard, and
/// the wizard is where Apple/Google signups are lost (301 blank accounts on
/// prod, 282 of 298 never returning). Merging them into one screen removes a
/// page from the funnel.
///
/// The guard that must survive the merge: native and learning can never be the
/// same language. The backend refuses that pair with PROFILE_INCOMPLETE, and a
/// picker that allowed it is what produced the earlier stuck cohort.
Language _lang(String code, String name, String nativeName) =>
    Language(id: code, code: code, name: name, nativeName: nativeName);

// Distinct nativeName, as real data has: the card renders both, so reusing
// `name` for both would make "one match" impossible to assert.
final _korean = _lang('ko', 'Korean', '한국어');
final _english = _lang('en', 'English', 'English (native)');
final _french = _lang('fr', 'French', 'Français');

Widget _host({
  Language? native,
  Language? learning,
  String? nativeLevel,
  String? learningLevel,
  ValueChanged<Language>? onNative,
  ValueChanged<Language>? onLearning,
  ValueChanged<String>? onNativeLevel,
  ValueChanged<String>? onLearningLevel,
  VoidCallback? onSwap,
  VoidCallback? onNext,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LanguagesStep(
          nativeLanguage: native,
          learningLanguage: learning,
          nativeLevel: nativeLevel,
          learningLevel: learningLevel,
          isLoadingLanguages: false,
          allLanguages: [_korean, _english, _french],
          onNativeSelected: onNative ?? (_) {},
          onLearningSelected: onLearning ?? (_) {},
          onNativeLevelChanged: onNativeLevel ?? (_) {},
          onLearningLevelChanged: onLearningLevel ?? (_) {},
          onSwap: onSwap ?? () {},
          onNext: onNext ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('both sides are on one screen', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.byKey(const Key('languages-native-card')), findsOneWidget);
    expect(find.byKey(const Key('languages-learning-card')), findsOneWidget);
  });

  testWidgets('each card shows the language chosen for its own side',
      (tester) async {
    await tester.pumpWidget(_host(native: _korean, learning: _english));
    // Scoped to the cards: the names also appear in the level labels
    // ("Your level in Korean"), which is not what this is asserting.
    expect(
      find.descendant(
        of: find.byKey(const Key('languages-native-card')),
        matching: find.text('Korean'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('languages-learning-card')),
        matching: find.text('English'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('levels appear only for a side that has a language',
      (tester) async {
    await tester.pumpWidget(_host(native: _korean));
    expect(find.byKey(const Key('native-level-A2')), findsOneWidget);
    expect(find.byKey(const Key('learning-level-A2')), findsNothing);
  });

  testWidgets('picking a level reports it for the right side', (tester) async {
    String? got;
    await tester.pumpWidget(
      _host(native: _korean, onNativeLevel: (l) => got = l),
    );
    await tester.tap(find.byKey(const Key('native-level-B1')));
    await tester.pump();
    expect(got, 'B1');
  });

  testWidgets('the picker excludes the language chosen on the other side',
      (tester) async {
    await tester.pumpWidget(_host(native: _korean, learning: _english));

    // The learning card behind the modal still renders "English", so count
    // occurrences rather than asserting absence: the sheet adding a second one
    // is exactly the bug this guards against.
    final englishBefore = find.text('English').evaluate().length;
    final frenchBefore = find.text('French').evaluate().length;

    await tester.tap(find.byKey(const Key('languages-native-card')));
    await tester.pumpAndSettle();

    expect(find.text('French').evaluate().length, greaterThan(frenchBefore),
        reason: 'the sheet should offer languages that are still free');
    expect(find.text('English').evaluate().length, englishBefore,
        reason: 'English is taken by the other side and must not be offered');
  });

  testWidgets('swap is offered only once both sides are chosen',
      (tester) async {
    await tester.pumpWidget(_host(native: _korean));
    expect(find.byKey(const Key('languages-swap')), findsNothing);

    await tester.pumpWidget(_host(native: _korean, learning: _english));
    expect(find.byKey(const Key('languages-swap')), findsOneWidget);
  });

  testWidgets('tapping swap asks the parent to exchange the pair',
      (tester) async {
    var swaps = 0;
    await tester.pumpWidget(
      _host(native: _korean, learning: _english, onSwap: () => swaps++),
    );
    await tester.tap(find.byKey(const Key('languages-swap')));
    await tester.pump();
    expect(swaps, 1);
  });

  testWidgets('continue reaches the parent, which owns validation',
      (tester) async {
    var next = 0;
    await tester.pumpWidget(_host(onNext: () => next++));
    await tester.tap(find.byKey(const Key('languages-continue')));
    await tester.pump();
    expect(next, 1);
  });
}

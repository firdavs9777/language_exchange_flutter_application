import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';
import 'package:bananatalk_app/services/review_prompt_service.dart';

class _FakeReviewer implements AppReviewer {
  int requests = 0;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> requestReview() async => requests++;
}

DailyPack _pack() => DailyPack(
      needsLanguage: false,
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 1,
      theme: const PackTheme(id: 'p1', topic: 'Work', level: 'intermediate'),
      stations: [
        const PackStation(
          kind: 'grammar',
          status: StationStatus.todo,
          payload: GrammarPayload(
            itemId: 'g1',
            unit: 1,
            section: 'Present',
            title: 'am / is / are',
            explanation: 'Match the verb to the subject.',
            examples: ['I am here.'],
            checks: [
              PackCheck(prompt: 'She ___ my sister.', options: ['am', 'is', 'are'])
            ],
          ),
        ),
      ],
    );

void main() {
  late _FakeReviewer reviewer;
  late List<String> shown;
  late bool budget;

  // Stamped long ago, so the install fallback for the signup date passes.
  final firstSeen = DateTime.now().subtract(const Duration(days: 30));

  setUp(() {
    SharedPreferences.setMockInitialValues({
      reviewPromptFirstSeenPrefsKey: firstSeen.millisecondsSinceEpoch,
    });
    ReviewPromptService.debugReset();
    reviewer = _FakeReviewer();
    shown = [];
    budget = true;
  });

  ReviewPromptService service() => ReviewPromptService(
        reviewer: reviewer,
        isInCall: () => false,
        tryConsumeBudget: () {
          if (!budget) return false;
          budget = false;
          return true;
        },
        onShown: shown.add,
      );

  Future<void> finishPack(WidgetTester tester, StationResult result) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyPackFlow(
        pack: _pack(),
        reviewPrompt: service(),
        submit: (station, {answers = const [], reviews = const [], text = ''}) async =>
            result,
      ),
    ));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-continue')));
    await tester.pumpAndSettle();
  }

  testWidgets('a finished daily pack asks for a review exactly once',
      (tester) async {
    await finishPack(
      tester,
      const StationResult(score: 1, total: 1, streak: 3, packComplete: true),
    );
    expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
    expect(reviewer.requests, 1);
    expect(shown, ['daily_pack']);
    // Rebuilds of the completion screen do not ask again.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(reviewer.requests, 1);
  });

  testWidgets('a 7-day streak reports the streak trigger', (tester) async {
    await finishPack(
      tester,
      const StationResult(score: 1, total: 1, streak: 7, packComplete: true),
    );
    expect(reviewer.requests, 1);
    expect(shown, ['streak_7']);
  });

  testWidgets('a station that does not finish the pack never asks',
      (tester) async {
    await finishPack(
      tester,
      const StationResult(score: 1, total: 1, packComplete: false),
    );
    expect(reviewer.requests, 0);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/widgets/story/story_correction_sticker_widget.dart';
import 'package:bananatalk_app/widgets/story/story_quiz_sticker_widget.dart';
import 'package:bananatalk_app/widgets/story/story_word_sticker_widget.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  final app = MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [Positioned(left: 0, right: 0, bottom: 100, child: child)],
      ),
    ),
  );
  return app;
}

Future<void> _small(WidgetTester t) async {
  t.view.physicalSize = const Size(320, 480);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

const _sticker = StoryCorrectionSticker(sentence: 'I goed to school');

StoryQuizSticker _quiz({int? correct, int? answer}) => StoryQuizSticker(
  question: 'Pick one',
  options: [
    StoryQuizOption(
      index: 0,
      text: 'went',
      count: correct == null ? null : 3,
      percentage: correct == null ? null : 75,
    ),
    StoryQuizOption(
      index: 1,
      text: 'goed',
      count: correct == null ? null : 1,
      percentage: correct == null ? null : 25,
    ),
  ],
  correctIndex: correct,
  userAnswerIndex: answer,
  hasAnswered: answer != null,
  totalAnswers: correct == null ? 0 : 4,
);

void main() {
  group('correction sticker', () {
    testWidgets('shows the sentence and Correct this; the field opens on tap', (
      t,
    ) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker,
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
        ),
      );
      expect(find.text('I goed to school'), findsOneWidget);
      expect(find.text('Correct this'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Correct this'));
      await t.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('field is capped at 500 characters', (t) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker,
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
        ),
      );
      await t.tap(find.text('Correct this'));
      await t.pump();
      expect(t.widget<TextField>(find.byType(TextField)).maxLength, 500);
    });

    testWidgets('focus pauses playback, sending resumes it', (t) async {
      final calls = <bool>[];
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker,
            onInteracting: calls.add,
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
        ),
      );
      await t.tap(find.text('Correct this'));
      await t.pump();
      await t.tap(find.byType(TextField));
      await t.pump();
      expect(calls, [true]);
      await t.enterText(find.byType(TextField), 'I went to school');
      await t.tap(find.byKey(const Key('correction-send')));
      await t.pump();
      expect(calls, [true, false]);
    });

    testWidgets(
      'send is disabled while a request is in flight, one call only',
      (t) async {
        var sends = 0;
        final done = Completer<CorrectionResult>();
        await t.pumpWidget(
          _host(
            StoryCorrectionStickerWidget(
              sticker: _sticker,
              onSubmit: (_) {
                sends++;
                return done.future;
              },
            ),
          ),
        );
        await t.tap(find.text('Correct this'));
        await t.pump();
        await t.enterText(find.byType(TextField), 'I went');
        await t.tap(find.byKey(const Key('correction-send')));
        await t.pump();
        await t.tap(
          find.byKey(const Key('correction-send')),
          warnIfMissed: false,
        );
        await t.pump();
        expect(sends, 1);
        done.complete(
          const CorrectionResult(outcome: CorrectionOutcome.failure),
        );
        await t.pump();
      },
    );

    testWidgets('a failed send keeps the field and the typed text', (t) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker,
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.blocked),
          ),
        ),
      );
      await t.tap(find.text('Correct this'));
      await t.pump();
      await t.enterText(find.byType(TextField), 'I went');
      await t.tap(find.byKey(const Key('correction-send')));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('I went'), findsOneWidget);
    });

    testWidgets('empty text cannot be sent', (t) async {
      var sends = 0;
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker,
            onSubmit: (_) async {
              sends++;
              return const CorrectionResult(outcome: CorrectionOutcome.success);
            },
          ),
        ),
      );
      await t.tap(find.text('Correct this'));
      await t.pump();
      await t.enterText(find.byType(TextField), '   ');
      await t.tap(
        find.byKey(const Key('correction-send')),
        warnIfMissed: false,
      );
      await t.pump();
      expect(sends, 0);
    });

    testWidgets('sent state', (t) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker.copyWith(hasCorrected: true),
            sent: true,
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
        ),
      );
      expect(find.text('Correction sent'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Correct this'), findsNothing);
    });

    testWidgets('already corrected state hides the field', (t) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker.copyWith(hasCorrected: true),
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
        ),
      );
      expect(find.text('You already corrected this'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('replies disabled or read-only: sentence only, no action', (
      t,
    ) async {
      for (final readOnly in [true, false]) {
        await t.pumpWidget(
          _host(
            StoryCorrectionStickerWidget(
              sticker: _sticker,
              readOnly: readOnly,
              allowReplies: readOnly,
              onSubmit: (_) async =>
                  const CorrectionResult(outcome: CorrectionOutcome.success),
            ),
          ),
        );
        expect(find.text('I goed to school'), findsOneWidget);
        expect(find.text('Correct this'), findsNothing);
      }
    });

    testWidgets('owner sees the count and no field', (t) async {
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: _sticker.copyWith(correctionCount: 3),
            isOwner: true,
          ),
        ),
      );
      expect(find.text('3 corrections'), findsOneWidget);
      expect(find.text('Correct this'), findsNothing);
    });

    testWidgets('320x480 and RTL do not overflow (field open)', (t) async {
      await _small(t);
      await t.pumpWidget(
        _host(
          StoryCorrectionStickerWidget(
            sticker: StoryCorrectionSticker(sentence: 'long ' * 40),
            onSubmit: (_) async =>
                const CorrectionResult(outcome: CorrectionOutcome.success),
          ),
          locale: const Locale('ar'),
        ),
      );
      await t.tap(find.byType(OutlinedButton).first);
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('quiz sticker', () {
    testWidgets('before answering: no percentages, no correct mark', (t) async {
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(quiz: _quiz(), onAnswer: (_) async => true),
        ),
      );
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('went'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('tap answers once and an optimistic pick is shown', (t) async {
      final calls = <int>[];
      final done = Completer<bool>();
      final interacting = <bool>[];
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(
            quiz: _quiz(),
            onInteracting: interacting.add,
            onAnswer: (i) {
              calls.add(i);
              return done.future;
            },
          ),
        ),
      );
      await t.tap(find.text('goed'));
      await t.pump();
      await t.tap(find.text('went'));
      await t.pump();
      expect(calls, [1], reason: 'one answer at a time');
      expect(find.byKey(const Key('quiz-pending-1')), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      done.complete(true);
      await t.pump();
      expect(interacting, [true, false]);
    });

    testWidgets('failure rolls the selection back and options work again', (
      t,
    ) async {
      final calls = <int>[];
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(
            quiz: _quiz(),
            onAnswer: (i) async {
              calls.add(i);
              return false;
            },
          ),
        ),
      );
      await t.tap(find.text('goed'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('quiz-pending-1')), findsNothing);
      await t.tap(find.text('went'));
      await t.pumpAndSettle();
      expect(calls, [1, 0]);
    });

    testWidgets('answered: percentages, correct mark and the verdict', (
      t,
    ) async {
      await t.pumpWidget(
        _host(StoryQuizStickerWidget(quiz: _quiz(correct: 0, answer: 1))),
      );
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.byKey(const Key('quiz-correct-0')), findsOneWidget);
      await t.pumpWidget(
        _host(StoryQuizStickerWidget(quiz: _quiz(correct: 0, answer: 0))),
      );
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('an answered quiz cannot be answered again', (t) async {
      var calls = 0;
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(
            quiz: _quiz(correct: 0, answer: 1),
            onAnswer: (_) async {
              calls++;
              return true;
            },
          ),
        ),
      );
      await t.tap(find.text('went'));
      await t.pump();
      expect(calls, 0);
    });

    testWidgets('owner sees results although hasAnswered is false', (t) async {
      await t.pumpWidget(
        _host(StoryQuizStickerWidget(quiz: _quiz(correct: 0), isOwner: true)),
      );
      expect(find.text('75%'), findsOneWidget);
      expect(find.byKey(const Key('quiz-correct-0')), findsOneWidget);
      expect(find.text('Not quite'), findsNothing);
      expect(find.text('Correct!'), findsNothing);
    });

    testWidgets('read-only: options are not tappable', (t) async {
      var calls = 0;
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(
            quiz: _quiz(),
            readOnly: true,
            onAnswer: (_) async {
              calls++;
              return true;
            },
          ),
        ),
      );
      await t.tap(find.text('went'));
      await t.pump();
      expect(calls, 0);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('320x480 and RTL do not overflow', (t) async {
      await _small(t);
      await t.pumpWidget(
        _host(
          StoryQuizStickerWidget(
            quiz: StoryQuizSticker(
              question: 'A very long question ' * 6,
              options: [
                for (var i = 0; i < 4; i++)
                  StoryQuizOption(
                    index: i,
                    text: 'An option that is rather long number $i',
                    count: 1,
                    percentage: 25,
                  ),
              ],
              correctIndex: 2,
              userAnswerIndex: 1,
              hasAnswered: true,
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  group('word sticker', () {
    const word = StoryWordSticker(
      word: 'serendipity',
      meaning: 'a happy accident',
      example: 'It was serendipity.',
      language: 'en',
    );

    testWidgets('shows word, meaning, example and Save word', (t) async {
      await t.pumpWidget(
        _host(StoryWordStickerWidget(sticker: word, onSave: () async {})),
      );
      expect(find.text('serendipity'), findsOneWidget);
      expect(find.text('a happy accident'), findsOneWidget);
      expect(find.text('It was serendipity.'), findsOneWidget);
      expect(find.text('Save word'), findsOneWidget);
    });

    testWidgets('example is optional', (t) async {
      await t.pumpWidget(
        _host(
          StoryWordStickerWidget(
            sticker: const StoryWordSticker(word: 'w', meaning: 'm'),
            onSave: () async {},
          ),
        ),
      );
      expect(find.text('w'), findsOneWidget);
    });

    testWidgets('tapping save calls once, even if tapped twice', (t) async {
      var saves = 0;
      final done = Completer<void>();
      await t.pumpWidget(
        _host(
          StoryWordStickerWidget(
            sticker: word,
            onSave: () {
              saves++;
              return done.future;
            },
          ),
        ),
      );
      await t.tap(find.text('Save word'));
      await t.pump();
      await t.tap(find.byKey(const Key('word-save')), warnIfMissed: false);
      await t.pump();
      expect(saves, 1);
      done.complete();
      await t.pump();
    });

    testWidgets('saved state replaces the button', (t) async {
      await t.pumpWidget(
        _host(
          StoryWordStickerWidget(
            sticker: word,
            saved: true,
            onSave: () async {},
          ),
        ),
      );
      expect(find.text('Added to your vocabulary'), findsOneWidget);
      expect(find.text('Save word'), findsNothing);
    });

    testWidgets('read-only and owner show no save button', (t) async {
      for (final owner in [true, false]) {
        await t.pumpWidget(
          _host(
            StoryWordStickerWidget(
              sticker: word,
              isOwner: owner,
              readOnly: !owner,
            ),
          ),
        );
        expect(find.text('serendipity'), findsOneWidget);
        expect(find.text('Save word'), findsNothing);
      }
    });

    testWidgets('320x480 and RTL do not overflow', (t) async {
      await _small(t);
      await t.pumpWidget(
        _host(
          StoryWordStickerWidget(
            sticker: StoryWordSticker(
              word: 'w' * 60,
              meaning: 'meaning ' * 20,
              example: 'example ' * 30,
            ),
            onSave: () async {},
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });
}

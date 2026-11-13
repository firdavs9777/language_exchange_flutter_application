import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/stories/create/correction_sticker_editor.dart';
import 'package:bananatalk_app/pages/stories/create/create_story_screen.dart';
import 'package:bananatalk_app/pages/stories/create/quiz_sticker_editor.dart';
import 'package:bananatalk_app/pages/stories/create/word_sticker_editor.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/stories_service.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// Opens [editor] as a route from a button and exposes the popped value.
class _Result<T> {
  T? value;
  bool popped = false;
}

Future<_Result<T>> _open<T>(WidgetTester tester, Widget editor) async {
  final r = _Result<T>();
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              r.value = await Navigator.push<T>(
                context,
                MaterialPageRoute(builder: (_) => editor),
              );
              r.popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return r;
}

bool _doneEnabled(WidgetTester tester) {
  final b = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Done'));
  return b.onPressed != null;
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

void main() {
  group('sticker sheet', () {
    Future<void> openSheet(
      WidgetTester tester,
      Map<String, dynamic> flags,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          const CreateStoryScreen(),
          overrides: [
            appConfigProvider.overrideWith(
              (ref) async => AppConfig.fromJson(flags),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // In the app the config is loaded at startup; load it here.
      await ProviderScope.containerOf(
        tester.element(find.byType(CreateStoryScreen)),
      ).read(appConfigProvider.future);
      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('text-story-stickers')));
      await tester.pumpAndSettle();
    }

    testWidgets('flags off: exactly today\'s entries', (tester) async {
      await openSheet(tester, {});
      expect(find.text('Poll'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.byKey(const Key('sticker-link')), findsOneWidget);
      expect(find.byKey(const Key('sticker-correction')), findsNothing);
      expect(find.byKey(const Key('sticker-quiz')), findsNothing);
      expect(find.byKey(const Key('sticker-word')), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    for (final c in const [
      ['storyStickerCorrectionEnabled', 'sticker-correction'],
      ['storyStickerQuizEnabled', 'sticker-quiz'],
      ['storyStickerWordEnabled', 'sticker-word'],
    ]) {
      testWidgets('${c[0]} adds only its own entry', (tester) async {
        await openSheet(tester, {c[0]: true});
        for (final k in const [
          'sticker-correction',
          'sticker-quiz',
          'sticker-word',
        ]) {
          expect(find.byKey(Key(k)), k == c[1] ? findsOneWidget : findsNothing);
        }
        expect(find.byType(ListTile), findsNWidgets(6));
      });
    }
  });

  group('composer', () {
    Future<void> pumpTextStory(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          const CreateStoryScreen(),
          overrides: [
            appConfigProvider.overrideWith(
              (ref) async => AppConfig.fromJson({
                'storyStickerCorrectionEnabled': true,
                'storyStickerQuizEnabled': true,
                'storyStickerWordEnabled': true,
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await ProviderScope.containerOf(
        tester.element(find.byType(CreateStoryScreen)),
      ).read(appConfigProvider.future);
      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, String entry) async {
      await tester.tap(find.byKey(const Key('text-story-stickers')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry));
      await tester.pumpAndSettle();
    }

    Future<void> fillQuiz(WidgetTester tester) async {
      await _type(tester, 'quiz-question', 'Capital of France?');
      await _type(tester, 'quiz-option-0', 'Paris');
      await _type(tester, 'quiz-option-1', 'Rome');
      await tester.tap(find.byKey(const Key('quiz-correct-0')));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }

    testWidgets('quiz after poll replaces the poll; chip removes the quiz', (
      tester,
    ) async {
      await pumpTextStory(tester);
      await pick(tester, 'Poll');
      await tester.enterText(find.byType(TextField).first, 'Pick one');
      await tester.enterText(find.byType(TextField).at(1), 'a');
      await tester.enterText(find.byType(TextField).at(2), 'b');
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Poll: Pick one'), findsOneWidget);

      await pick(tester, 'Quiz');
      await fillQuiz(tester);
      expect(find.textContaining('Poll:'), findsNothing);
      expect(find.textContaining('Quiz: Capital of France?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Quiz:'), findsNothing);
    });

    testWidgets('word after quiz replaces the quiz', (tester) async {
      await pumpTextStory(tester);
      await pick(tester, 'Quiz');
      await fillQuiz(tester);
      await pick(tester, 'Word');
      await _type(tester, 'word-word', 'hola');
      await _type(tester, 'word-meaning', 'hello');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Quiz:'), findsNothing);
      expect(find.textContaining('Word: hola'), findsOneWidget);
    });

    testWidgets('sharing passes the sticker to the service', (tester) async {
      SharedPreferences.setMockInitialValues({'token': 't'});
      final bodies = <Map<String, dynamic>>[];
      StoriesService.httpClient = MockClient((req) async {
        bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 's1',
              'user': {'_id': 'u1', 'name': 'A'},
              'mediaUrl': '',
              'mediaType': 'text',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(() => StoriesService.httpClient = null);

      await pumpTextStory(tester);
      await pick(tester, 'Quiz');
      await fillQuiz(tester);

      // Tap the canvas to add the story's text.
      await tester.tapAt(const Offset(450, 1200));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'hello');
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(bodies, hasLength(1));
      final quiz = bodies.single['quizSticker'] as Map<String, dynamic>;
      expect(quiz['question'], 'Capital of France?');
      expect(quiz['options'], ['Paris', 'Rome']);
      expect(quiz['correctIndex'], 0);
      expect(bodies.single.containsKey('correctionSticker'), isFalse);
      expect(bodies.single.containsKey('wordSticker'), isFalse);
    });
  });

  group('CorrectionStickerEditor', () {
    testWidgets('validates and returns the sticker', (tester) async {
      final r = await _open<StoryCorrectionSticker>(
        tester,
        const CorrectionStickerEditor(defaultLanguage: 'ko'),
      );
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'correction-sentence', '   ');
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'correction-sentence', 'a' * 301);
      expect(_doneEnabled(tester), isFalse);
      expect(find.text('301/300'), findsOneWidget);
      // Counts trimmed length, like the server.
      await _type(tester, 'correction-sentence', '  ${'a' * 300}  ');
      expect(find.text('300/300'), findsOneWidget);
      expect(_doneEnabled(tester), isTrue);
      await _type(tester, 'correction-sentence', '  I goed home  ');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(r.value!.sentence, 'I goed home');
      expect(r.value!.language, 'ko');
      expect(r.value!.x, 0.5);
      expect(r.value!.y, 0.5);
    });

    testWidgets('cancel returns null', (tester) async {
      final r = await _open<StoryCorrectionSticker>(
        tester,
        const CorrectionStickerEditor(),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(r.popped, isTrue);
      expect(r.value, isNull);
    });
  });

  group('WordStickerEditor', () {
    testWidgets('validates and returns the sticker', (tester) async {
      final r = await _open<StoryWordSticker>(
        tester,
        const WordStickerEditor(defaultLanguage: 'es'),
      );
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'word-word', 'hola');
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'word-meaning', 'hello');
      expect(_doneEnabled(tester), isTrue);
      await _type(tester, 'word-word', 'a' * 61);
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'word-word', 'hola');
      await _type(tester, 'word-meaning', 'a' * 121);
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'word-meaning', 'hello');
      await _type(tester, 'word-example', 'a' * 201);
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'word-example', '   ');
      expect(_doneEnabled(tester), isTrue);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(r.value!.word, 'hola');
      expect(r.value!.meaning, 'hello');
      expect(r.value!.example, isNull);
      expect(r.value!.language, 'es');
    });

    testWidgets('keeps a trimmed example', (tester) async {
      final r = await _open<StoryWordSticker>(
        tester,
        const WordStickerEditor(),
      );
      await _type(tester, 'word-word', 'hola');
      await _type(tester, 'word-meaning', 'hello');
      await _type(tester, 'word-example', ' Hola, amigo ');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(r.value!.example, 'Hola, amigo');
      expect(r.value!.language, isNull);
    });
  });

  group('QuizStickerEditor', () {
    testWidgets('needs question, 2 options and a correct one', (tester) async {
      final r = await _open<StoryQuizSticker>(
        tester,
        const QuizStickerEditor(),
      );
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'quiz-question', 'Capital of France?');
      await _type(tester, 'quiz-option-0', 'Paris');
      // one option only
      await tester.tap(find.byKey(const Key('quiz-correct-0')));
      await tester.pump();
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'quiz-option-1', 'Rome');
      expect(_doneEnabled(tester), isTrue);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final q = r.value!;
      expect(q.question, 'Capital of France?');
      expect(q.options.map((o) => o.text), ['Paris', 'Rome']);
      expect(q.correctIndex, 0);
      expect(q.toCreateJson()['correctIndex'], 0);
    });

    testWidgets('no correct option marked blocks Done', (tester) async {
      await _open<StoryQuizSticker>(tester, const QuizStickerEditor());
      await _type(tester, 'quiz-question', 'Q?');
      await _type(tester, 'quiz-option-0', 'a');
      await _type(tester, 'quiz-option-1', 'b');
      expect(_doneEnabled(tester), isFalse);
      await tester.tap(find.byKey(const Key('quiz-correct-1')));
      await tester.pump();
      expect(_doneEnabled(tester), isTrue);
    });

    testWidgets('duplicate options (case-insensitive, trimmed) are refused', (
      tester,
    ) async {
      await _open<StoryQuizSticker>(tester, const QuizStickerEditor());
      await _type(tester, 'quiz-question', 'Q?');
      await _type(tester, 'quiz-option-0', 'Paris');
      await _type(tester, 'quiz-option-1', '  paris ');
      await tester.tap(find.byKey(const Key('quiz-correct-0')));
      await tester.pump();
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'quiz-option-1', 'Rome');
      expect(_doneEnabled(tester), isTrue);
    });

    testWidgets('length limits: question 200, option 80', (tester) async {
      await _open<StoryQuizSticker>(tester, const QuizStickerEditor());
      await _type(tester, 'quiz-option-0', 'a');
      await _type(tester, 'quiz-option-1', 'b');
      await tester.tap(find.byKey(const Key('quiz-correct-0')));
      await _type(tester, 'quiz-question', 'q' * 201);
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'quiz-question', 'q' * 200);
      expect(_doneEnabled(tester), isTrue);
      await _type(tester, 'quiz-option-1', 'b' * 81);
      expect(_doneEnabled(tester), isFalse);
      await _type(tester, 'quiz-option-1', 'b' * 80);
      expect(_doneEnabled(tester), isTrue);
    });

    testWidgets(
      'correct index follows the option after a blank row is dropped',
      (tester) async {
        final r = await _open<StoryQuizSticker>(
          tester,
          const QuizStickerEditor(),
        );
        await _type(tester, 'quiz-question', 'Q?');
        await tester.tap(find.byKey(const Key('quiz-add-option')));
        await tester.pump();
        await _type(tester, 'quiz-option-1', 'b');
        await _type(tester, 'quiz-option-2', 'c');
        await tester.tap(find.byKey(const Key('quiz-correct-2')));
        await tester.pump();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(r.value!.options.map((o) => o.text), ['b', 'c']);
        expect(r.value!.correctIndex, 1);
      },
    );

    testWidgets('at most 4 options', (tester) async {
      await _open<StoryQuizSticker>(tester, const QuizStickerEditor());
      await tester.tap(find.byKey(const Key('quiz-add-option')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('quiz-add-option')));
      await tester.pump();
      expect(find.byKey(const Key('quiz-option-3')), findsOneWidget);
      expect(find.byKey(const Key('quiz-add-option')), findsNothing);
    });
  });
}

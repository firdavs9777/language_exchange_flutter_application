import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/story/story_correction_sticker_widget.dart';
import 'package:bananatalk_app/widgets/story/story_progress_bar.dart';
import 'package:bananatalk_app/widgets/story/story_quiz_sticker_widget.dart';
import 'package:bananatalk_app/widgets/story/story_word_sticker_widget.dart';

import '../helpers/community_fixture.dart';

Story _story(
  Map<String, dynamic> extra, {
  String id = '64b7f0c2a1b2c3d4e5f60718',
  Duration ttl = const Duration(hours: 20),
}) => Story.fromJson({
  '_id': id,
  'user': {'_id': 'author1', 'name': 'Ana'},
  'mediaType': 'text',
  'text': 'Hello',
  'backgroundColor': '#336699',
  'createdAt': DateTime.now().toIso8601String(),
  'expiresAt': DateTime.now().add(ttl).toIso8601String(),
  ...extra,
});

const _quizJson = {
  'question': 'Pick one',
  'options': [
    {'index': 0, 'text': 'went'},
    {'index': 1, 'text': 'goed'},
  ],
  'hasAnswered': false,
  'totalAnswers': 0,
};

const _answeredQuiz = {
  'question': 'Pick one',
  'options': [
    {'index': 0, 'text': 'went', 'count': 3, 'percentage': 75},
    {'index': 1, 'text': 'goed', 'count': 1, 'percentage': 25},
  ],
  'hasAnswered': true,
  'totalAnswers': 4,
  'correctIndex': 0,
  'userAnswerIndex': 1,
};

final _requests = <http.Request>[];

/// Requests other than the view beacon the viewer sends on its own.
List<http.Request> get _calls =>
    _requests.where((r) => !r.url.path.endsWith('/view')).toList();

void _respond(http.Response Function(http.Request) f) {
  _requests.clear();
  StoriesService.httpClient = MockClient((req) async {
    _requests.add(req);
    return f(req);
  });
}

Future<void> _pump(
  WidgetTester tester,
  List<Story> stories, {
  bool own = false,
  StoryWordSaver? saveWord,
  Size size = const Size(1080, 2340),
  double dpr = 3,
}) async {
  SharedPreferences.setMockInitialValues({'token': 't'});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userProvider.overrideWith((ref) async => communityFixture())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryViewerScreen(
          stories: stories,
          isOwnStory: own,
          saveWord: saveWord ?? defaultStoryWordSaver,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  StoriesService.httpClient = null;
}

void main() {
  tearDown(() => StoriesService.httpClient = null);

  testWidgets(
    'a story with no learning sticker builds none of the new widgets',
    (tester) async {
      await _pump(tester, [_story({})]);
      expect(find.byType(StoryCorrectionStickerWidget), findsNothing);
      expect(find.byType(StoryQuizStickerWidget), findsNothing);
      expect(find.byType(StoryWordStickerWidget), findsNothing);
      await _dispose(tester);
    },
  );

  group('quiz', () {
    testWidgets(
      'answering shows the server result, and survives paging away and back',
      (tester) async {
        _respond(
          (r) => http.Response(
            jsonEncode({
              'success': true,
              'data': {'quiz': _answeredQuiz, 'isCorrect': false},
            }),
            200,
          ),
        );
        await _pump(tester, [
          _story({'quizSticker': _quizJson}),
          _story({}, id: '64b7f0c2a1b2c3d4e5f60719'),
        ]);
        expect(find.textContaining('%'), findsNothing);
        await tester.tap(find.text('goed'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(_calls.single.url.path, endsWith('/quiz-answer'));
        expect(jsonDecode(_calls.single.body), {'optionIndex': 1});
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('Not quite'), findsOneWidget);

        // Next story, then back: the answered state is kept.
        await tester.tapAt(const Offset(350, 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(StoryQuizStickerWidget), findsNothing);
        await tester.tapAt(const Offset(20, 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('75%'), findsOneWidget);
        await _dispose(tester);
      },
    );

    testWidgets('a successful answer without a readable quiz keeps the pick',
        (tester) async {
      _respond((r) => http.Response('{"success":true}', 200));
      await _pump(tester, [_story({'quizSticker': _quizJson})]);
      await tester.tap(find.text('goed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await tester.tap(find.text('went'));
      await tester.pump();
      expect(_calls.length, 1, reason: 'cannot answer twice');
      await _dispose(tester);
    });

    testWidgets('a failed answer rolls back and says so', (tester) async {
      _respond((r) => http.Response('{"success":false}', 400));
      await _pump(tester, [
        _story({'quizSticker': _quizJson}),
      ]);
      await tester.tap(find.text('goed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('quiz-pending-1')), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('an expired story shows the quiz read-only', (tester) async {
      _respond((r) => http.Response('{}', 500));
      await _pump(tester, [
        _story({'quizSticker': _quizJson}, ttl: const Duration(hours: -2)),
      ]);
      await tester.tap(find.text('goed'));
      await tester.pump();
      expect(_calls, isEmpty);
      await _dispose(tester);
    });

    testWidgets('the owner sees the results', (tester) async {
      await _pump(tester, [
        _story({
          'quizSticker': {
            ..._answeredQuiz,
            'hasAnswered': false,
            'userAnswerIndex': null,
          },
        }),
      ], own: true);
      expect(find.text('75%'), findsOneWidget);
      await _dispose(tester);
    });
  });

  group('correction', () {
    const sticker = {'sentence': 'I goed to school', 'language': 'en'};

    Future<void> openAndSend(WidgetTester tester, String text) async {
      await tester.tap(find.text('Correct this'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byKey(const Key('correction-send')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets(
      'success: sent state with max(returned, previous + 1) kept per story',
      (tester) async {
        _respond(
          (r) => http.Response(
            jsonEncode({
              'success': true,
              'data': {'correctionCount': 0, 'hasCorrected': true},
            }),
            201,
          ),
        );
        await _pump(tester, [
          _story({
            'correctionSticker': {...sticker, 'correctionCount': 4},
          }),
          _story({}, id: '64b7f0c2a1b2c3d4e5f60719'),
        ]);
        await openAndSend(tester, 'I went to school');
        expect(jsonDecode(_calls.single.body), {'text': 'I went to school'});
        expect(find.text('Correction sent'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        await tester.tapAt(const Offset(350, 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tapAt(const Offset(20, 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Correction sent'), findsOneWidget);
        await _dispose(tester);
      },
    );

    testWidgets('a send in flight stays disabled after paging away and back',
        (tester) async {
      final held = Completer<http.Response>();
      var sends = 0;
      StoriesService.httpClient = MockClient((req) async {
        if (req.url.path.endsWith('/correction')) {
          sends++;
          return held.future;
        }
        return http.Response('{}', 200);
      });
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
        _story({}, id: '64b7f0c2a1b2c3d4e5f60719'),
      ]);
      await openAndSend(tester, 'I went');
      expect(sends, 1);
      await tester.tapAt(const Offset(350, 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(20, 300));
      await tester.pump(const Duration(milliseconds: 300));
      // Back on the story: the field is closed (new State); open it again.
      await tester.tap(find.text('Correct this'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'again');
      final send = tester.widget<IconButton>(find.byKey(const Key('correction-send')));
      expect(send.onPressed, isNull);
      expect(sends, 1);
      held.complete(http.Response(
          '{"success":true,"data":{"correctionCount":1,"hasCorrected":true}}',
          201));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Correction sent'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('paging away with the field focused releases the pause',
        (tester) async {
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
        _story({}, id: '64b7f0c2a1b2c3d4e5f60719'),
      ]);
      await tester.tap(find.text('Correct this'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(350, 300));
      await tester.pump(const Duration(milliseconds: 300));
      final before = tester
          .widget<StoryProgressBar>(find.byType(StoryProgressBar))
          .currentProgress;
      await tester.pump(const Duration(seconds: 1));
      final after = tester
          .widget<StoryProgressBar>(find.byType(StoryProgressBar))
          .currentProgress;
      expect(after, greaterThan(before));
      // Holding the screen must still pause (a stale paused flag would make
      // the pause a no-op and the bar would keep running).
      final hold = await tester.startGesture(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 100));
      final held = tester
          .widget<StoryProgressBar>(find.byType(StoryProgressBar))
          .currentProgress;
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<StoryProgressBar>(find.byType(StoryProgressBar)).currentProgress,
        held,
      );
      await hold.up();
      await tester.pump(const Duration(milliseconds: 50));
      await _dispose(tester);
    });

    testWidgets('409: the already corrected state', (tester) async {
      _respond(
        (r) => http.Response(
          '{"success":false,"error":"You already corrected this story"}',
          409,
        ),
      );
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
      ]);
      await openAndSend(tester, 'I went');
      expect(find.text('You already corrected this'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await _dispose(tester);
    });

    testWidgets('403 replies disabled hides the field', (tester) async {
      _respond(
        (r) => http.Response(
          '{"success":false,"error":"Replies are disabled for this story"}',
          403,
        ),
      );
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
      ]);
      await openAndSend(tester, 'I went');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Correct this'), findsNothing);
      await _dispose(tester);
    });

    testWidgets('limit reached: server message in a snackbar, text kept', (
      tester,
    ) async {
      _respond(
        (r) => http.Response(
          '{"success":false,"error":"Daily messages limit exceeded."}',
          429,
        ),
      );
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
      ]);
      await openAndSend(tester, 'I went');
      expect(find.text('Daily messages limit exceeded.'), findsOneWidget);
      expect(find.text('I went'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('a server failure shows a snackbar and keeps the text', (
      tester,
    ) async {
      _respond((r) => http.Response('{}', 500));
      await _pump(tester, [
        _story({'correctionSticker': sticker}),
      ]);
      await openAndSend(tester, 'I went');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('I went'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('allowReplies false: no field', (tester) async {
      await _pump(tester, [
        _story({'correctionSticker': sticker, 'allowReplies': false}),
      ]);
      expect(find.text('I goed to school'), findsOneWidget);
      expect(find.text('Correct this'), findsNothing);
      await _dispose(tester);
    });

    testWidgets('expired story: read-only', (tester) async {
      await _pump(tester, [
        _story({'correctionSticker': sticker}, ttl: const Duration(hours: -1)),
      ]);
      expect(find.text('I goed to school'), findsOneWidget);
      expect(find.text('Correct this'), findsNothing);
      await _dispose(tester);
    });

    testWidgets('owner: count only', (tester) async {
      await _pump(tester, [
        _story({
          'correctionSticker': {
            ...sticker,
            'correctionCount': 2,
            'corrections': [
              {
                'user': {'_id': 'a'},
              },
              {
                'user': {'_id': 'b'},
              },
            ],
          },
        }),
      ], own: true);
      expect(find.text('2 corrections'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('the field stays visible above the keyboard at 320x480', (
      tester,
    ) async {
      await _pump(
        tester,
        [
          _story({'correctionSticker': sticker}),
        ],
        size: const Size(320, 480),
        dpr: 1,
      );
      // The viewer already overflows by 24px at 320 wide without any sticker
      // (header / reply bar, not this task); drain it so only new ones count.
      tester.takeException();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(find.text('Correct this'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byType(TextField));
      expect(field.bottom, lessThanOrEqualTo(480 - 200));
      expect(field.top, greaterThanOrEqualTo(0));
      await _dispose(tester);
    });
  });

  group('word', () {
    const sticker = {
      'word': 'serendipity',
      'meaning': 'a happy accident',
      'example': 'It was serendipity.',
      'language': 'en',
    };

    testWidgets('save maps the sticker to the vocabulary call once', (
      tester,
    ) async {
      final calls = <Map<String, String?>>[];
      await _pump(
        tester,
        [
          _story({'wordSticker': sticker}),
        ],
        saveWord:
            ({
              required String word,
              required String translation,
              required String language,
              String? exampleSentence,
            }) async {
              calls.add({
                'word': word,
                'translation': translation,
                'language': language,
                'exampleSentence': exampleSentence,
              });
              return {'success': true};
            },
      );
      await tester.tap(find.text('Save word'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, [
        {
          'word': 'serendipity',
          'translation': 'a happy accident',
          'language': 'en',
          'exampleSentence': 'It was serendipity.',
        },
      ]);
      expect(find.text('Save word'), findsNothing);
      expect(find.text('Added to your vocabulary'), findsWidgets);
      await _dispose(tester);
    });

    testWidgets('a missing language is sent as auto', (tester) async {
      String? lang;
      await _pump(
        tester,
        [
          _story({
            'wordSticker': {'word': 'w', 'meaning': 'm'},
          }),
        ],
        saveWord:
            ({
              required String word,
              required String translation,
              required String language,
              String? exampleSentence,
            }) async {
              lang = language;
              return {'success': true};
            },
      );
      await tester.tap(find.text('Save word'));
      await tester.pump();
      expect(lang, 'auto');
      await _dispose(tester);
    });

    testWidgets('a failure keeps the button and shows a snackbar', (
      tester,
    ) async {
      await _pump(
        tester,
        [
          _story({'wordSticker': sticker}),
        ],
        saveWord:
            ({
              required String word,
              required String translation,
              required String language,
              String? exampleSentence,
            }) async => {'success': false, 'error': 'boom'},
      );
      await tester.tap(find.text('Save word'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Save word'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      await _dispose(tester);
    });
  });
}

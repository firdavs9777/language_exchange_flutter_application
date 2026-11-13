import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';

void main() {
  late Directory tmp;
  late File image;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('stories_svc_test');
    image = File('${tmp.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));
  tearDown(() => StoriesService.httpClient = null);

  http.BaseRequest? seen;
  String? seenBody;

  void respond(int status, [String body = '{}']) {
    seen = null;
    seenBody = null;
    StoriesService.httpClient = MockClient((req) async {
      seen = req;
      seenBody = req.body;
      return http.Response(body, status);
    });
  }

  const storyJson = '{"success":true,"data":{"_id":"s1"}}';
  const correction =
      StoryCorrectionSticker(sentence: 'I goed', language: 'en', x: 0.2, y: 0.3);
  const quiz = StoryQuizSticker(
    question: 'Q?',
    options: [
      StoryQuizOption(index: 0, text: 'a'),
      StoryQuizOption(index: 1, text: 'b'),
    ],
    correctIndex: 1,
  );
  const word = StoryWordSticker(word: 'w', meaning: 'm', example: 'e');

  group('createStory (multipart)', () {
    test('sends sticker fields as JSON strings and the idempotency header',
        () async {
      respond(201, storyJson);
      final r = await StoriesService.createStory(
        mediaFiles: [image],
        correctionSticker: correction,
        quizSticker: quiz,
        wordSticker: word,
        idempotencyKey: 'key_1-A',
      );
      expect(r.success, isTrue);
      expect(seen!.headers['Idempotency-Key'], 'key_1-A');
      final body = seenBody!;
      expect(body, contains('name="correctionSticker"'));
      expect(body, contains(jsonEncode(correction.toCreateJson())));
      expect(body, contains(jsonEncode(quiz.toCreateJson())));
      expect(body, contains(jsonEncode(word.toCreateJson())));
    });

    test('no key means no header and no sticker fields', () async {
      respond(201, storyJson);
      await StoriesService.createStory(mediaFiles: [image]);
      expect(seen!.headers.containsKey('Idempotency-Key'), isFalse);
      expect(seenBody, isNot(contains('Sticker')));
    });

    test('409 messages map to inProgress and alreadyPosted', () async {
      respond(409, '{"message":"Story upload already in progress"}');
      var r = await StoriesService.createStory(mediaFiles: [image]);
      expect(r.success, isFalse);
      expect(r.failure, StoryPostFailure.inProgress);
      respond(409, '{"message":"Story was already posted"}');
      r = await StoriesService.createStory(mediaFiles: [image]);
      expect(r.failure, StoryPostFailure.alreadyPosted);
    });

    test('503 is tryAgain, 429 is limitReached, 500 is generic', () async {
      respond(503, '{"message":"Try again shortly"}');
      expect((await StoriesService.createStory(mediaFiles: [image])).failure,
          StoryPostFailure.tryAgain);
      respond(429, '{"message":"limit"}');
      var r = await StoriesService.createStory(mediaFiles: [image]);
      expect(r.limitReached, isTrue);
      expect(r.failure, isNull);
      respond(500);
      r = await StoriesService.createStory(mediaFiles: [image]);
      expect(r.success, isFalse);
      expect(r.failure, isNull);
      expect(r.limitReached, isFalse);
    });

    test('an unrecognised 409 stays generic', () async {
      respond(409, '{"message":"conflict"}');
      final r = await StoriesService.createStory(mediaFiles: [image]);
      expect(r.failure, isNull);
      expect(r.error, 'conflict');
    });
  });

  group('createTextStory (JSON)', () {
    test('sends sticker objects and the header', () async {
      respond(201, storyJson);
      final r = await StoriesService.createTextStory(
        text: 'hi',
        backgroundColor: '#000000',
        correctionSticker: correction,
        quizSticker: quiz,
        wordSticker: word,
        idempotencyKey: 'abc',
      );
      expect(r.success, isTrue);
      expect(seen!.headers['Idempotency-Key'], 'abc');
      final m = jsonDecode(seenBody!) as Map;
      expect(m['correctionSticker'], correction.toCreateJson());
      expect(m['quizSticker'], quiz.toCreateJson());
      expect(m['wordSticker'], word.toCreateJson());
    });

    test('no key, no stickers: nothing extra', () async {
      respond(201, storyJson);
      await StoriesService.createTextStory(text: 'hi', backgroundColor: '#000');
      expect(seen!.headers.containsKey('Idempotency-Key'), isFalse);
      final m = jsonDecode(seenBody!) as Map;
      expect(m.keys.where((k) => k.endsWith('Sticker')), isEmpty);
    });

    test('status mappings', () async {
      respond(409, '{"message":"Story upload already in progress"}');
      expect(
          (await StoriesService.createTextStory(
                  text: 'hi', backgroundColor: '#000'))
              .failure,
          StoryPostFailure.inProgress);
      respond(409, '{"message":"Story was already posted"}');
      expect(
          (await StoriesService.createTextStory(
                  text: 'hi', backgroundColor: '#000'))
              .failure,
          StoryPostFailure.alreadyPosted);
      respond(503);
      expect(
          (await StoriesService.createTextStory(
                  text: 'hi', backgroundColor: '#000'))
              .failure,
          StoryPostFailure.tryAgain);
      respond(429);
      expect(
          (await StoriesService.createTextStory(
                  text: 'hi', backgroundColor: '#000'))
              .limitReached,
          isTrue);
    });
  });

  group('submitCorrection', () {
    Future<CorrectionResult> go(int status, [String body = '{}']) {
      respond(status, body);
      return StoriesService.submitCorrection(storyId: 's1', text: 'I went');
    }

    test('201 succeeds and sends exactly {text}', () async {
      final r = await go(201,
          '{"success":true,"data":{"correctionCount":3,"hasCorrected":true}}');
      expect(r.success, isTrue);
      expect(r.outcome, CorrectionOutcome.success);
      expect(r.correctionCount, 3);
      expect(seen!.url.path, endsWith('stories/s1/correction'));
      expect(seen!.method, 'POST');
      expect(seenBody, '{"text":"I went"}');
    });

    test('409 is alreadyCorrected', () async {
      final r = await go(409, '{"message":"x"}');
      expect(r.alreadyCorrected, isTrue);
      expect(r.success, isFalse);
    });

    test('403 replies disabled vs blocked', () async {
      var r = await go(403, '{"message":"Replies are disabled for this story"}');
      expect(r.outcome, CorrectionOutcome.repliesDisabled);
      expect(r.blocked, isFalse);
      r = await go(403, '{"message":"You cannot interact"}');
      expect(r.outcome, CorrectionOutcome.blocked);
      expect(r.blocked, isTrue);
      r = await go(403);
      expect(r.outcome, CorrectionOutcome.blocked);
    });

    test('deployed 403 wordings and code', () async {
      var r = await go(403,
          '{"success":false,"code":"CONVERSATION_START_LIMIT","message":"Daily conversation limit reached"}');
      expect(r.outcome, CorrectionOutcome.limitReached);
      expect(r.message, 'Daily conversation limit reached');
      r = await go(403, '{"message":"This content is not available"}');
      expect(r.outcome, CorrectionOutcome.unavailable);
      r = await go(403, '{"message":"Cannot reply to this story"}');
      expect(r.outcome, CorrectionOutcome.blocked);
      r = await go(403, 'not json');
      expect(r.outcome, CorrectionOutcome.blocked);
    });

    test('deployed 409 and 429 wordings', () async {
      var r = await go(409, '{"message":"You already corrected this story"}');
      expect(r.outcome, CorrectionOutcome.alreadyCorrected);
      r = await go(429, '{"message":"Daily messages limit exceeded. Upgrade."}');
      expect(r.outcome, CorrectionOutcome.limitReached);
      expect(r.message, startsWith('Daily messages limit exceeded'));
    });

    test('a 201 with an unreadable body is still success', () async {
      var r = await go(201, 'not json');
      expect(r.success, isTrue);
      expect(r.correctionCount, isNull);
      r = await go(201, '[]');
      expect(r.success, isTrue);
    });

    test('429 is limitReached and carries the message', () async {
      final r = await go(429, '{"message":"Message limit reached"}');
      expect(r.outcome, CorrectionOutcome.limitReached);
      expect(r.message, 'Message limit reached');
    });

    test('400 invalid carries the message, 404 unavailable, 500 failure',
        () async {
      var r = await go(400, '{"message":"Story has expired"}');
      expect(r.outcome, CorrectionOutcome.invalid);
      expect(r.message, 'Story has expired');
      r = await go(404);
      expect(r.outcome, CorrectionOutcome.unavailable);
      r = await go(500);
      expect(r.outcome, CorrectionOutcome.failure);
    });

    test('a thrown error is a failure', () async {
      StoriesService.httpClient = MockClient((_) async => throw Exception('x'));
      final r = await StoriesService.submitCorrection(storyId: 's', text: 't');
      expect(r.outcome, CorrectionOutcome.failure);
    });
  });

  group('answerQuiz', () {
    test('200 parses the answered quiz and isCorrect', () async {
      respond(
          200,
          jsonEncode({
            'success': true,
            'data': {
              'quiz': {
                'question': 'Q?',
                'options': [
                  {'index': 0, 'text': 'a', 'count': 1, 'percentage': 50},
                  {'index': 1, 'text': 'b', 'count': 1, 'percentage': 50},
                ],
                'hasAnswered': true,
                'totalAnswers': 2,
                'correctIndex': 1,
                'userAnswerIndex': 0,
              },
              'isCorrect': false,
            },
          }));
      final r = await StoriesService.answerQuiz(storyId: 's1', optionIndex: 0);
      expect(r.success, isTrue);
      expect(r.isCorrect, isFalse);
      expect(r.quiz!.correctIndex, 1);
      expect(r.quiz!.userAnswerIndex, 0);
      expect(seen!.url.path, endsWith('stories/s1/quiz-answer'));
      expect(seenBody, '{"optionIndex":0}');
    });

    test('400 and 404 are failures with the message', () async {
      respond(400, '{"message":"Story has expired"}');
      var r = await StoriesService.answerQuiz(storyId: 's1', optionIndex: 0);
      expect(r.success, isFalse);
      expect(r.quiz, isNull);
      expect(r.error, 'Story has expired');
      respond(404);
      r = await StoriesService.answerQuiz(storyId: 's1', optionIndex: 0);
      expect(r.success, isFalse);
    });
  });

  group('viewStory', () {
    test('without completed the body is exactly today\'s', () async {
      respond(200, '{"viewCount":4}');
      await StoriesService.viewStory(storyId: 's1');
      expect(seenBody, '{}');
      await StoriesService.viewStory(storyId: 's1', viewDuration: 5);
      expect(seenBody, '{"viewDuration":5}');
      await StoriesService.viewStory(
          storyId: 's1', viewDuration: 5, completed: false);
      expect(seenBody, '{"viewDuration":5}');
    });

    test('completed true is sent', () async {
      respond(200, '{"viewCount":4}');
      final r = await StoriesService.viewStory(
          storyId: 's1', viewDuration: 5, completed: true);
      expect(seenBody, '{"viewDuration":5,"completed":true}');
      expect(r['success'], isTrue);
      expect(r['viewCount'], 4);
    });
  });

  group('getStoryViewers', () {
    test('without summary it is null', () async {
      respond(200, '{"data":{"viewCount":1,"views":[]}}');
      final r = await StoriesService.getStoryViewers(storyId: 's1');
      expect(r['success'], isTrue);
      expect(r.containsKey('summary'), isTrue);
      expect(r['summary'], isNull);
    });

    test('with summary it is parsed', () async {
      respond(
          200,
          '{"data":{"viewCount":1,"views":[{"user":{"_id":"u"},"completed":true}],'
          '"summary":{"views":1,"completions":1,"replies":2,"reactions":3,"sticker":null}}}');
      final r = await StoriesService.getStoryViewers(storyId: 's1');
      final s = r['summary'] as StoryViewsSummary;
      expect(s.completions, 1);
      expect(s.reactions, 3);
      expect((r['views'] as List).single.completed, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';

Map<String, dynamic> storyJson([Map<String, dynamic> extra = const {}]) => {
      '_id': 's1',
      'user': {'_id': 'u1', 'name': 'A'},
      'mediaUrl': 'm.jpg',
      'mediaType': 'image',
      ...extra,
    };

void main() {
  group('Story with today\'s JSON', () {
    test('has no learning stickers', () {
      final s = Story.fromJson(storyJson());
      expect(s.correctionSticker, isNull);
      expect(s.quizSticker, isNull);
      expect(s.wordSticker, isNull);
      expect(s.interactiveStickerCount, 0);
    });

    test('explicit nulls are fine', () {
      final s = Story.fromJson(storyJson({
        'correctionSticker': null,
        'quizSticker': null,
        'wordSticker': null,
      }));
      expect(s.interactiveStickerCount, 0);
    });
  });

  group('StoryCorrectionSticker', () {
    test('parses', () {
      final c = StoryCorrectionSticker.fromJsonOrNull({
        'sentence': 'I goed home',
        'language': 'en',
        'x': 0.2,
        'y': 0.8,
        'correctionCount': 3,
        'hasCorrected': true,
      })!;
      expect(c.sentence, 'I goed home');
      expect(c.language, 'en');
      expect(c.x, 0.2);
      expect(c.y, 0.8);
      expect(c.correctionCount, 3);
      expect(c.hasCorrected, isTrue);
    });

    test('language absent, x/y default and clamp', () {
      final c = StoryCorrectionSticker.fromJsonOrNull(
          {'sentence': 'a', 'x': 5, 'y': -2})!;
      expect(c.language, isNull);
      expect(c.x, 1.0);
      expect(c.y, 0.0);
      final d = StoryCorrectionSticker.fromJsonOrNull({'sentence': 'a'})!;
      expect(d.x, 0.5);
      expect(d.y, 0.5);
      expect(d.correctionCount, 0);
      expect(d.hasCorrected, isFalse);
    });

    test('toCreateJson shape', () {
      const c = StoryCorrectionSticker(
          sentence: 's', language: 'en', x: 0.1, y: 0.9);
      expect(c.toCreateJson(),
          {'sentence': 's', 'language': 'en', 'x': 0.1, 'y': 0.9});
    });

    test('copyWith', () {
      const c = StoryCorrectionSticker(sentence: 's');
      final d = c.copyWith(correctionCount: 2, hasCorrected: true);
      expect(d.correctionCount, 2);
      expect(d.hasCorrected, isTrue);
      expect(d.sentence, 's');
    });
  });

  group('StoryQuizSticker', () {
    Map<String, dynamic> quiz([Map<String, dynamic> extra = const {}]) => {
          'question': 'Which?',
          'options': [
            {'index': 0, 'text': 'a'},
            {'index': 1, 'text': 'b'},
          ],
          'hasAnswered': false,
          'totalAnswers': 0,
          ...extra,
        };

    test('unanswered: no correctIndex, counts absent', () {
      final q = StoryQuizSticker.fromJsonOrNull(quiz())!;
      expect(q.question, 'Which?');
      expect(q.options.length, 2);
      expect(q.options[0].count, isNull);
      expect(q.options[0].percentage, isNull);
      expect(q.correctIndex, isNull);
      expect(q.userAnswerIndex, isNull);
      expect(q.hasAnswered, isFalse);
    });

    test('answered shape', () {
      final q = StoryQuizSticker.fromJsonOrNull(quiz({
        'hasAnswered': true,
        'totalAnswers': 4,
        'correctIndex': 1,
        'userAnswerIndex': 0,
        'options': [
          {'index': 0, 'text': 'a', 'count': 1, 'percentage': 25},
          {'index': 1, 'text': 'b', 'count': 3, 'percentage': 75},
        ],
      }))!;
      expect(q.hasAnswered, isTrue);
      expect(q.totalAnswers, 4);
      expect(q.correctIndex, 1);
      expect(q.userAnswerIndex, 0);
      expect(q.options[1].count, 3);
      expect(q.options[1].percentage, 75);
    });

    test('owner: hasAnswered false with correctIndex present', () {
      final q = StoryQuizSticker.fromJsonOrNull(
          quiz({'correctIndex': 0, 'userAnswerIndex': null}))!;
      expect(q.hasAnswered, isFalse);
      expect(q.correctIndex, 0);
    });

    test('needs 2..4 options', () {
      expect(
          StoryQuizSticker.fromJsonOrNull(quiz({
            'options': [
              {'index': 0, 'text': 'a'}
            ]
          })),
          isNull);
      expect(
          StoryQuizSticker.fromJsonOrNull(quiz({
            'options': [for (var i = 0; i < 5; i++) {'index': i, 'text': 't$i'}]
          })),
          isNull);
      expect(
          StoryQuizSticker.fromJsonOrNull(quiz({
            'options': [for (var i = 0; i < 4; i++) {'index': i, 'text': 't$i'}]
          })),
          isNotNull);
    });

    test('toCreateJson sends correctIndex as an int', () {
      const q = StoryQuizSticker(
        question: 'Q',
        options: [
          StoryQuizOption(index: 0, text: 'a'),
          StoryQuizOption(index: 1, text: 'b'),
        ],
        correctIndex: 1,
      );
      expect(q.toCreateJson(),
          {'question': 'Q', 'options': ['a', 'b'], 'correctIndex': 1});
    });

    test('copyWith', () {
      final q = StoryQuizSticker.fromJsonOrNull(quiz())!;
      final r = q.copyWith(hasAnswered: true, correctIndex: 1);
      expect(r.hasAnswered, isTrue);
      expect(r.correctIndex, 1);
      expect(r.question, 'Which?');
    });
  });

  group('StoryWordSticker', () {
    test('parses with example and language absent', () {
      final w = StoryWordSticker.fromJsonOrNull(
          {'word': 'hola', 'meaning': 'hello'})!;
      expect(w.word, 'hola');
      expect(w.meaning, 'hello');
      expect(w.example, isNull);
      expect(w.language, isNull);
      expect(w.x, 0.5);
    });

    test('toCreateJson shape', () {
      const w = StoryWordSticker(
          word: 'w',
          meaning: 'm',
          example: 'e',
          language: 'ko',
          x: 0.3,
          y: 0.4);
      expect(w.toCreateJson(), {
        'word': 'w',
        'meaning': 'm',
        'example': 'e',
        'language': 'ko',
        'x': 0.3,
        'y': 0.4,
      });
    });

    test('copyWith', () {
      const w = StoryWordSticker(word: 'w', meaning: 'm');
      expect(w.copyWith(meaning: 'z').meaning, 'z');
      expect(w.copyWith(meaning: 'z').word, 'w');
    });
  });

  group('malformed inputs never throw', () {
    final bad = <Object?>[
      null,
      5,
      'str',
      <dynamic>[],
      <String, dynamic>{},
      {'sentence': ''},
      {'sentence': '  '},
      {'sentence': 5},
      {'sentence': 'a', 'x': 'left', 'y': null, 'correctionCount': 'many'},
      {'question': 'q', 'options': 'nope'},
      {'question': 'q', 'options': [1, 2, 3]},
      {'question': 'q', 'options': [null, null]},
      {'question': '', 'options': []},
      {'word': 'w'},
      {'word': 'w', 'meaning': ''},
      {'word': '', 'meaning': 'm'},
      {'word': 'w', 'meaning': 'm', 'example': 7, 'language': [], 'x': {}},
    ];
    for (final b in bad) {
      test('$b', () {
        StoryCorrectionSticker.fromJsonOrNull(b);
        StoryQuizSticker.fromJsonOrNull(b);
        StoryWordSticker.fromJsonOrNull(b);
        Story.fromJson(storyJson({
          'correctionSticker': b,
          'quizSticker': b,
          'wordSticker': b,
        }));
      });
    }

    test('non-numeric x/y fall back to 0.5', () {
      final c = StoryCorrectionSticker.fromJsonOrNull(
          {'sentence': 'a', 'x': 'left', 'y': null})!;
      expect(c.x, 0.5);
      expect(c.y, 0.5);
    });

    test('word needs meaning', () {
      expect(StoryWordSticker.fromJsonOrNull({'word': 'w'}), isNull);
    });
  });

  group('Story stickers and count', () {
    test('parse and count together', () {
      final s = Story.fromJson(storyJson({
        'correctionSticker': {'sentence': 'a'},
        'wordSticker': {'word': 'w', 'meaning': 'm'},
        'poll': {
          'question': 'q',
          'options': [
            {'text': 'a'},
            {'text': 'b'}
          ]
        },
      }));
      expect(s.correctionSticker, isNotNull);
      expect(s.wordSticker, isNotNull);
      expect(s.quizSticker, isNull);
      expect(s.interactiveStickerCount, 3);
    });

    test('copyWith keeps stickers', () {
      final s = Story.fromJson(storyJson({
        'wordSticker': {'word': 'w', 'meaning': 'm'},
      }));
      expect(s.copyWith(viewCount: 3).wordSticker, isNotNull);
    });
  });

  group('StoryView.completed', () {
    test('defaults false and parses', () {
      expect(StoryView.fromJson({'user': 'u'}).completed, isFalse);
      expect(
          StoryView.fromJson({'user': 'u', 'completed': true}).completed,
          isTrue);
      expect(
          StoryView.fromJson({'user': 'u', 'completed': 'yes'}).completed,
          isFalse);
    });
  });

  group('StoryViewsSummary', () {
    test('parses with a poll-like sticker', () {
      final s = StoryViewsSummary.fromJsonOrNull({
        'views': 10,
        'completions': 4,
        'replies': 2,
        'reactions': 3,
        'sticker': {
          'type': 'quiz',
          'count': 5,
          'correctIndex': 1,
          'correctCount': 3,
          'options': [
            {'text': 'a', 'count': 2},
            {'text': 'b', 'count': 3},
          ],
        },
      })!;
      expect(s.views, 10);
      expect(s.completions, 4);
      expect(s.replies, 2);
      expect(s.reactions, 3);
      expect(s.sticker!.type, 'quiz');
      expect(s.sticker!.count, 5);
      expect(s.sticker!.correctIndex, 1);
      expect(s.sticker!.correctCount, 3);
      expect(s.sticker!.options.length, 2);
      expect(s.sticker!.options[1].text, 'b');
      expect(s.sticker!.options[1].count, 3);
    });

    test('null sticker, unknown type and junk give sticker null', () {
      expect(StoryViewsSummary.fromJsonOrNull({'views': 1})!.sticker, isNull);
      expect(
          StoryViewsSummary.fromJsonOrNull({'views': 1, 'sticker': null})!
              .sticker,
          isNull);
      expect(
          StoryViewsSummary.fromJsonOrNull(
                  {'views': 1, 'sticker': {'type': 'hologram', 'count': 2}})!
              .sticker,
          isNull);
      expect(StoryViewsSummary.fromJsonOrNull({'views': 1, 'sticker': 5})!
          .sticker, isNull);
    });

    test('non-map is null; missing numbers are 0', () {
      expect(StoryViewsSummary.fromJsonOrNull(null), isNull);
      expect(StoryViewsSummary.fromJsonOrNull('x'), isNull);
      final s = StoryViewsSummary.fromJsonOrNull(<String, dynamic>{})!;
      expect(s.views, 0);
      expect(s.completions, 0);
    });

    test('recognised sticker types', () {
      for (final t in ['poll', 'questionBox', 'quiz', 'correction', 'word']) {
        expect(
            StoryViewsSummary.fromJsonOrNull(
                    {'sticker': {'type': t, 'count': 1}})!
                .sticker,
            isNotNull,
            reason: t);
      }
    });
  });
}

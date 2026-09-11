import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

Map<String, dynamic> _packJson() => {
      'needsLanguage': false,
      'dateKey': '2026-09-07',
      'weekKey': '2026-W37',
      'dayInWeek': 1,
      'language': 'en',
      'requestedLevel': 'A2',
      'servedLevel': 'A2',
      'theme': {'id': 'p1', 'topic': 'Work & careers', 'level': 'intermediate'},
      'packComplete': false,
      'stations': [
        {
          'kind': 'vocabulary',
          'status': 'todo',
          'score': null,
          'payload': {
            'words': [
              {'word': 'ambition', 'definition': 'a strong wish', 'example': 'Her ambition showed.'}
            ],
            'checks': [
              {
                'prompt': 'Which word means "a strong wish"?',
                'options': ['ambition', 'colleague', 'salary']
              }
            ],
          },
        },
        {'kind': 'grammar', 'status': 'done', 'score': 2, 'payload': null},
        {
          'kind': 'listening',
          'status': 'todo',
          'payload': {
            'clips': [
              {'id': 'c0', 'text': 'She is waiting outside.', 'word': 'waiting'}
            ]
          }
        },
        {'kind': 'review', 'status': 'empty', 'payload': null},
      ],
    };

void main() {
  test('parses the pack envelope', () {
    final pack = DailyPack.fromJson(_packJson());
    expect(pack.needsLanguage, isFalse);
    expect(pack.weekKey, '2026-W37');
    expect(pack.dayInWeek, 1);
    expect(pack.theme!.topic, 'Work & careers');
    expect(pack.stations.length, 4);
  });

  test('maps station status strings onto the enum', () {
    final pack = DailyPack.fromJson(_packJson());
    expect(pack.stationOf('vocabulary')!.status, StationStatus.todo);
    expect(pack.stationOf('grammar')!.status, StationStatus.done);
    expect(pack.stationOf('review')!.status, StationStatus.empty);
  });

  test('an unknown status degrades to todo rather than throwing', () {
    final json = _packJson();
    (json['stations'] as List)[0]['status'] = 'something-new';
    expect(DailyPack.fromJson(json).stationOf('vocabulary')!.status, StationStatus.todo);
  });

  test('doneCount counts done and empty stations, matching the server ring', () {
    // 'empty' is satisfied, not outstanding — a learner with no due words must
    // not see 3 of 4 forever.
    expect(DailyPack.fromJson(_packJson()).doneCount, 2);
  });

  test('parses a vocabulary payload with words and checks', () {
    final station = DailyPack.fromJson(_packJson()).stationOf('vocabulary')!;
    final payload = station.payload as VocabPayload;
    expect(payload.words.single.word, 'ambition');
    expect(payload.checks.single.options.length, 3);
  });

  test('parses a listening payload', () {
    final payload =
        DailyPack.fromJson(_packJson()).stationOf('listening')!.payload as ListeningPayload;
    expect(payload.clips.single.text, 'She is waiting outside.');
  });

  test('needsLanguage responses parse without any stations', () {
    final pack = DailyPack.fromJson({'needsLanguage': true});
    expect(pack.needsLanguage, isTrue);
    expect(pack.stations, isEmpty);
  });

  test('a missing theme is null, not a crash', () {
    final json = _packJson()..remove('theme');
    expect(DailyPack.fromJson(json).theme, isNull);
  });

  test('level fallback is reported when served differs from requested', () {
    final json = _packJson()..['servedLevel'] = 'A1';
    expect(DailyPack.fromJson(json).isLevelFallback, isTrue);
    expect(DailyPack.fromJson(_packJson()).isLevelFallback, isFalse);
  });

  test('nextStation is the first outstanding one', () {
    expect(DailyPack.fromJson(_packJson()).nextStation!.kind, 'vocabulary');
  });

  test('parses a station result', () {
    final result = StationResult.fromJson({
      'score': 2, 'total': 3, 'xpAwarded': 10, 'streak': 4,
      'packComplete': false, 'stationsRemaining': ['review'],
    });
    expect(result.score, 2);
    expect(result.streak, 4);
    expect(result.stationsRemaining, ['review']);
  });
}

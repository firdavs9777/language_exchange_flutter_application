import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';

void main() {
  final json = {
    'needsLanguage': false,
    'dateKey': '2026-08-23',
    'language': 'en',
    'requestedLevel': 'A2',
    'servedLevel': 'A2',
    'grammar': {
      'id': 'g1',
      'kind': 'grammar',
      'level': 'A2',
      'title': 'used to vs would',
      'explanation': 'Both describe past habits.',
      'examples': [
        {'text': 'I used to live in Seoul.', 'translation': 'a past state'}
      ],
      'quickCheck': [
        {'prompt': 'I ___ be shy.', 'options': ['used to', 'would']}
      ],
    },
    'vocabulary': null,
    'completed': [
      {'kind': 'grammar', 'score': 2}
    ],
    'dayComplete': false,
  };

  test('parses a full drop', () {
    final state = DailyDropState.fromJson(json);
    expect(state.needsLanguage, isFalse);
    expect(state.dateKey, '2026-08-23');
    expect(state.grammar!.title, 'used to vs would');
    expect(state.grammar!.quickCheck.first.options.length, 2);
    expect(state.vocabulary, isNull);
    expect(state.dayComplete, isFalse);
    expect(state.scoreFor('grammar'), 2);
  });

  test('scoreFor returns null for a kind not yet completed', () {
    expect(DailyDropState.fromJson(json).scoreFor('vocabulary'), isNull);
  });

  test('a needsLanguage response parses without items', () {
    final state = DailyDropState.fromJson({
      'needsLanguage': true, 'dateKey': '2026-08-23',
      'grammar': null, 'vocabulary': null,
    });
    expect(state.needsLanguage, isTrue);
    expect(state.grammar, isNull);
  });

  test('a served level below the requested one is detectable', () {
    final state = DailyDropState.fromJson({...json, 'requestedLevel': 'C1', 'servedLevel': 'B1'});
    expect(state.isLevelFallback, isTrue);
  });

  test('matching requested and served levels are not a fallback', () {
    expect(DailyDropState.fromJson(json).isLevelFallback, isFalse);
  });
}

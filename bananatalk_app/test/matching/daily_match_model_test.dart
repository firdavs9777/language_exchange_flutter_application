import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';

void main() {
  test('DailyMatch.fromJson tolerates junk and parses the contract', () {
    final match = DailyMatch.fromJson({
      'user': {
        '_id': 'u1',
        'name': 'Minji',
        'native_language': 'Korean',
        'language_to_learn': 'English'
      },
      'matchReasons': ['reciprocal_pair', 'shared_topic:travel', 42],
      'reciprocal': true,
      'lastActiveBucket': 'today',
      'responseRate': 0.8,
    });
    expect(match.user.name, 'Minji');
    expect(match.matchReasons, ['reciprocal_pair', 'shared_topic:travel']);
    expect(match.reciprocal, true);
    expect(match.lastActiveBucket, 'today');
    expect(match.responseRate, 0.8);

    final degenerate = DailyMatch.fromJson({'user': 'u2'});
    expect(degenerate.user.name, isNotEmpty);
    expect(degenerate.user.id, 'u2');
    expect(degenerate.matchReasons, isEmpty);
    expect(degenerate.reciprocal, false);
    expect(degenerate.responseRate, isNull);
  });

  test('DailyMatchesResult.fromJson skips junk rows and parses refresh', () {
    final r = DailyMatchesResult.fromJson({
      'matches': [
        {'user': 'u1'},
        'garbage',
        null,
      ],
      'nextRefreshAt': '2026-10-02T00:00:00.000Z',
    });
    expect(r.matches.length, 1);
    expect(r.nextRefreshAt, isNotNull);
    expect(r.unavailable, false);
    expect(DailyMatchesResult.unavailableResult.unavailable, true);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/matching_daily_service.dart';

void main() {
  test('404 (kill switch) hides the tab', () {
    final r = MatchingDailyService.parseResponse(404, '{"success":false}');
    expect(r.unavailable, true);
  });

  test('200 parses the batch', () {
    final r = MatchingDailyService.parseResponse(
        200, '{"matches":[{"user":{"_id":"u1","name":"A"}}]}');
    expect(r.unavailable, false);
    expect(r.matches.single.user.id, 'u1');
  });

  test('5xx and other failures throw so the tab shows Retry', () {
    expect(() => MatchingDailyService.parseResponse(500, 'oops'),
        throwsA(isA<MatchingDailyException>()));
    expect(() => MatchingDailyService.parseResponse(401, '{}'),
        throwsA(isA<MatchingDailyException>()));
  });

  test('a non-object or unparsable 200 body throws', () {
    expect(() => MatchingDailyService.parseResponse(200, '[]'),
        throwsA(isA<MatchingDailyException>()));
    expect(() => MatchingDailyService.parseResponse(200, '<html>'),
        throwsA(isA<FormatException>()));
  });
}

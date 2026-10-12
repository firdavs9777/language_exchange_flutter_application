import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/analytics_service.dart';

void main() {
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  test('the four onboarding events use the spec names and params', () async {
    final a = AnalyticsService.instance;
    await a.logActivationMilestone('lesson', 2);
    await a.logGuideRetired('moments', 'milestones');
    await a.logNotificationPrimeShown('first_matches');
    await a.logNotificationPrimeResult('later');

    expect(events.map((e) => e.$1), [
      'activation_milestone',
      'guide_retired',
      'notification_prime_shown',
      'notification_prime_result',
    ]);
    expect(events[0].$2, {'action': 'lesson', 'count': 2});
    expect(events[1].$2, {'surface': 'moments', 'reason': 'milestones'});
    expect(events[2].$2, {'trigger': 'first_matches'});
    expect(events[3].$2, {'result': 'later'});
  });
}

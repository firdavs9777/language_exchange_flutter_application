import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/notification_router.dart';

void main() {
  test('daily_drop resolves to the daily drop route', () {
    expect(NotificationRouter.targetPathForType('daily_drop', const {}), '/learning/daily');
  });

  test('an unknown type does not resolve to the daily route', () {
    expect(NotificationRouter.targetPathForType('mystery', const {}), isNot('/learning/daily'));
  });
}

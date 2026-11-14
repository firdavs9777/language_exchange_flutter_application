import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/notification_router.dart';

void main() {
  test('masked visit push opens the visitors list', () {
    expect(
      NotificationRouter.targetPathForType('profile_visit',
          {'screen': 'visitors', 'masked': 'true', 'bundleSize': 2}),
      '/visitors',
    );
  });

  test('masked flag alone opens the visitors list (push values are strings)',
      () {
    expect(
      NotificationRouter.targetPathForType(
          'profile_visit', {'masked': 'true', 'bundleSize': '3'}),
      '/visitors',
    );
  });

  test('named visit push still opens the visitor', () {
    expect(
      NotificationRouter.targetPathForType(
          'profile_visit', {'userId': 'u1', 'screen': 'profile'}),
      '/profile/u1',
    );
  });

  test('a visit push with neither opens nothing, as before', () {
    expect(NotificationRouter.targetPathForType('profile_visit', {}), isNull);
  });

  test('friend_request is unchanged', () {
    expect(
      NotificationRouter.targetPathForType('friend_request', {'userId': 'u2'}),
      '/profile/u2',
    );
    expect(NotificationRouter.targetPathForType('friend_request', {}), isNull);
  });
}

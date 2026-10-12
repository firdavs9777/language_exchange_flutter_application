import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_history_screen.dart';
import 'package:bananatalk_app/services/notification_router.dart';

NotificationItem _item(String type, Map<String, dynamic> data) => NotificationItem(
    id: 'n1', type: type, title: 't', body: 'b', data: data, read: false,
    createdAt: DateTime(2026, 10, 12));

void main() {
  test('an announcement push opens its screen over home', () {
    final plan = NotificationRouter.planFor('announcement', {'announcementId': 'a1'});
    expect(plan.path, '/announcement/a1');
    expect(plan.usePushAfterHome, isTrue);
  });

  test('without an id it just opens home', () {
    expect(NotificationRouter.planFor('announcement', {}).path, '/home');
  });

  test('list rows carry the type the router needs', () {
    final p = notificationTapPayload(_item('announcement', {'announcementId': 'a1'}));
    expect(p, {'type': 'announcement', 'announcementId': 'a1', 'notificationId': 'n1'});
    expect(notificationTapPayload(_item('moment_like', {'momentId': 'm'})),
        {'momentId': 'm', 'notificationId': 'n1'});
  });

  test('announcement rows have their own icon and colour', () {
    final src = File('lib/pages/notifications/notification_history_screen.dart')
        .readAsStringSync();
    expect("case 'announcement':".allMatches(src).length, 2);
  });

  // Real backend shapes (services/announcementDelivery.js): the FCM data map
  // is all strings and also carries notificationId; the stored Notification
  // has data: { announcementId } as a nested map.
  test('real push payload (string values, with notificationId) routes', () {
    final data = NotificationRouter.normalizeLifecycleData({
      'type': 'announcement',
      'announcementId': '65f0c0ffee0000000000abcd',
      'notificationId': '65f0c0ffee0000000000beef',
    });
    final plan = NotificationRouter.planFor(
        NotificationRouter.resolveType(data), data);
    expect(plan.path, '/announcement/65f0c0ffee0000000000abcd');
    expect(plan.usePushAfterHome, isTrue);
  });

  test('real list document parses and its tap payload routes', () {
    final item = NotificationItem.fromJson({
      '_id': '65f0c0ffee0000000000beef',
      'id': '65f0c0ffee0000000000beef',
      'userId': 'u1',
      'type': 'announcement',
      'title': 'Hello',
      'body': 'World',
      'data': {'announcementId': '65f0c0ffee0000000000abcd'},
      'read': false,
      'createdAt': '2026-10-12T00:00:00.000Z',
    });
    final payload = notificationTapPayload(item);
    final plan = NotificationRouter.planFor(
        NotificationRouter.resolveType(payload), payload);
    expect(plan.path, '/announcement/65f0c0ffee0000000000abcd');
  });

  test('empty or non-string ids never crash and never route', () {
    expect(NotificationRouter.planFor('announcement', {'announcementId': ''}).path, '/home');
    expect(NotificationRouter.planFor('announcement', {'announcementId': null}).path, '/home');
  });
}
